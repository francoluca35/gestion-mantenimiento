# Seed demo (usuarios admin/tecnico/panolero/...).
param(
	[string]$EnvFile = ".env.demo",
	[string]$ComposeFile = "docker-compose.demo.yml"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path $EnvFile)) {
	throw "Falta $EnvFile"
}

Write-Host "Build + run seed one-shot..." -ForegroundColor Cyan
& docker compose -f $ComposeFile --env-file $EnvFile --profile seed run --rm --build seed
if ($LASTEXITCODE -ne 0) { throw "Seed falló" }
Write-Host "Seed OK — usuarios demo con clave Sika123!" -ForegroundColor Green
