# Publica el APK de Switcher GPS a Supabase Storage + app_releases (app_id=gps).
# Uso:
#   $env:SUPABASE_SERVICE_ROLE_KEY = 'eyJ...'
#   .\tools\publish_apk.ps1
#   .\tools\publish_apk.ps1 -ForceUpdate -Notes "Cambio crítico"

param(
  [string]$ApkPath = "",
  [string]$Notes = "",
  [switch]$ForceUpdate,
  [string]$ProjectUrl = "https://bacticsxilkcyddxbxwz.supabase.co"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$key = $env:SUPABASE_SERVICE_ROLE_KEY
if ([string]::IsNullOrWhiteSpace($key)) {
  Write-Host "Falta SUPABASE_SERVICE_ROLE_KEY en el entorno." -ForegroundColor Red
  Write-Host "Supabase -> Project Settings -> API Keys -> Legacy -> service_role"
  exit 1
}

$pubspec = Get-Content ".\pubspec.yaml" -Raw
if ($pubspec -notmatch 'version:\s*([0-9.]+)\+([0-9]+)') {
  throw "No se pudo leer version de pubspec.yaml"
}
$versionName = $Matches[1]
$buildNumber = [int]$Matches[2]
$versionCode = 9000 + $buildNumber
Write-Host "Pubspec $versionName+$buildNumber -> OTA version_code=$versionCode"

if ([string]::IsNullOrWhiteSpace($ApkPath)) {
  $ApkPath = ".\dist\Switcher-GPS-$versionName.apk"
}
if (-not (Test-Path $ApkPath)) {
  throw "No existe el APK: $ApkPath - ejecuta flutter build apk --release y copialo a dist\"
}

$objectPath = "gps/Switcher-GPS-$versionName-$buildNumber.apk"
$uploadUrl = "$ProjectUrl/storage/v1/object/app-releases/$objectPath"
$apkFull = (Resolve-Path $ApkPath).Path

Write-Host "Subiendo $ApkPath -> app-releases/$objectPath ..."
$uploadOut = (& curl.exe -sS -w "`nHTTP:%{http_code}" -X POST $uploadUrl `
  -H "Authorization: Bearer $key" `
  -H "apikey: $key" `
  -H "x-upsert: true" `
  -H "Content-Type: application/octet-stream" `
  -H "User-Agent: SwitcherPublish/1.0" `
  --data-binary "@$apkFull") -join "`n"
if ($uploadOut -notmatch 'HTTP:200') {
  throw "Storage upload fallo:`n$uploadOut"
}
Write-Host "Storage OK"

$publicUrl = "$ProjectUrl/storage/v1/object/public/app-releases/$objectPath"
$forceJson = if ($ForceUpdate) { 'true' } else { 'true' }
$notesEsc = ($Notes -replace '\\', '\\' -replace '"', '\"')

$deactivateFile = Join-Path $env:TEMP 'switcher_gps_deactivate.json'
$rowFile = Join-Path $env:TEMP 'switcher_gps_release.json'
Set-Content -Path $deactivateFile -Value '{"active":false}' -NoNewline -Encoding Ascii
$rowJson = @"
{"app_id":"gps","platform":"android","version_name":"$versionName","version_code":$versionCode,"apk_path":"$objectPath","apk_url":"$publicUrl","force_update":$forceJson,"notes":"$notesEsc","active":true}
"@
Set-Content -Path $rowFile -Value $rowJson -NoNewline -Encoding Ascii

& curl.exe -sS -o NUL -w "deactivate:%{http_code}`n" -X PATCH `
  "$ProjectUrl/rest/v1/app_releases?app_id=eq.gps&platform=eq.android&active=eq.true&version_code=neq.$versionCode" `
  -H "Authorization: Bearer $key" `
  -H "apikey: $key" `
  -H "Prefer: return=minimal" `
  -H "Content-Type: application/json" `
  -H "User-Agent: SwitcherPublish/1.0" `
  --data-binary "@$deactivateFile" | Out-Host

$upsertOut = (& curl.exe -sS -w "`nHTTP:%{http_code}" -X POST `
  "$ProjectUrl/rest/v1/app_releases?on_conflict=app_id,platform,version_code" `
  -H "Authorization: Bearer $key" `
  -H "apikey: $key" `
  -H "Prefer: return=representation,resolution=merge-duplicates" `
  -H "Content-Type: application/json" `
  -H "User-Agent: SwitcherPublish/1.0" `
  --data-binary "@$rowFile") -join "`n"
if ($upsertOut -notmatch 'HTTP:20[01]') {
  throw "app_releases upsert fallo:`n$upsertOut"
}

Write-Host ""
Write-Host "Publicado Switcher GPS $versionName ($versionCode) force_update=$forceJson" -ForegroundColor Green
Write-Host "URL: $publicUrl"
