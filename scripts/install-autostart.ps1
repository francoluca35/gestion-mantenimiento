# Instala arranque automático del stack demo al iniciar Windows.
# Requiere Docker Desktop con "Start when you log in" habilitado.
# Uso (PowerShell como usuario normal o Admin):
#   powershell -File scripts/install-autostart.ps1
# Quitar:
#   powershell -File scripts/install-autostart.ps1 -Uninstall

param(
	[switch]$Uninstall,
	[string]$TaskName = "SikaDemoDockerUp"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$upScript = Join-Path $root "scripts\start-sika.ps1"
$wrapper = Join-Path $root "scripts\demo-autostart.cmd"

if ($Uninstall) {
	Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
	if (Test-Path $wrapper) { Remove-Item $wrapper -Force }
	Write-Host "Tarea $TaskName eliminada." -ForegroundColor Green
	exit 0
}

if (-not (Test-Path $upScript)) {
	throw "No se encontró $upScript"
}

# CMD wrapper: start-sika espera Docker Desktop, levanta compose y valida salud.
$cmd = @"
@echo off
setlocal
set ROOT=$root
cd /d "%ROOT%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\start-sika.ps1" -Headless >> "%ROOT%\backups\autostart.log" 2>&1
"@

if (-not (Test-Path (Join-Path $root "backups"))) {
	New-Item -ItemType Directory -Path (Join-Path $root "backups") | Out-Null
}
Set-Content -Path $wrapper -Value $cmd -Encoding ASCII

$action = New-ScheduledTaskAction -Execute $wrapper -WorkingDirectory $root
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet `
	-AllowStartIfOnBatteries `
	-DontStopIfGoingOnBatteries `
	-StartWhenAvailable `
	-MultipleInstances IgnoreNew `
	-ExecutionTimeLimit (New-TimeSpan -Hours 1)

Register-ScheduledTask `
	-TaskName $TaskName `
	-Action $action `
	-Trigger $trigger `
	-Settings $settings `
	-Description "Levanta Gestión Docker (API + web + Postgres + backup); Cloudflared corre como servicio Windows" `
	-Force | Out-Null

Write-Host "Tarea '$TaskName' registrada al iniciar sesión." -ForegroundColor Green
Write-Host "Activá también en Docker Desktop: Settings → General → Start Docker Desktop when you log in"
Write-Host "Log: backups\autostart.log"
Write-Host "Probar ahora: powershell -File scripts\start-sika.ps1"
Write-Host "Desinstalar: powershell -File scripts\install-autostart.ps1 -Uninstall"
