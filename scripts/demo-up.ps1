# Levanta el stack demo (build + health).
# Uso: powershell -File scripts/demo-up.ps1 [-WithTunnel] [-Seed]

param(
	[switch]$WithTunnel,
	[switch]$Seed,
	[string]$EnvFile = ".env.demo",
	[string]$ComposeFile = "docker-compose.demo.yml",
	[int]$HealthTimeoutSec = 180
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path $EnvFile)) {
	if (Test-Path ".env.demo.example") {
		Copy-Item ".env.demo.example" $EnvFile
		Write-Host "Creado $EnvFile desde .env.demo.example — EDITÁ secretos antes de producción." -ForegroundColor Yellow
	} else {
		throw "Falta $EnvFile. Copiá .env.demo.example → .env.demo"
	}
}

# Leer token del env file (simple parse KEY=VALUE)
function Get-EnvValue([string]$path, [string]$key) {
	$line = Get-Content $path | Where-Object { $_ -match "^\s*$key\s*=" } | Select-Object -First 1
	if (-not $line) { return "" }
	return ($line -split "=", 2)[1].Trim().Trim('"').Trim("'")
}

$token = Get-EnvValue $EnvFile "CLOUDFLARE_TUNNEL_TOKEN"
$profiles = @()
if ($WithTunnel -or ($token -and $token.Length -gt 10)) {
	$profiles += "tunnel"
	Write-Host "Perfil tunnel activo (Cloudflare)." -ForegroundColor Cyan
}

$profileArgs = @()
if ($profiles.Count -gt 0) {
	$profileArgs = @("--profile", ($profiles -join ","))
}

Write-Host "docker compose up -d --build ..." -ForegroundColor Cyan
& docker compose -f $ComposeFile --env-file $EnvFile @profileArgs up -d --build
if ($LASTEXITCODE -ne 0) { throw "compose up falló" }

$deadline = (Get-Date).AddSeconds($HealthTimeoutSec)
Write-Host "Esperando /v1/ready ..."
do {
	try {
		$r = Invoke-WebRequest -Uri "http://127.0.0.1:3000/v1/ready" -UseBasicParsing -TimeoutSec 5
		if ($r.StatusCode -eq 200) {
			Write-Host "API ready OK" -ForegroundColor Green
			break
		}
	} catch {
		Start-Sleep -Seconds 3
	}
	if ((Get-Date) -gt $deadline) {
		& docker compose -f $ComposeFile --env-file $EnvFile logs api --tail 80
		throw "Timeout esperando /v1/ready"
	}
} while ($true)

if ($Seed) {
	Write-Host "Ejecutando seed..." -ForegroundColor Cyan
	& powershell -File (Join-Path $PSScriptRoot "seed-demo.ps1") -EnvFile $EnvFile -ComposeFile $ComposeFile
}

$port = Get-EnvValue $EnvFile "API_PORT"
if (-not $port) { $port = "3000" }
$public = Get-EnvValue $EnvFile "PUBLIC_BASE_URL"
Write-Host ""
Write-Host "Listo." -ForegroundColor Green
Write-Host "  Local:  http://127.0.0.1:$port/v1/health"
Write-Host "  Público: $public/v1  (si tunnel configurado)"
Write-Host "  Android: Perfil → Servidor API = $public/v1"
Write-Host "  Seed:    powershell -File scripts/seed-demo.ps1"
Write-Host "  Backup:  carpeta ./backups (automático diario)"
