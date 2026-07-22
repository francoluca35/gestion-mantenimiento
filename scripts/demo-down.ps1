# Baja el stack demo.
param(
	[string]$EnvFile = ".env.demo",
	[string]$ComposeFile = "docker-compose.demo.yml",
	[switch]$Volumes
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$composeArgs = @("-f", $ComposeFile)
if (Test-Path $EnvFile) {
	$composeArgs += @("--env-file", $EnvFile)
}
# Incluir todos los perfiles para apagar todo
$composeArgs += @("--profile", "tunnel", "--profile", "seed", "--profile", "with-minio", "--profile", "with-redis")
$composeArgs += @("down")
if ($Volumes) { $composeArgs += "--volumes" }

& docker compose @composeArgs
Write-Host "Stack detenido." -ForegroundColor Green
