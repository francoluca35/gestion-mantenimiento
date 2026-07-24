@echo off
setlocal EnableExtensions
title Iniciar Gestion de Mantenimiento
cd /d "%~dp0"
color 0B

echo ============================================================
echo        GESTION DE MANTENIMIENTO - INICIANDO SERVIDOR
echo ============================================================
echo.
echo Carpeta: %CD%
echo.

where docker >nul 2>&1
if errorlevel 1 (
	color 0C
	echo ERROR: Docker no esta en el PATH.
	echo Instala Docker Desktop y reinicia la PC.
	pause
	exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-sika.ps1"
if errorlevel 1 (
	color 0C
	echo.
	echo ERROR: no se pudo iniciar. Revise los mensajes anteriores.
	pause
	exit /b 1
)

rem Consolas de monitoreo (se pueden cerrar; los contenedores siguen activos).
start "SIKA - API Logs" cmd /k "cd /d \"%~dp0\" && docker compose -f docker-compose.demo.yml --env-file .env.demo logs -f --tail 40 api"
start "SIKA - Backup Logs" cmd /k "cd /d \"%~dp0\" && docker compose -f docker-compose.demo.yml --env-file .env.demo logs -f --tail 20 backup"

echo.
echo ============================================================
echo  LISTO
echo  Web PC:    http://localhost:8080
echo  API:       http://localhost:3000/v1
echo  Movil:     https://api.sorjuanaliberte.store/v1
echo ============================================================
echo.
echo Puede cerrar esta ventana y las ventanas de logs.
timeout /t 10
exit /b 0
