@echo off
setlocal
title Iniciar Gestion de Mantenimiento
cd /d "%~dp0"
color 0B

echo ============================================================
echo        GESTION DE MANTENIMIENTO - INICIANDO SERVIDOR
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-sika.ps1"
if errorlevel 1 (
	color 0C
	echo.
	echo ERROR: no se pudo iniciar. Revise los mensajes anteriores.
	pause
	exit /b 1
)

rem Consolas de monitoreo (se pueden cerrar; los contenedores siguen activos).
start "SIKA - API Logs" cmd /k "cd /d %~dp0 && docker compose -f docker-compose.demo.yml --env-file .env.demo logs -f --tail 40 api"
start "SIKA - Backup Logs" cmd /k "cd /d %~dp0 && docker compose -f docker-compose.demo.yml --env-file .env.demo logs -f --tail 20 backup"

echo.
echo Servidor iniciado. Se abrio la aplicacion en Chrome.
echo Puede cerrar esta ventana y las ventanas de logs.
timeout /t 8
exit /b 0
