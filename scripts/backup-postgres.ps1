# Backup diario Postgres (demo 2 meses).
# Programar con Task Scheduler (Windows) o cron (Linux).
# Ejemplo Task Scheduler: diario 02:00 → powershell -File scripts/backup-postgres.ps1

param(
	[string]$ComposeFile = "docker-compose.demo.yml",
	[string]$EnvFile = ".env.demo",
	[string]$Container = "sika-demo-postgres",
	[string]$DbUser = "sika",
	[string]$DbName = "gestion_mantenimiento",
	[string]$BackupDir = "backups",
	[int]$KeepDays = 14
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path $BackupDir)) {
	New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$fileName = "gestion_mantenimiento-$stamp.sql.gz"
$outFile = Join-Path $BackupDir $fileName

Write-Host "Backup → $outFile"

$running = docker ps --filter "name=$Container" --format "{{.Names}}"
if (-not $running) {
	throw "Contenedor $Container no está corriendo. Levantá la demo primero."
}

# Escribe en el volumen montado ./backups → /backups (evita corrupción binaria en PowerShell).
docker exec $Container sh -c "pg_dump -U `"$DbUser`" -d `"$DbName`" --no-owner --format=plain | gzip -c > /backups/$fileName"

if (-not (Test-Path $outFile) -or (Get-Item $outFile).Length -lt 100) {
	throw "Backup vacío o fallido"
}

Get-ChildItem $BackupDir -Filter "gestion_mantenimiento-*.sql.gz" |
	Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$KeepDays) } |
	Remove-Item -Force

Write-Host "OK — reteniendo últimos $KeepDays días"
