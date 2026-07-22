# Sprint 5 — Infra demo 2 meses (robusta)

**Objetivo:** tu PC Windows actúa como servidor 24/7. Celulares y otras PCs entran por HTTPS (`api.sorjuanaliberte.store`) vía Cloudflare Tunnel. La notebook de desarrollo ya no es requisito.

Ver también [`../10-infraestructura.md`](../10-infraestructura.md).

---

## Qué incluye

| Artefacto | Rol |
|-----------|-----|
| [`docker-compose.demo.yml`](../../docker-compose.demo.yml) | Postgres + API + backup diario + cloudflared (profile) |
| [`apps/api/Dockerfile`](../../apps/api/Dockerfile) | Multi-stage, migrate al arrancar, healthcheck, non-root |
| [`.env.demo.example`](../../.env.demo.example) | Plantilla de secretos / dominio / tunnel |
| [`scripts/demo-up.ps1`](../../scripts/demo-up.ps1) | Build + up + espera `/v1/ready` |
| [`scripts/demo-down.ps1`](../../scripts/demo-down.ps1) | Apagar stack |
| [`scripts/seed-demo.ps1`](../../scripts/seed-demo.ps1) | Seed one-shot (usuarios demo) |
| [`scripts/backup-loop.sh`](../../scripts/backup-loop.sh) | Backup automático dentro de Docker |
| [`scripts/backup-postgres.ps1`](../../scripts/backup-postgres.ps1) | Backup manual |
| [`scripts/restore-postgres.ps1`](../../scripts/restore-postgres.ps1) | Restore desde `.sql.gz` |
| [`scripts/install-autostart.ps1`](../../scripts/install-autostart.ps1) | Task Scheduler al iniciar sesión |

**Red:** solo el puerto `3000` (API) sale al host. Postgres no se publica. Storage por defecto = `local` (fotos por la misma API/HTTPS).

---

## 1) Primera vez en la PC servidor

```powershell
cd D:\Clientes-2026\sika\gestion-mantenimiento
cp .env.demo.example .env.demo
# Editar .env.demo:
#   POSTGRES_PASSWORD, JWT_SECRET, JWT_REFRESH_SECRET (fuertes)
#   PUBLIC_BASE_URL=https://api.sorjuanaliberte.store
#   CLOUDFLARE_TUNNEL_TOKEN=<token del tunnel>
```

### Cloudflare Tunnel (dominio `sorjuanaliberte.store`)

1. Cloudflare Zero Trust → **Networks → Tunnels → Create**
2. Copiá el **Tunnel token** → `CLOUDFLARE_TUNNEL_TOKEN` en `.env.demo`
3. Public hostname:
   - **Hostname:** `api.sorjuanaliberte.store`
   - **Service:** `http://api:3000`
4. En DonWeb/Cloudflare DNS: el CNAME lo crea Zero Trust (proxied)

```powershell
powershell -File scripts/demo-up.ps1 -WithTunnel -Seed
# o sin seed la primera vez:
powershell -File scripts/demo-up.ps1 -WithTunnel
powershell -File scripts/seed-demo.ps1
```

### Arranque automático Windows

1. Docker Desktop → Settings → General → **Start Docker Desktop when you log in**
2. Luego:

```powershell
powershell -File scripts/install-autostart.ps1
```

Log: `backups\autostart.log`

### Firewall Windows

Abrí **TCP 3000** (entrada) para fallback LAN:

```powershell
New-NetFirewallRule -DisplayName "Sika API 3000" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
```

---

## 2) Acceso clientes

| Escenario | URL API |
|-----------|---------|
| **Android / remoto (recomendado)** | `https://api.sorjuanaliberte.store/v1` |
| Misma LAN (sin Internet) | `http://<IP-PC>:3000/v1` |
| Emulador en la PC | `http://10.0.2.2:3000/v1` |
| Web local | API `http://localhost:3000/v1` |

En Android: **Perfil → Servidor API** (sin reinstalar).

Health:

```bash
curl https://api.sorjuanaliberte.store/v1/health
curl https://api.sorjuanaliberte.store/v1/ready
curl http://127.0.0.1:3000/v1/ready
```

Login demo: `admin` / `tecnico` / `panolero` — clave `Sika123!`

---

## 3) Backups y restore

Automático: contenedor `sika-demo-backup` (diario UTC `BACKUP_HOUR_UTC`, retención `BACKUP_KEEP_DAYS`).

Manual:

```powershell
powershell -File scripts/backup-postgres.ps1
```

Restore:

```powershell
powershell -File scripts/restore-postgres.ps1 -BackupFile backups\gestion_mantenimiento-YYYYMMDD-HHMMSS.sql.gz
```

---

## 4) Operación diaria

```powershell
powershell -File scripts/demo-up.ps1          # levantar / rebuild
powershell -File scripts/demo-down.ps1        # bajar
docker compose -f docker-compose.demo.yml --env-file .env.demo ps
docker compose -f docker-compose.demo.yml --env-file .env.demo logs -f api
```

Profiles opcionales:

| Profile | Qué agrega |
|---------|------------|
| `tunnel` | cloudflared (si hay token) |
| `seed` | job one-shot de seed |
| `with-minio` | MinIO (solo si cambiás a `STORAGE_PROVIDER=minio`) |
| `with-redis` | Redis (reservado; la API aún no lo usa) |

---

## Checklist de aceptación

- [ ] `demo-up.ps1` OK; `GET /v1/ready` → 200
- [ ] Seed OK; login `admin` / `Sika123!`
- [ ] `https://api.sorjuanaliberte.store/v1/health` desde el celular
- [ ] APK: Perfil → URL = `https://api.sorjuanaliberte.store/v1` → login
- [ ] Aparece un `.sql.gz` en `backups/` (manual o tras el primer ciclo del backup)
- [ ] Reinicio de Windows + Docker Desktop → stack vuelve (Task Scheduler)
- [ ] Notebook de desarrollo apagada → demo sigue viva en la PC servidor

---

## Fuera de alcance (siguientes)

- CI deploy automático
- Keystore Play Store
- Alta disponibilidad / réplicas
- Storage R2 producción (cambiar `STORAGE_*` sin tocar el compose base)
