# Inicio unificado de Gestión de Mantenimiento.
# Levanta Docker, PostgreSQL, API, web, backups y verifica Cloudflare.

param(
	[switch]$Headless,
	[switch]$Rebuild,
	[switch]$Seed,
	[string]$EnvFile = ".env.demo",
	[string]$ComposeFile = "docker-compose.demo.yml"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Write-Step([string]$text) {
	Write-Host ""
	Write-Host "==> $text" -ForegroundColor Cyan
}

function Wait-Docker([int]$timeoutSeconds = 300) {
	$deadline = (Get-Date).AddSeconds($timeoutSeconds)
	while ((Get-Date) -lt $deadline) {
		& cmd.exe /c "docker info >nul 2>&1"
		if ($LASTEXITCODE -eq 0) { return }
		Start-Sleep -Seconds 5
	}
	throw "Docker Desktop no respondió después de $timeoutSeconds segundos."
}

function Ensure-Docker {
	& cmd.exe /c "docker info >nul 2>&1"
	if ($LASTEXITCODE -eq 0) { return }

	Write-Step "Iniciando Docker Desktop"
	$dockerDesktop = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
	if (-not (Test-Path $dockerDesktop)) {
		throw "Docker Desktop no está instalado en la ruta esperada."
	}
	Start-Process $dockerDesktop
	Wait-Docker
}

function Stop-ProjectDevServer([int]$port) {
	$connections = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
	foreach ($connection in $connections) {
		$pidValue = $connection.OwningProcess
		if (-not $pidValue) { continue }

		$processInfo = Get-CimInstance Win32_Process -Filter "ProcessId=$pidValue" -ErrorAction SilentlyContinue
		$commandLine = $processInfo.CommandLine
		$isProjectDev = $commandLine -and (
			$commandLine -match "gestion-mantenimiento" -or
			$commandLine -match "nest start" -or
			$commandLine -match "flutter_tools"
		)

		if ($isProjectDev) {
			Write-Host "Cerrando servidor de desarrollo en puerto $port (PID $pidValue)..."
			Stop-Process -Id $pidValue -Force -ErrorAction SilentlyContinue
			Start-Sleep -Seconds 1
		} elseif ($processInfo.Name -match "com\.docker|docker-proxy|wslrelay|wslhost|wsl|vpnkit") {
			# Puerto publicado por Docker Desktop (WSL2). Compose se encarga de recrearlo.
			Write-Host "Puerto $port en uso por Docker ($($processInfo.Name)); Compose lo reutilizará." -ForegroundColor DarkGray
		} else {
			throw "El puerto $port está ocupado por '$($processInfo.Name)' (PID $pidValue). Cerralo antes de iniciar SIKA."
		}
	}
}

function Ensure-Cloudflared {
	$service = Get-Service -Name "Cloudflared" -ErrorAction SilentlyContinue
	if (-not $service) {
		Write-Warning "No se encontró el servicio Cloudflared. La app funcionará por LAN, pero no por el dominio público."
		return
	}

	if ($service.StartType -ne "Automatic") {
		Set-Service -Name "Cloudflared" -StartupType Automatic
	}
	if ($service.Status -ne "Running") {
		Start-Service -Name "Cloudflared"
		$service.WaitForStatus("Running", (New-TimeSpan -Seconds 30))
	}
	Write-Host "Cloudflared: RUNNING / AUTO" -ForegroundColor Green
}

function Wait-Url([string]$url, [int]$timeoutSeconds = 180) {
	$deadline = (Get-Date).AddSeconds($timeoutSeconds)
	do {
		try {
			$response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
			if ($response.StatusCode -eq 200) { return $true }
		} catch {
			Start-Sleep -Seconds 3
		}
	} while ((Get-Date) -lt $deadline)
	return $false
}

function Get-EnvValue([string]$path, [string]$key, [string]$defaultValue = "") {
	$line = Get-Content $path -ErrorAction SilentlyContinue |
		Where-Object { $_ -match "^\s*$key\s*=" } |
		Select-Object -First 1
	if (-not $line) { return $defaultValue }
	return ($line -split "=", 2)[1].Trim().Trim('"').Trim("'")
}

function Ensure-FlutterWeb {
	$webIndex = Join-Path $root "apps\client\build\web\index.html"
	$needsBuild = $Rebuild -or -not (Test-Path $webIndex)
	if (-not $needsBuild) {
		Write-Host "Web Flutter ya compilada (apps/client/build/web)." -ForegroundColor Green
		return
	}

	$flutter = Get-Command flutter -ErrorAction SilentlyContinue
	if (-not $flutter) {
		throw "Flutter no está en el PATH. Instalá Flutter o agregalo al PATH para construir la web."
	}

	$publicBase = (Get-EnvValue (Join-Path $root $EnvFile) "PUBLIC_BASE_URL" "https://api.sorjuanaliberte.store").TrimEnd("/")
	$apiBaseUrl = if ($publicBase -match "/v1$") { $publicBase } else { "$publicBase/v1" }

	Write-Step "Compilando Flutter web (API = $apiBaseUrl)"
	Push-Location (Join-Path $root "apps\client")
	try {
		& flutter pub get
		if ($LASTEXITCODE -ne 0) { throw "flutter pub get falló." }
		& flutter build web --release --dart-define=API_BASE_URL=$apiBaseUrl
		if ($LASTEXITCODE -ne 0) { throw "flutter build web falló." }
	} finally {
		Pop-Location
	}

	if (-not (Test-Path $webIndex)) {
		throw "No se generó apps/client/build/web/index.html"
	}
}

if (-not (Test-Path $EnvFile)) {
	throw "Falta $EnvFile. Ejecutá scripts\setup-sika.ps1 una vez."
}

Ensure-Docker
Ensure-Cloudflared

# Evitar choques con npm run start:dev / flutter run.
Stop-ProjectDevServer -port 3000
Stop-ProjectDevServer -port 8080

Ensure-FlutterWeb

Write-Step "Levantando base de datos, API, web y backups"
$composeArgs = @("-f", $ComposeFile, "--env-file", $EnvFile, "up", "-d")
if ($Rebuild) { $composeArgs += "--build" }
& docker compose @composeArgs
if ($LASTEXITCODE -ne 0) { throw "No se pudo levantar Docker Compose." }

if (-not (Wait-Url "http://127.0.0.1:3000/v1/ready")) {
	& docker compose -f $ComposeFile --env-file $EnvFile logs api --tail 100
	throw "La API no quedó lista."
}
if (-not (Wait-Url "http://127.0.0.1:8080/health" 60)) {
	& docker compose -f $ComposeFile --env-file $EnvFile logs web --tail 60
	throw "La web no quedó lista."
}

if ($Seed) {
	Write-Step "Cargando datos demo"
	& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\seed-demo.ps1" `
		-EnvFile $EnvFile -ComposeFile $ComposeFile
	if ($LASTEXITCODE -ne 0) { throw "Falló el seed." }
}

$publicOk = Wait-Url "https://api.sorjuanaliberte.store/v1/health" 30

Write-Host ""
Write-Host "GESTIÓN DE MANTENIMIENTO ESTÁ LISTA" -ForegroundColor Green
Write-Host "Web PC:      http://localhost:8080"
Write-Host "API local:   http://localhost:3000/v1"
Write-Host "API móvil:   https://api.sorjuanaliberte.store/v1"
Write-Host "Cloudflare:  $(if ($publicOk) { 'OK' } else { 'verificar tunnel' })"
Write-Host "Backups:     $root\backups"

if (-not $Headless) {
	Start-Process "http://localhost:8080"
}
