# Sprint 5 — Infra demo 2 meses

**Rama:** `Sprint-5/infra-demo`  
**Objetivo:** la demo no depende de la notebook de desarrollo.

Ver también [`../10-infraestructura.md`](../10-infraestructura.md).

---

## Qué incluye este sprint

| Artefacto | Rol |
|-----------|-----|
| [`docker-compose.demo.yml`](../../docker-compose.demo.yml) | Postgres + Redis + MinIO + API Nest |
| [`apps/api/Dockerfile`](../../apps/api/Dockerfile) | Build producción API + `migrate deploy` al arrancar |
| [`scripts/backup-postgres.ps1`](../../scripts/backup-postgres.ps1) | `pg_dump` diario + retención 14 días |
| Carpeta `backups/` | Destino de dumps (gitignored) |

---

## Deploy en host estable (servidor Sika / VM)

```bash
# 1) Clonar y configurar
git clone <repo> && cd gestion-mantenimiento
cp .env.example .env.demo
# Editar: JWT_*, POSTGRES_PASSWORD, FIREBASE_*, STORAGE_PUBLIC_URL=http://<IP>:9000/sika-mantenimiento

# 2) Levantar
docker compose -f docker-compose.demo.yml --env-file .env.demo up -d --build

# 3) Seed (una vez)
docker exec -it sika-demo-api npx prisma db seed
# Si el seed no está en la imagen runner, correr desde apps/api en el host apuntando a DATABASE_URL del contenedor.

# 4) Health
curl http://localhost:3000/v1/health
```

### Acceso Android / web

| Escenario | URL API |
|-----------|---------|
| Misma LAN (IP fija) | `http://192.168.x.x:3000/v1` |
| Emulador Android en el servidor | `http://10.0.2.2:3000/v1` |
| Fuera de planta | Cloudflare Tunnel → HTTPS → API `:3000` |

En la app: **Perfil → Servidor API** (sin rebuild).

### Backups

```powershell
# Manual
powershell -File scripts/backup-postgres.ps1

# Task Scheduler: diario 02:00 → mismo comando
```

Restaurar:

```bash
gunzip -c backups/gestion_mantenimiento-YYYYMMDD-HHMMSS.sql.gz | docker exec -i sika-demo-postgres psql -U sika -d gestion_mantenimiento
```

---

## Checklist de aceptación

- [ ] `docker compose -f docker-compose.demo.yml up -d --build` OK
- [ ] `GET /v1/health` responde
- [ ] Login `tecnico` / `panolero` / `admin` con `Sika123!`
- [ ] Push FCM con `FIREBASE_*` en `.env.demo`
- [ ] APK/emulador apunta a IP del host (no a la notebook)
- [ ] Backup diario programado; al menos un `.sql.gz` en `backups/`
- [ ] Notebook apagada → demo sigue viva

---

## Fuera de alcance (siguientes)

- CI deploy automático
- Alta disponibilidad / réplicas
- R2 producción (se puede apuntar `STORAGE_*` sin cambiar compose)
