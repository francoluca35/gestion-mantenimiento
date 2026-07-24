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

function New-Secret([int]$bytes = 36) {
	$data = New-Object byte[] $bytes
	[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($data)
	return [Convert]::ToBase64String($data).Replace("+", "A").Replace("/", "B").TrimEnd("=")
}

function Ensure-EnvFile {
	if (Test-Path $EnvFile) { return }

	$example = Join-Path $root ".env.demo.example"
	if (-not (Test-Path $example)) {
		throw "Falta $EnvFile y no existe .env.demo.example."
	}

	Write-Step "Creando $EnvFile desde .env.demo.example"
	$template = Get-Content $example -Raw
	$template = $template.Replace("CAMBIAR_password_fuerte_demo", (New-Secret 30))
	$template = $template.Replace("CAMBIAR_jwt_secret_largo_minimo_32_chars!!", (New-Secret 48))
	$template = $template.Replace("CAMBIAR_refresh_secret_largo_minimo_32!!", (New-Secret 48))

	$sourceEnv = Join-Path $root ".env"
	if (Test-Path $sourceEnv) {
		$firebaseKeys = @("FIREBASE_PROJECT_ID", "FIREBASE_CLIENT_EMAIL", "FIREBASE_PRIVATE_KEY")
		$firebaseLines = @()
		foreach ($key in $firebaseKeys) {
			$line = Get-Content $sourceEnv |
				Where-Object { $_ -match "^\s*$key\s*=" } |
				Select-Object -First 1
			if ($line) { $firebaseLines += $line }
		}
		if ($firebaseLines.Count -gt 0) {
			$template += "`n`n# Firebase copiado del entorno local`n" + ($firebaseLines -join "`n") + "`n"
		}
	}

	$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
	[System.IO.File]::WriteAllText((Join-Path $root $EnvFile), $template, $utf8NoBom)
	Write-Host "$EnvFile creado con secretos aleatorios." -ForegroundColor Green
}

function Invoke-Compose {
	param([Parameter(Mandatory = $true)][string[]]$ComposeArgs)
	$prev = $ErrorActionPreference
	$ErrorActionPreference = "Continue"
	try {
		& docker compose @ComposeArgs 2>&1 | ForEach-Object {
			if ($_ -is [System.Management.Automation.ErrorRecord]) {
				Write-Host $_.Exception.Message
			} else {
				Write-Host $_
			}
		}
		if ($LASTEXITCODE -ne 0) {
			throw "docker compose falló (código $LASTEXITCODE)."
		}
	} finally {
		$ErrorActionPreference = $prev
	}
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

Ensure-EnvFile
Ensure-Docker
Ensure-Cloudflared

# Evitar choques con npm run start:dev / flutter run.
Stop-ProjectDevServer -port 3000
Stop-ProjectDevServer -port 8080

Ensure-FlutterWeb

Write-Step "Levantando base de datos, API, web y backups"
$composeArgs = @("-f", $ComposeFile, "--env-file", $EnvFile, "up", "-d", "--remove-orphans")
if ($Rebuild) { $composeArgs += "--build" }
Invoke-Compose -ComposeArgs $composeArgs

if (-not (Wait-Url "http://127.0.0.1:3000/v1/ready")) {
	$prev = $ErrorActionPreference
	$ErrorActionPreference = "Continue"
	& docker compose -f $ComposeFile --env-file $EnvFile logs api --tail 100 2>&1 | Out-Host
	$ErrorActionPreference = $prev
	throw "La API no quedó lista."
}
if (-not (Wait-Url "http://127.0.0.1:8080/health" 60)) {
	$prev = $ErrorActionPreference
	$ErrorActionPreference = "Continue"
	& docker compose -f $ComposeFile --env-file $EnvFile logs web --tail 60 2>&1 | Out-Host
	$ErrorActionPreference = $prev
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
