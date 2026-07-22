@echo off
setlocal
title Estado Gestion de Mantenimiento
cd /d "%~dp0"
color 0A

echo ============================================================
echo          ESTADO DE GESTION DE MANTENIMIENTO
echo ============================================================
echo.
docker compose -f docker-compose.demo.yml --env-file .env.demo ps
echo.
powershell -NoProfile -Command "try { $r=Invoke-WebRequest 'http://127.0.0.1:3000/v1/ready' -UseBasicParsing -TimeoutSec 5; Write-Host 'API local: OK' -ForegroundColor Green } catch { Write-Host 'API local: CAIDA' -ForegroundColor Red }; try { $r=Invoke-WebRequest 'https://api.sorjuanaliberte.store/v1/health' -UseBasicParsing -TimeoutSec 10; Write-Host 'Cloudflare: OK' -ForegroundColor Green } catch { Write-Host 'Cloudflare: CAIDO' -ForegroundColor Red }"
echo.
pause
