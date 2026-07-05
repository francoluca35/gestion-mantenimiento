# Faltantes — Módulo 2 (Planta)

Estado actual: **fundación usable** (API + seed Virrey + UI árbol/máquinas).

## Jerarquía de negocio (recordar)

```
SIKA                                  ← empresa (fijo en UI)
  └── PLANTA_VIRREY                   ← planta del usuario logueado
        └── (ubicaciones que cree el usuario)
              └── (sectores)
                    └── (máquinas)
```

- El usuario **solo ve su planta** (`sucursal_id`). No hay selector de otras plantas.
- Al inicio el árbol está vacío bajo la planta: se crean ubicaciones, sectores y máquinas desde la app.
- Profundidad variable: ubicación → máquina, o ubicación → sector → máquina.
- UI: explorador moderno (sidebar + detalle + stats), inspirado en gestión de equipos contemporánea.

---

## Qué ya está

### Backend

- Tablas: `ubicaciones`, `tipos_equipo`, `equipos`, `componentes`, `lecturas`
- Árbol de ubicaciones (crear, modificar, borrar, mover)
- Equipo solo en nodo hoja
- CRUD tipos de equipo
- CRUD equipos (mover, fuera de servicio)
- Lecturas por equipo
- Filtro por sucursal (lógica NestJS)
- Seed Planta Virrey (Silos Externos → Sector Losa → SILO-103/104, Molienda → MOL-01)

### Flutter

- Ruta `/planta` y acceso desde nav (si tiene `archivos.equipos.listar`)
- Árbol de ubicaciones
- Lista de equipos (filtro por nodo)
- Detalle de equipo (detalle JSON + últimas lecturas)
- Alta simple de ubicación y equipo
- Selector de sucursal para admin global

---

## Qué falta

| Ítem | Prioridad |
|------|-----------|
| Editar / borrar ubicación desde UI | Alta |
| Editar equipo, marcar fuera de servicio desde UI | Alta |
| Mover nodo / equipo (drag o diálogo) en UI | Media |
| Form builder de campos dinámicos de TipoEquipo | Media |
| Componentes de equipo (API parcial, sin UI) | Baja |
| Gráfico de lecturas / contadores | Baja (M3/M6) |
| Planos / fotos de equipo en storage | Baja |
| RLS PostgreSQL por `sucursal_id` | Alta (prod) |
| Validar `sector_id` de Usuario contra Ubicacion | Media (cierra faltante M1) |
| Tests e2e planta | Media |

---

## Listo para M3

Con lo actual se puede emitir OT sobre `equipo_id` real (SILO-103, etc.).

---

## Referencias

- `docs/01-modulos.md` — alcance M2
- `docs/02-entidades.md` — modelo
- `docs/06-apis.md` — contrato REST
