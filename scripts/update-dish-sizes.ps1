param([string]$ConfigPath, [string]$MySqlBin = 'C:\Program Files\MySQL\MySQL Server 8.0\bin')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (!$ConfigPath) { $ConfigPath = Join-Path $projectRoot '.runtime/db.properties' }
$config = ConvertFrom-StringData ([IO.File]::ReadAllText([IO.Path]::GetFullPath($ConfigPath)))
$dbUri = [uri]($config['db.url'] -replace '^jdbc:', '')
$catalog = $dbUri.AbsolutePath.Trim('/')
$appUser = $config['db.user']
if ($catalog -notmatch '^restman(_test)?$' -or $appUser -notmatch '^[a-zA-Z0-9_]+$' -or $dbUri.Host -notin @('127.0.0.1','localhost')) {
    throw 'Chi cap nhat DB RestMan cuc bo voi cau hinh hop le.'
}
$port = if ($dbUri.Port -gt 0) { $dbUri.Port } else { 3306 }
function Invoke-SizeTool([string]$Exe, [string]$Arguments, [string]$Sql = '') {
    $process = New-Object Diagnostics.Process
    $start = New-Object Diagnostics.ProcessStartInfo
    try {
        $start.FileName = Join-Path $MySqlBin $Exe
        $start.Arguments = "--host=127.0.0.1 --port=$port --user=$appUser --default-character-set=utf8mb4 $Arguments"
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $start.RedirectStandardInput = $true
        $start.RedirectStandardOutput = $true
        $start.RedirectStandardError = $true
        $start.StandardOutputEncoding = [Text.Encoding]::UTF8
        $start.EnvironmentVariables['MYSQL_PWD'] = $config['db.password']
        $process.StartInfo = $start
        [void]$process.Start()
        $outTask = $process.StandardOutput.ReadToEndAsync()
        $errTask = $process.StandardError.ReadToEndAsync()
        $bytes = [Text.Encoding]::UTF8.GetBytes($Sql)
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
$backupDir = Join-Path $projectRoot '.runtime/backups'
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$backup = Join-Path $backupDir ("$catalog-port$port-before-sizes-" + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.sql')
[void](Invoke-SizeTool 'mysqldump.exe' "--single-transaction --no-tablespaces --skip-triggers --set-gtid-purged=OFF --result-file=`"$backup`" $catalog tblSize tblDishSize")
if (!(Test-Path -LiteralPath $backup) -or (Get-Item -LiteralPath $backup).Length -eq 0) { throw 'Sao luu size chua thanh cong; khong cap nhat.' }
$detailsSql = "USE $catalog; SELECT id,tblDishid,tblDishSizeid,tblComboid,quantity FROM tblComboDetail ORDER BY id;"
$before = Invoke-SizeTool 'mysql.exe' '--batch --skip-column-names --connect-timeout=5' $detailsSql
$sql = [IO.File]::ReadAllText((Join-Path $projectRoot 'database/dish-sizes.sql'),[Text.Encoding]::UTF8).Replace('USE restman;',"USE $catalog;")
[void](Invoke-SizeTool 'mysql.exe' '--batch --connect-timeout=5' $sql)
$after = Invoke-SizeTool 'mysql.exe' '--batch --skip-column-names --connect-timeout=5' $detailsSql
if ($before -cne $after) { throw 'Chi tiet combo da thay doi; kiem tra lai truoc khi tiep tuc.' }
$missing = Invoke-SizeTool 'mysql.exe' '--batch --skip-column-names --connect-timeout=5' "USE $catalog; SELECT COUNT(*) FROM tblDish d CROSS JOIN tblSize s LEFT JOIN tblDishSize ds ON ds.tblDishid=d.id AND ds.tblSizeid=s.id WHERE d.tblRestaurantid=1 AND s.name IN ('S','M','L') AND ds.id IS NULL;"
if ([int]$missing.Trim() -ne 0) { throw 'Con mon chua du size S/M/L.' }
Write-Host "Da cap nhat size S/M/L. Chi tiet combo cu giu nguyen. Ban sao luu: $backup"
