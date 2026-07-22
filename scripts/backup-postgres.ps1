# Backup manual Postgres (además del servicio backup del compose).
# Programar opcionalmente con Task Scheduler; el contenedor sika-demo-backup ya corre diario.

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

function Get-EnvValue([string]$path, [string]$key) {
	if (-not (Test-Path $path)) { return $null }
	$line = Get-Content $path | Where-Object { $_ -match "^\s*$key\s*=" } | Select-Object -First 1
	if (-not $line) { return $null }
	return ($line -split "=", 2)[1].Trim().Trim('"').Trim("'")
}

if (Test-Path $EnvFile) {
	$u = Get-EnvValue $EnvFile "POSTGRES_USER"
	$d = Get-EnvValue $EnvFile "POSTGRES_DB"
	$k = Get-EnvValue $EnvFile "BACKUP_KEEP_DAYS"
	if ($u) { $DbUser = $u }
	if ($d) { $DbName = $d }
	if ($k) { $KeepDays = [int]$k }
}

if (-not (Test-Path $BackupDir)) {
	New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$fileName = "gestion_mantenimiento-$stamp.sql.gz"
$outFile = Join-Path $BackupDir $fileName

Write-Host "Backup → $outFile"

$running = docker ps --filter "name=$Container" --format "{{.Names}}"
if (-not $running) {
	throw "Contenedor $Container no está corriendo. Levantá la demo primero (scripts/demo-up.ps1)."
}

docker exec $Container sh -c "pg_dump -U `"$DbUser`" -d `"$DbName`" --no-owner --format=plain | gzip -c > /backups/$fileName"

if (-not (Test-Path $outFile) -or (Get-Item $outFile).Length -lt 100) {
	throw "Backup vacío o fallido"
}

Get-ChildItem $BackupDir -Filter "gestion_mantenimiento-*.sql.gz" |
	Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$KeepDays) } |
	Remove-Item -Force

Write-Host "OK — reteniendo últimos $KeepDays días (compose=$ComposeFile)"
