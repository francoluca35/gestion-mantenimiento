# Database — PostgreSQL

## Desarrollo

Se levanta con Docker Compose desde la raíz del monorepo.

```bash
docker compose up -d postgres
```

Scripts de init en `init/` se ejecutan solo en el **primer** arranque del volumen.

## Contenido

```
database/
├── init/
│   └── 01-schemas.sql   # public + analytics + audit
├── migrations/          # (pendiente) migraciones Prisma/TypeORM
├── seeds/               # (pendiente) derechos, catálogos
└── rls/                 # (pendiente) políticas por sucursal
```

Ver [02-entidades.md](../../docs/02-entidades.md) y [03-relaciones.md](../../docs/03-relaciones.md).
