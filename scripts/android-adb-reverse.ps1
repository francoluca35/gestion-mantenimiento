# Configura adb reverse para que el celular use localhost:3000 → PC:3000
# Uso: desde la raíz del repo, con el teléfono USB + depuración USB:
#   powershell -ExecutionPolicy Bypass -File scripts/android-adb-reverse.ps1

$ErrorActionPreference = 'Stop'

$adbCandidates = @(
	"$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
	"$env:ANDROID_HOME\platform-tools\adb.exe",
	"$env:ANDROID_SDK_ROOT\platform-tools\adb.exe"
)

$adb = $adbCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $adb) {
	$fromPath = Get-Command adb -ErrorAction SilentlyContinue
	if ($fromPath) { $adb = $fromPath.Source }
}

if (-not $adb) {
	Write-Error "No se encontró adb. Instalá Android SDK platform-tools o agregalo al PATH."
}

Write-Host "adb: $adb"
& $adb start-server | Out-Null
$devices = & $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\tdevice$' }
if (-not $devices) {
	Write-Error "No hay dispositivos en modo 'device'. Conectá el celular por USB y aceptá depuración."
}

Write-Host "Dispositivos:"
$devices | ForEach-Object { Write-Host "  $_" }

& $adb reverse tcp:3000 tcp:3000
if ($LASTEXITCODE -ne 0) {
	Write-Error "adb reverse falló (exit $LASTEXITCODE)"
}

Write-Host ""
Write-Host "Listo. En la app (Perfil → Servidor API) usá:"
Write-Host "  http://127.0.0.1:3000/v1"
Write-Host ""
Write-Host "Dejá la API corriendo: cd apps/api && npm run start:dev"
Write-Host "Para quitar el reverse: adb reverse --remove tcp:3000"
