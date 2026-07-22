@echo off
setlocal
title Detener Gestion de Mantenimiento
cd /d "%~dp0"
color 0E

echo Deteniendo Gestion de Mantenimiento...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\demo-down.ps1"
if errorlevel 1 (
	color 0C
	echo Error al detener.
	pause
	exit /b 1
)

echo Servidor detenido. Cloudflared queda activo para el proximo inicio.
timeout /t 5
