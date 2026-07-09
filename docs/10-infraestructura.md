# 10 — Infraestructura

## Desarrollo (ahora)

```
Tu PC (Windows)
├── Docker Compose
│   ├── PostgreSQL 16   → localhost:5432
│   ├── Redis 7         → localhost:6379
│   └── MinIO           → localhost:9000 (API) / 9001 (consola)
├── NestJS API          → localhost:3000/v1
└── Flutter (Android + Web)
```

### Comandos

```bash
# Infra
docker compose up -d
docker compose ps
docker compose down

# API
cd apps/api
npm run start:dev

# Flutter Web
cd apps/client
flutter run -d chrome

# Flutter Android (emulador)
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1
```

### Credenciales locales

| Servicio | Usuario | Clave |
|----------|---------|-------|
| PostgreSQL | `sika` | `sika_dev` |
| MinIO | `minioadmin` | `minioadmin` |

Consola MinIO: http://localhost:9001

---

## Storage (fotos, firmas, PDFs, backups)

Abstracción `StorageService` en NestJS. Mismo código para dev y producción.

| Entorno | Provider | Endpoint |
|---------|----------|----------|
| Desarrollo | `minio` | `http://localhost:9000` |
| Producción | `r2` o `s3` | Cloudflare R2 / AWS S3 |

### Flujo de subida

```
Flutter → POST /v1/storage/presign
       ← { uploadUrl, publicUrl, key }
Flutter → PUT uploadUrl (directo a MinIO/R2/S3)
Flutter → confirma en API (guarda key en OT)
```

### Estructura de keys

```
{sucursalId}/{entityType}/{entityId}/{kind}/{timestamp}-{fileName}
```

Ejemplo:
```
planta-virrey/ot/uuid-ot/fotos/1719...-foto1.jpg
planta-virrey/ot/uuid-ot/firmas/1719...-firma.png
planta-virrey/ot/uuid-ot/pdf/1719...-ot-1234.pdf
```

### Variables (ver `.env.example`)

```env
STORAGE_PROVIDER=minio   # minio | r2 | s3 | local
STORAGE_BUCKET=sika-mantenimiento
STORAGE_ENDPOINT=http://localhost:9000
STORAGE_ACCESS_KEY=minioadmin
STORAGE_SECRET_KEY=minioadmin
STORAGE_PUBLIC_URL=http://localhost:9000/sika-mantenimiento
STORAGE_FORCE_PATH_STYLE=true
```

Para producción (Cloudflare R2), solo cambiar esas variables. **No se reescribe código.**

---

## Producción (servidor Windows Sika)

```
Servidor Windows Sika              Nube
─────────────────────              ────
PostgreSQL                         Cloudflare R2 o AWS S3
NestJS API                         Firebase FCM (push)
Redis (opcional)
Cloudflare Tunnel → HTTPS
```

| Qué | Dónde |
|-----|-------|
| OT, stock, usuarios, permisos | PostgreSQL en Sika |
| Fotos, firmas, PDFs, backups DB | R2 / S3 |
| Push | Firebase FCM |
| Acceso 4G | Tunnel + dominio + HTTPS |

---

## Flutter

Un solo proyecto (`apps/client`) compila a **Web** y **Android**.

**Todos los roles** (técnico, supervisor, admin, gerencia, pañolero) pueden usar ambas plataformas. El acceso a módulos lo define el perfil de derechos, no el dispositivo.

| Target | Uso típico | Layout |
|--------|------------|--------|
| **Web** | Oficina, pantallas grandes | Sidebar + tablas + panel detalle |
| **Android** | Planta, supervisión en movimiento | Bottom nav + flujo lineal |

Layout adaptativo (breakpoints 600 / 900 / 1200 px):

- **Móvil (<600px):** bottom nav + flujo lineal por rol
- **Tablet (600–900px):** rail compacto o split según pantalla
- **Desktop (≥900px):** sidebar expandido + panel principal + detalle lateral

Estado: pantallas con lógica `wide` implementada; shell global móvil (`AdaptiveScaffold`) pendiente — ver [`00-estado-proyecto.md`](00-estado-proyecto.md).
