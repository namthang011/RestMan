param([Parameter(Mandatory=$true)][string]$TomcatHome)
$ErrorActionPreference='Stop'
if (!$env:JAVA_HOME -or !(Test-Path "$env:JAVA_HOME/bin/java.exe")){throw 'Đặt JAVA_HOME trỏ tới JDK 17.'}
$env:CATALINA_HOME=(Resolve-Path -LiteralPath $TomcatHome).Path
$env:CATALINA_BASE=Join-Path (Split-Path $PSScriptRoot -Parent) '.runtime/tomcat'
$env:RESTMAN_DB_CONFIG=Join-Path (Split-Path $PSScriptRoot -Parent) '.runtime/db.properties'
if (!(Test-Path -LiteralPath $env:RESTMAN_DB_CONFIG) -and !$env:RESTMAN_DB_USER) {
    throw 'Chua cau hinh MySQL. Chay .\scripts\init-db.ps1 va nhap mat khau quan tri truoc.'
}
if (!(Test-Path "$env:CATALINA_BASE/conf/server.xml")){throw 'Chạy deploy.ps1 trước.'}
& "$env:CATALINA_HOME/bin/catalina.bat" run
