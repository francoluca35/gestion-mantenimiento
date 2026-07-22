# Configuración inicial: genera secretos, crea .env.demo, construye imágenes,
# carga el seed, instala autostart y crea accesos directos en el Escritorio.

param(
	[switch]$SkipBuild,
	[switch]$SkipSeed
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function New-Secret([int]$bytes = 36) {
	$data = New-Object byte[] $bytes
	[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($data)
	return [Convert]::ToBase64String($data).Replace("+", "A").Replace("/", "B").TrimEnd("=")
}

function Get-EnvLine([string]$path, [string]$key) {
	if (-not (Test-Path $path)) { return $null }
	return Get-Content $path | Where-Object { $_ -match "^\s*$key\s*=" } | Select-Object -First 1
}

$envDemo = Join-Path $root ".env.demo"
if (-not (Test-Path $envDemo)) {
	$template = Get-Content (Join-Path $root ".env.demo.example") -Raw
	$template = $template.Replace("CAMBIAR_password_fuerte_demo", (New-Secret 30))
	$template = $template.Replace("CAMBIAR_jwt_secret_largo_minimo_32_chars!!", (New-Secret 48))
	$template = $template.Replace("CAMBIAR_refresh_secret_largo_minimo_32!!", (New-Secret 48))

	# Reutilizar Firebase del entorno de desarrollo sin mostrar secretos.
	$sourceEnv = Join-Path $root ".env"
	$firebaseLines = @(
		Get-EnvLine $sourceEnv "FIREBASE_PROJECT_ID"
		Get-EnvLine $sourceEnv "FIREBASE_CLIENT_EMAIL"
		Get-EnvLine $sourceEnv "FIREBASE_PRIVATE_KEY"
	) | Where-Object { $_ }
	if ($firebaseLines.Count -gt 0) {
		$template += "`n`n# Firebase copiado del entorno local`n" + ($firebaseLines -join "`n") + "`n"
	}

	$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
	[System.IO.File]::WriteAllText($envDemo, $template, $utf8NoBom)
	Write-Host ".env.demo creado con secretos aleatorios." -ForegroundColor Green
} else {
	Write-Host ".env.demo ya existe; no se modificaron sus secretos." -ForegroundColor Yellow
}

if (-not $SkipBuild) {
	if ($SkipSeed) {
		& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\start-sika.ps1" -Rebuild
	} else {
		& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\start-sika.ps1" -Rebuild -Seed
	}
	if ($LASTEXITCODE -ne 0) { throw "Falló el primer inicio." }
}

& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\install-autostart.ps1"
if ($LASTEXITCODE -ne 0) { throw "No se pudo instalar el inicio automático." }

& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\create-desktop-shortcuts.ps1"
if ($LASTEXITCODE -ne 0) { throw "No se pudieron crear accesos directos." }

Write-Host ""
Write-Host "CONFIGURACIÓN COMPLETA" -ForegroundColor Green
Write-Host "Usá 'Iniciar Gestión Mantenimiento' en el Escritorio."
