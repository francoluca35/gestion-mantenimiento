# Gestión de Mantenimiento

Reemplazo moderno de **SGMWin** (LyM Ingeniería) para Sika Argentina.

SGMWin es el documento de **requisitos funcionales**, no el diseño de la aplicación.

## Stack

| Capa | Tecnología |
|------|------------|
| App (técnicos + admin) | **Flutter** (Android + Web, un solo código) |
| Backend | NestJS + API REST |
| Base de datos | PostgreSQL 16 + Row-Level Security |
| Storage (fotos/PDF) | MinIO (dev) → Cloudflare R2 / S3 (prod) |
| Colas | Redis |
| Push | Firebase Cloud Messaging |
| PDF de OT | Puppeteer (Fase 2) |

## Estructura

```
gestion-mantenimiento/
├── apps/
│   ├── api/        # NestJS
│   └── client/     # Flutter (Android + Web)
├── packages/
│   ├── database/   # Init SQL, migraciones
│   └── shared/     # Tipos compartidos
├── docs/           # Especificación funcional y técnica
├── docker-compose.yml
└── .env.example
```

## Arranque rápido (desarrollo)

### 1. Infra (Docker)

```bash
cp .env.example .env
docker compose up -d
```

Servicios:

| Servicio | URL |
|----------|-----|
| PostgreSQL | `localhost:5432` (user `sika` / pass `sika_dev`) |
| Redis | `localhost:6379` |
| MinIO API | http://localhost:9000 |
| MinIO Console | http://localhost:9001 (`minioadmin` / `minioadmin`) |

### 2. API + base de datos (M1)

```bash
cd apps/api
npm install
npx prisma migrate dev
npx prisma db seed
npm run start:dev
```

Health: http://localhost:3000/v1/health

### 3. Flutter

```bash
cd apps/client
flutter pub get

# Web (admin / desktop)
flutter run -d chrome --web-port=8080

# Android (emulador)
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1
```

### Usuarios demo (clave: `Sika123!`)

| Usuario | Rol |
|---------|-----|
| `admin` | Administrador global (todas las sucursales) |
| `tecnico` | Técnico — Planta Virrey |
| `panolero` | Pañolero — Planta Virrey |
| `supervisor` | Supervisor — Planta Virrey |
| `admin.virrey` | Admin de sucursal — Planta Virrey |

## Módulos

1. **Seguridad** — Login, usuarios, perfiles, derechos, sucursales
2. **Planta** — Ubicaciones, equipos, tipos de equipo
3. **Mantenimiento** — Procedimientos, OT, checklist, fotos, firma
4. **Pañol** — Materiales, stock, movimientos, herramientas
5. **Compras** — OC, proveedores, vales
6. **Indicadores** — KPIs, Pareto, costos, Gantt
7. **Notificaciones** — Push en cada paso del proceso

## Documentación

Ver [`docs/`](./docs/):

- [01 — Módulos](./docs/01-modulos.md)
- [02 — Entidades](./docs/02-entidades.md)
- [03 — Relaciones](./docs/03-relaciones.md)
- [04 — Flujos](./docs/04-flujos.md)
- [05 — Permisos](./docs/05-permisos.md)
- [06 — APIs](./docs/06-apis.md)
- [07 — Pantallas](./docs/07-pantallas.md)
- [08 — UI/UX](./docs/08-ui-ux.md)
- [09 — Roadmap](./docs/09-roadmap.md)
- [10 — Infraestructura](./docs/10-infraestructura.md)

## Producción (Sika)

| Qué | Dónde |
|-----|-------|
| API + PostgreSQL | Servidor Windows Sika |
| Fotos, firmas, PDFs, backups | **Nube** (R2 / S3) |
| Acceso 4G | Cloudflare Tunnel + HTTPS |
| Push | Firebase FCM |

Solo se cambian variables de `.env`. El código de storage es el mismo.

## Referencia

- Sistema original: [SGMWin — LyM Ingeniería](https://www.lym.com.ar)
- Cliente: Sika Argentina S.A.
