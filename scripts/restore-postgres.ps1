# Restaura un dump .sql.gz en el Postgres demo.
# Uso: powershell -File scripts/restore-postgres.ps1 -BackupFile backups\gestion_mantenimiento-YYYYMMDD-HHMMSS.sql.gz

param(
	[Parameter(Mandatory = $true)]
	[string]$BackupFile,
	[string]$EnvFile = ".env.demo",
	[string]$ComposeFile = "docker-compose.demo.yml",
	[string]$Container = "sika-demo-postgres",
	[string]$DbUser = "sika",
	[string]$DbName = "gestion_mantenimiento"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path $BackupFile)) {
	throw "No existe $BackupFile"
}

$running = docker ps --filter "name=$Container" --format "{{.Names}}"
if (-not $running) {
	throw "Contenedor $Container no está corriendo. Ejecutá scripts/demo-up.ps1 primero."
}

$full = (Resolve-Path $BackupFile).Path
$name = Split-Path $full -Leaf
$inContainer = "/backups/$name"

# Si el archivo no está en ./backups montado, copiarlo
$backupsDir = Join-Path $root "backups"
if (-not (Test-Path (Join-Path $backupsDir $name))) {
	if (-not (Test-Path $backupsDir)) { New-Item -ItemType Directory -Path $backupsDir | Out-Null }
	Copy-Item $full (Join-Path $backupsDir $name) -Force
	Write-Host "Copiado a backups/$name"
}

Write-Host "ADVERTENCIA: esto reemplaza datos en $DbName" -ForegroundColor Yellow
$confirm = Read-Host "Escribí RESTORE para continuar"
if ($confirm -ne "RESTORE") {
	Write-Host "Cancelado."
	exit 0
}

Write-Host "Restaurando $name ..."
docker exec -i $Container sh -c "gunzip -c `"$inContainer`" | psql -U `"$DbUser`" -d `"$DbName`" -v ON_ERROR_STOP=1"
if ($LASTEXITCODE -ne 0) { throw "Restore falló" }

Write-Host "Restore OK. Reiniciá la API si hace falta:" -ForegroundColor Green
Write-Host "  docker restart sika-demo-api"
