param(
    [string]$MySqlExe = 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe',
    [string]$AdminUser = 'root',
    [ValidateRange(1,65535)][int]$Port = 3306,
    [string]$ConfigPath,
    [switch]$IncludeTests
)
$ErrorActionPreference = 'Stop'
if ($AdminUser -notmatch '^[a-zA-Z0-9_]+$') { throw 'Ten tai khoan quan tri khong hop le.' }
$projectRoot = Split-Path $PSScriptRoot -Parent
if (!$ConfigPath) { $ConfigPath = Join-Path $projectRoot '.runtime/db.properties' }
$configPath = [IO.Path]::GetFullPath($ConfigPath)
if (!(Test-Path -LiteralPath $MySqlExe)) { throw 'Khong tim thay mysql.exe. Truyen -MySqlExe voi duong dan dung.' }
if (Test-Path -LiteralPath $configPath) {
    throw 'Da co cau hinh DB. De bao toan du lieu, dung scripts/upgrade-db.ps1 cho DB cu; khong chay khoi tao du lieu mau.'
}
New-Item -ItemType Directory -Force -Path (Split-Path $configPath -Parent) | Out-Null

# Tai khoan ung dung rieng, khong luu mat khau root vao file/lenh/history.
$appUser = 'restman_app_' + [guid]::NewGuid().ToString('N').Substring(0,12)
$appPassword = [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')
$schema = [IO.File]::ReadAllText((Join-Path $projectRoot 'database/design-schema.sql'), [Text.Encoding]::UTF8) + "`n" + [IO.File]::ReadAllText((Join-Path $projectRoot 'database/restman.sql'), [Text.Encoding]::UTF8)
$schema += "`n" + [IO.File]::ReadAllText((Join-Path $projectRoot 'database/dish-sizes.sql'), [Text.Encoding]::UTF8)
$sql = $schema + "`nCREATE USER IF NOT EXISTS '$appUser'@'localhost' IDENTIFIED BY '$appPassword';`nGRANT SELECT, INSERT, UPDATE, DELETE ON restman.* TO '$appUser'@'localhost';`n"
if ($IncludeTests) {
    $sql += $schema.Replace('restman', 'restman_test')
    $sql += "`nGRANT SELECT, INSERT, UPDATE, DELETE ON restman_test.* TO '$appUser'@'localhost';`n"
}
$securePassword = Read-Host "Mat khau MySQL cua $AdminUser (chi nhap tai may nay)" -AsSecureString
$secretPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$process = New-Object Diagnostics.Process
try {
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $MySqlExe
    $start.Arguments = "--host=127.0.0.1 --port=$Port --user=$AdminUser --default-character-set=utf8mb4 --batch --connect-timeout=5"
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.EnvironmentVariables['MYSQL_PWD'] = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($secretPointer)
    $process.StartInfo = $start
    [void]$process.Start()
    $outputTask = $process.StandardOutput.ReadToEndAsync()
    $errorTask = $process.StandardError.ReadToEndAsync()
    # Windows PowerShell 5.1/.NET Framework has no StandardInputEncoding property.
    # Write UTF-8 bytes directly, without a BOM, to preserve Vietnamese SQL text.
    $sqlBytes = [Text.Encoding]::UTF8.GetBytes($sql)
    $process.StandardInput.BaseStream.Write($sqlBytes, 0, $sqlBytes.Length)
    $process.StandardInput.Close()
    $process.WaitForExit()
    $output = $outputTask.GetAwaiter().GetResult()
    $errorText = $errorTask.GetAwaiter().GetResult()
    if ($process.ExitCode -ne 0) { throw $errorText }
    Write-Host $output
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secretPointer)
    if ($null -ne $start) { $start.EnvironmentVariables.Remove('MYSQL_PWD') }
    $process.Dispose()
}

$url = "jdbc:mysql://127.0.0.1:${Port}/restman?characterEncoding=UTF-8&connectionTimeZone=Asia/Bangkok&connectTimeout=5000&socketTimeout=10000"
$config = "db.url=$url`ndb.user=$appUser`ndb.password=$appPassword`n"
[IO.File]::WriteAllText($configPath, $config, (New-Object Text.UTF8Encoding($false)))
if ($IncludeTests) {
    $testConfigPath = Join-Path $projectRoot '.runtime/db-test.properties'
    [IO.File]::WriteAllText($testConfigPath, $config.Replace('/restman?', '/restman_test?'), (New-Object Text.UTF8Encoding($false)))
    Write-Host 'Da tao them restman_test. Dat RESTMAN_TEST_DB_CONFIG toi .runtime/db-test.properties de chay integration test.'
}
Write-Host "Da tao database restman va cau hinh $configPath. Khong chia se file cau hinh mat khau."
Write-Host 'Tiep theo: mvn -o clean verify; dung Tomcat cu, copy WAR va chay lai scripts/run.ps1.'

