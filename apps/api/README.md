# API — NestJS

Backend REST del sistema de gestión de mantenimiento.

## Arranque

Desde la raíz del monorepo, con Docker levantado:

```bash
cd apps/api
npm install
npm run start:dev
```

- Health: http://localhost:3000/v1/health
- Storage: http://localhost:3000/v1/storage/status

Las variables se leen de `../../.env` (raíz del monorepo).

## Módulos

```
src/modules/
├── storage/     # Fotos, firmas, PDFs (MinIO / R2 / S3)
├── seguridad/   # (próximo) Auth, usuarios, perfiles
├── planta/      # (próximo)
├── mantenimiento/
├── panol/
├── compras/
├── indicadores/
└── notificaciones/
```

Ver [06-apis.md](../../docs/06-apis.md) y [10-infraestructura.md](../../docs/10-infraestructura.md).
