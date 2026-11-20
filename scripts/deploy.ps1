param([Parameter(Mandatory=$true)][string]$TomcatHome)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$TomcatHome=(Resolve-Path -LiteralPath $TomcatHome).Path
if (!(Test-Path "$TomcatHome/lib/servlet-api.jar")) {throw 'TomcatHome không hợp lệ.'}
if (!(Test-Path "$projectRoot/target/restman.war")) {throw 'Chạy mvn clean verify trước.'}
$base=Join-Path $projectRoot '.runtime/tomcat'
if (Test-Path "$base/conf/server.xml") {throw 'Runtime đã tồn tại. Dừng server và copy target/restman.war vào .runtime/tomcat/webapps để cập nhật, hoặc dùng hướng dẫn deploy thủ công.'}
New-Item -ItemType Directory -Force -Path $base | Out-Null
Copy-Item -LiteralPath "$TomcatHome/conf" -Destination $base -Recurse
foreach($dir in 'logs','temp','work','webapps'){New-Item -ItemType Directory -Force -Path "$base/$dir" | Out-Null}
[xml]$config=Get-Content -LiteralPath "$base/conf/server.xml"
$config.Server.SetAttribute('port','-1')
foreach($connector in $config.SelectNodes('//Connector')) {if($connector.GetAttribute('protocol') -like '*HTTP*') {$connector.SetAttribute('port','8081');$connector.SetAttribute('address','127.0.0.1')}}
$config.Save("$base/conf/server.xml")
Copy-Item -LiteralPath "$projectRoot/target/restman.war" -Destination "$base/webapps/restman.war"
Write-Host "Đã deploy. Chạy: .\scripts\run.ps1 -TomcatHome '$TomcatHome'"
