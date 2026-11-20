param(
    [string]$MySqlBin = 'C:\Program Files\MySQL\MySQL Server 8.0\bin',
    [string]$AdminUser = 'root',
    [ValidateRange(1,65535)][int]$Port = 3306,
    [switch]$SkipDeploy
)
$ErrorActionPreference = 'Stop'
if ($AdminUser -notmatch '^[a-zA-Z0-9_]+$') { throw 'Ten tai khoan quan tri khong hop le.' }
$projectRoot = Split-Path $PSScriptRoot -Parent
$warPath = Join-Path $projectRoot 'target/restman.war'
if (!(Test-Path -LiteralPath $warPath)) { throw 'Chay mvn -o clean verify de tao WAR moi truoc khi nang cap DB.' }
$backupDir = Join-Path $projectRoot '.runtime/backups'
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$backup = Join-Path $backupDir ("restman-port$Port-before-design-" + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.sql')
$securePassword = Read-Host "Mat khau MySQL cua $AdminUser (chi nhap tai may nay)" -AsSecureString
$secretPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
function Invoke-DatabaseTool([string]$Exe, [string]$Arguments, [string]$InputSql = '') {
    $process = New-Object Diagnostics.Process
    $start = New-Object Diagnostics.ProcessStartInfo
    try {
        $start.FileName = Join-Path $MySqlBin $Exe
        $timeoutOption = if ($Exe -eq 'mysql.exe') { '--connect-timeout=5' } else { '' }
        $start.Arguments = "--host=127.0.0.1 --port=$Port --user=$AdminUser --default-character-set=utf8mb4 $timeoutOption $Arguments"
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $start.RedirectStandardInput = $true
        $start.RedirectStandardOutput = $true
        $start.RedirectStandardError = $true
        $start.StandardOutputEncoding = [Text.Encoding]::UTF8
        $start.EnvironmentVariables['MYSQL_PWD'] = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($secretPointer)
        $process.StartInfo = $start
        [void]$process.Start()
        $outTask = $process.StandardOutput.ReadToEndAsync()
        $errTask = $process.StandardError.ReadToEndAsync()
        $bytes = [Text.Encoding]::UTF8.GetBytes($InputSql)
        $process.StandardInput.BaseStream.Write($bytes,0,$bytes.Length)
        $process.StandardInput.Close()
        $process.WaitForExit()
        $output = $outTask.GetAwaiter().GetResult()
        $errors = $errTask.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw $errors }
        return $output
    } finally {
        $start.EnvironmentVariables.Remove('MYSQL_PWD')
        $process.Dispose()
    }
}
try {
    # Only upgrade while the old application is stopped: otherwise new writes may miss the snapshot.
    Write-Host 'Dam bao RestMan/Tomcat da dung truoc khi tiep tuc.'
    $active = Invoke-DatabaseTool 'mysql.exe' '--batch --skip-column-names' "SELECT COUNT(*) FROM information_schema.PROCESSLIST WHERE DB='restman' AND ID<>CONNECTION_ID();"
    if ([int]$active.Trim() -gt 0) { throw 'Con ket noi toi restman. Dung ung dung roi chay lai.' }
    [void](Invoke-DatabaseTool 'mysqldump.exe' "--single-transaction --no-tablespaces --set-gtid-purged=OFF --result-file=`"$backup`" restman")
    if (!(Test-Path -LiteralPath $backup) -or (Get-Item -LiteralPath $backup).Length -eq 0) { throw 'Sao luu chua thanh cong; khong sua DB.' }
    Write-Host "Da sao luu: $backup"
    $legacy = Invoke-DatabaseTool 'mysql.exe' '--batch --skip-column-names' "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='restman' AND TABLE_NAME IN ('dish','combo','combo_item');"
    if ([int]$legacy.Trim() -notin @(0,3)) { throw 'Chi co mot phan bang cu. Dung nang cap de kiem tra du lieu.' }
    $schema = [IO.File]::ReadAllText((Join-Path $projectRoot 'database/design-schema.sql'),[Text.Encoding]::UTF8)
    [void](Invoke-DatabaseTool 'mysql.exe' '--batch' $schema)
    if ([int]$legacy.Trim() -eq 3) {
    $migration = [IO.File]::ReadAllText((Join-Path $projectRoot 'database/migrate-to-design.sql'),[Text.Encoding]::UTF8)
    [void](Invoke-DatabaseTool 'mysql.exe' '--batch' ("USE restman;`n" + $migration))
    $verify = @'
USE restman;
SELECT COUNT(*) FROM dish d LEFT JOIN tblDish n ON n.id=d.id
 WHERE n.id IS NULL OR NOT (n.name <=> d.name) OR NOT (n.type <=> d.dish_type)
 OR NOT (n.basePrice <=> d.price) OR NOT (n.description <=> d.description) OR NOT (n.img <=> d.image);
SELECT COUNT(*) FROM combo c LEFT JOIN tblCombo n ON n.id=c.id
 WHERE n.id IS NULL OR NOT (n.name <=> c.name) OR NOT (n.price <=> c.price) OR NOT (n.description <=> c.description);
SELECT COUNT(*) FROM combo_item ci LEFT JOIN tblComboDetail cd ON cd.tblComboid=ci.combo_id AND cd.tblDishid=ci.dish_id
 LEFT JOIN tblDishSize ds ON ds.id=cd.tblDishSizeid LEFT JOIN tblSize s ON s.id=ds.tblSizeid
 WHERE cd.id IS NULL OR cd.quantity<>ci.quantity OR ds.tblDishid<>ci.dish_id OR ds.pricePercentage<>100;
'@
    $counts = Invoke-DatabaseTool 'mysql.exe' '--batch --skip-column-names' $verify
    if (($counts -split '\s+' | Where-Object { $_ -and $_ -ne '0' }).Count -gt 0) { throw 'Kiem tra du lieu chuyen doi khong khop. Giu nguyen ban sao luu va cac bang cu de kiem tra.' }
    }
    $sizeSql = [IO.File]::ReadAllText((Join-Path $projectRoot 'database/dish-sizes.sql'),[Text.Encoding]::UTF8)
    [void](Invoke-DatabaseTool 'mysql.exe' '--batch' $sizeSql)
    $cleanup = [IO.File]::ReadAllText((Join-Path $projectRoot 'database/keep-two-modules.sql'),[Text.Encoding]::UTF8)
    [void](Invoke-DatabaseTool 'mysql.exe' '--batch' $cleanup)
    $remaining = Invoke-DatabaseTool 'mysql.exe' '--batch --skip-column-names' "SELECT LOWER(TABLE_NAME) FROM information_schema.TABLES WHERE TABLE_SCHEMA='restman' ORDER BY TABLE_NAME;"
    $actual = @($remaining -split '\s+' | Where-Object { $_ } | Sort-Object)
    $expected = @('tblrestaurant','tblsize','tbldish','tbldishsize','tblcombo','tblcombodetail') | Sort-Object
    if (@(Compare-Object $expected $actual).Count -ne 0) { throw 'Danh sach bang sau nang cap khong dung 6 bang. Xem lai DB va ban sao luu.' }
    # Deploy only after successful database verification; no runtime config/password changes.
    $webapps = Join-Path $projectRoot '.runtime/tomcat/webapps'
    if (!$SkipDeploy -and (Test-Path -LiteralPath $webapps)) { Copy-Item -LiteralPath $warPath -Destination (Join-Path $webapps 'restman.war') -Force }
    [IO.File]::WriteAllText((Join-Path $projectRoot ".runtime/design-db-port$Port-upgraded.txt"), (Get-Date -Format o))
    Write-Host 'Thanh cong: DB chi con 6 bang cho hai module. Da chuyen du lieu, sao luu va copy WAR moi.'
    Write-Host 'Khoi dong lai Tomcat bang scripts/run.ps1 de dung ban moi.'
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secretPointer)
}
