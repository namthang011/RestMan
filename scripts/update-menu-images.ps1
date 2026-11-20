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
function Invoke-ImageTool([string]$Exe, [string]$Arguments, [string]$Sql = '') {
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
$backup = Join-Path $backupDir ("$catalog-port$port-before-images-" + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.sql')
$assetDir=Join-Path $projectRoot 'src/main/webapp/assets/images/generated'
foreach($name in @((1..12 | ForEach-Object {"dish-$_.png"}) + (1..3 | ForEach-Object {"combo-$_.png"}))) {
    if (!(Test-Path -LiteralPath (Join-Path $assetDir $name))) { throw "Missing generated image: $name" }
}
[void](Invoke-ImageTool 'mysqldump.exe' "--single-transaction --no-tablespaces --skip-triggers --set-gtid-purged=OFF --result-file=`"$backup`" $catalog tblDish tblCombo")
if (!(Test-Path -LiteralPath $backup) -or (Get-Item -LiteralPath $backup).Length -eq 0) { throw 'Image backup failed; no database update.' }
$sql=[IO.File]::ReadAllText((Join-Path $projectRoot 'database/generated-images.sql'),[Text.Encoding]::UTF8).Replace('USE restman;',"USE $catalog;")
[void](Invoke-ImageTool 'mysql.exe' '--batch --connect-timeout=5' $sql)
Write-Host "Updated generated image paths. Backup: $backup"
Write-Host (Invoke-ImageTool 'mysql.exe' '--batch --connect-timeout=5' "USE $catalog; SELECT COUNT(*) AS generated_dishes FROM tblDish WHERE img LIKE 'assets/images/generated/dish-%.png'; SELECT COUNT(*) AS generated_combos FROM tblCombo WHERE img LIKE 'assets/images/generated/combo-%.png';")