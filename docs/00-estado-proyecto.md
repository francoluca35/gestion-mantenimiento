# 00 — Estado del proyecto

Documento maestro: **qué hay**, **qué falta** y **qué mejorar**.

**Última actualización:** 2026-07-16

---

## Resumen ejecutivo

| Área | Estado global | Notas |
|------|---------------|-------|
| **M1 Seguridad** | 🟢 ~92% | RLS, CRUD UI, editor derechos, perfil clave/sesiones, e2e |
| **M2 Planta** | 🟢 ~90% | CRUD UI, documentos, lecturas, mover/editar, e2e |
| **M3 Mantenimiento** | 🟢 ~90% | Ola 2 + Sprints 1–3; FCM en Sprint 4 (código listo) |
| **M4 Pañol** | ❌ 0% | Fase 2 |
| **M5 Compras** | ❌ 0% | Fase 2 |
| **M6 Indicadores** | ❌ ~5% | Solo resumen OT en home |
| **M7 Notificaciones** | 🟡 ~80% | Push FCM + deep-link Mis OT; falta validar E2E en Android |
| **Paridad SGwing** | 🟡 ~58% | 32 capturas en `docs/images/` |
| **Paridad SGMWin manual** | 🟡 ~45% | Ver `MATRIZ-PARIDAD.md` |
| **Shell adaptativo móvil** | 🟡 ~75% | Bottom nav por rol, sidebars colapsables con flecha |

**Principio de plataforma:** un solo Flutter (Web + Android), **todos los roles** en ambas plataformas. Misma API y permisos; la UI se adapta al ancho de pantalla y al perfil del usuario.

---

## Qué se hizo

### Infraestructura y fundación

- Monorepo: NestJS (`apps/api`) + Flutter (`apps/client`) + Docker (PostgreSQL, Redis, MinIO).
- Auth JWT + refresh + guards por derecho (`JwtAuthGuard`, `DerechoGuard`).
- Seed demo Planta Virrey con usuarios: `admin`, `supervisor`, `tecnico`, `panolero`, `admin.virrey` (clave `Sika123!`).
- Documentación funcional completa (`docs/01`–`10`) + manual SGMWin parseado + 32 capturas SGwing.

### M1 — Seguridad (cerrado desarrollo — 2026-07-09)

| Hecho | Detalle |
|-------|---------|
| Login / logout / sesión persistida | Flutter + API |
| CRUD API + UI | usuarios, perfiles, sucursales |
| Editor derechos Total/Parcial | `/perfiles/:id/derechos` |
| Árbol derechos (solo lectura) | `/derechos` + `GET /derechos/tree` |
| Perfil usuario | Cambio de clave, sesiones, revocar todas |
| `sectorId` en usuario | API + dropdown en formulario |
| RLS PostgreSQL | Políticas por sucursal + contexto Prisma |
| Tests e2e auth | `auth-security.e2e-spec.ts` — 6/6 OK |
| Árbol de derechos (seed parcial) | Total/Parcial en `PermisosService` |
| Flags de rol | `es_administrador`, `supervisa_sucursales`, etc. |

| Diferido | Detalle |
|----------|---------|
| Árbol derechos 1:1 SGMWin | Ampliar seed según `docs/05-permisos.md` |
| Recuperación de clave | Opcional |
| Invalidar JWT access al cambiar clave | Sesiones DB revocadas; access token stateless |

### M2 — Planta (cerrado desarrollo — 2026-07-09)

| Hecho | Detalle |
|-------|---------|
| Árbol ubicaciones | CRUD API + UI (crear, editar, borrar, mover) |
| Equipos | Alta/edición/mover, fuera de servicio, campos dinámicos tipo |
| Ficha máquina | Tabs: General, Lecturas, Historial, Procedimientos, Documentos |
| Documentos adjuntos | API + storage presign + tab Documentos |
| Lecturas | Alta desde ficha + mini gráfico de barras |
| Procedimientos por alcance | Planta / sector / equipo |
| Selector planta | Admin y supervisa sucursales |
| Tests e2e | `planta.e2e-spec.ts` — 3/3 OK |
| Picker mapa | `planta_equipo_picker_dialog` + `PlantaMapPanel` |
| Seed Virrey | Silos Externos → Sector Losa → SILO-103/104, MOL-01 |

### M3 — Mantenimiento (Ola 2 ✅ cerrada web — 2026-07-08)

| Hecho | Detalle |
|-------|---------|
| Mapa lateral `/ot` | 3 columnas: lista · detalle · mapa; filtro planta/sector/equipo |
| Mapa `/ot/necesarias` | Vista previa, técnico por fila, filtro por ámbito |
| Colores OT SGwing-17 | Verde realizada · rojo pendiente · amarillo en ejecución (`ot_ui.dart`) |
| PDF OT (plantilla SGwing) | `GET /ot/:id/pdf` + `GET /ot/:id/pdf/view` — HTML imprimible paridad OT-4783 |
| Push al asignar (stub) | Log `[push:disabled]` sin credenciales; código listo para Android |
| Smoke test Ola 2 | `node tools/smoke-ola2.mjs` — 12/12 OK (2026-07-08) |
| Procedimientos por nodo | `/planta` — alcance planta/sector |
| Shell móvil | Bottom nav por rol; ruta `/mis-ot` para técnico |
| Sidebars colapsables | Flecha en menú global, lista OT, mapa, explorador planta |
| Mapa planta embebido | `PlantaMapPanel` — raíz en planta del usuario, selección libre |
| Paleta Sika | Amarillo `#FFB11B` · rojo `#E30613` · blanco/negro en tema |

| Diferido post-Ola 2 | Detalle |
|---------------------|---------|
| FCM push real | ✅ código + env; falta validar E2E en Android |
| PDF binario | Puppeteer → `.pdf` descargable (opcional; HTML ya imprimible) |
| Animaciones finas | Transiciones mapa y colapso paneles |

### Documentación de paridad

| Documento | Contenido |
|-----------|-----------|
| [`faltantes/sgwing-paridad.md`](faltantes/sgwing-paridad.md) | Checklist 32 pantallas + sprints A–E |
| [`referencias/MATRIZ-PARIDAD.md`](referencias/MATRIZ-PARIDAD.md) | Manual SGMWin capítulo a capítulo |
| [`images/Sistema_SGwing.md`](images/Sistema_SGwing.md) | Referencia visual con capturas |
| [`faltantes/m1-m3`](faltantes/) | Faltantes por módulo |

---

## Qué falta (priorizado)

### P0 — Ola 2 inmediata (SGwing UX)

Ver [`faltantes/sgwing-paridad.md`](faltantes/sgwing-paridad.md) Sprint A–B.

| # | Ítem | Estado | Referencia |
|---|------|--------|------------|
| 1 | Mapa lateral en `/ot` + filtro por planta/sector | ✅ | sgwing-16, 32 |
| 2 | Mapa en `/ot/necesarias` + vista previa + técnico por fila | ✅ | sgwing-30, 31 |
| 3 | Colores OT: verde / rojo / amarillo | ✅ | sgwing-17 |
| 4 | PDF de OT | ✅ plantilla SGwing | sgwing-12, 31 |
| 5 | Push al asignar técnico | 🟡 código listo | sgwing-25, 31 (M7) — validar en Android |
| 6 | Procedimientos filtrados por nodo planta/sector en `/planta` | ✅ | sgwing-14 |
| 7 | **Shell móvil** — bottom nav + sidebars colapsables | ✅ | `08-ui-ux.md` |
| 8 | Flujo Android técnico (Mis OT → checklist → firma → cerrar) | ✅ | A-01–A-11 |
| 9 | Paleta corporativa Sika en tema Flutter | ✅ | logo marca |

### P1 — Corto plazo (post Ola 2)

| Área | Ítems |
|------|-------|
| M1 | CRUD UI usuarios/perfiles/sucursales, editor derechos Total/Parcial |
| M1 | RLS PostgreSQL por `sucursal_id` |
| M2 | Editar/borrar ubicación, mover nodos, documentos equipo |
| M3 | Filtros avanzados OT, columnas extendidas, fotos en OT |
| M3 | OT no periódica: sector, fechas inicio/fin, campo recibe |
| M4 | Pañol, stock, reserva materiales (sgwing-04) |
| Móvil | Vistas supervisor (OT sector, conformidad rápida) y gerencia (KPIs resumen) |

### P2 — Medio plazo

| Área | Ítems |
|------|-------|
| M3 | Gantt, OT derivada, búsqueda avanzada procedimientos |
| M3 | Emisión automática cron, emisión por contador |
| M5 | Órdenes de compra, proveedores |
| M6 | Dashboard gerencial, TMEF, ICO, Pareto |
| Móvil | Offline + sync técnico |

### P3 — Largo plazo

- Versiones/histórico procedimiento (sgwing-07)
- Copiar/pegar equipo (sgwing-09)
- Anexos SGMWin (planos, Report Pro, gráficas avanzadas)
- Tests e2e completos por módulo

---

## Qué se puede mejorar

### Arquitectura y código

| Mejora | Impacto | Estado actual |
|--------|---------|---------------|
| Conectar `AdaptiveScaffold` al router | Medio — bottom nav ya en `AppShell` | Parcialmente resuelto |
| Unificar breakpoints | Medio | Mezcla de 600 / 900 / 960 px en distintas pantallas |
| RLS en PostgreSQL | Alto (seguridad prod) | Solo filtro en servicios NestJS |
| Tests e2e auth, OT, planta | Alto | Casi sin cobertura |
| `prisma generate` con API corriendo | Bajo | EPERM en Windows si API bloquea DLL |

### UX / producto

| Mejora | Detalle |
|--------|---------|
| Colores OT consistentes | ✅ Semántica SGwing + paleta Sika en tema global |
| Selector de sucursal al login | Admin global — recordar última planta |
| Bottom nav por rol | Técnico: Inicio / OT / Notif / Perfil; Supervisor: Inicio / OT / Solicitudes / Notif |
| Pantallas “pesadas” en móvil | Editor derechos, Gantt, export masivo → desktop-first pero no bloqueados |
| Animaciones y transiciones | Parcial (`AnimatedSwitcher` en shell); unificar en navegación móvil |
| Accesibilidad en planta | Targets táctiles 48dp+, contraste, uso con guantes |

### Documentación

| Mejora | Acción |
|--------|--------|
| Mantener este doc al cerrar sprints | Actualizar tablas “hecho / falta” |
| Vincular PRs | ID `sgwing-XX` o `cap4-ot-necesarias` |
| `m2-planta.md` desactualizado parcialmente | Revisar tras cada sprint de planta |

### Operaciones / prod

| Mejora | Detalle |
|--------|---------|
| CI/CD | Lint + test + build en pipeline |
| Storage prod | MinIO dev → R2/S3 (código listo, falta deploy) |
| FCM | Firebase proyecto + tokens en app Android |
| Cloudflare Tunnel | Acceso 4G desde planta |

---

## Plataformas y roles

| Rol | Web (≥900px) | Android / móvil (<900px) |
|-----|--------------|---------------------------|
| **Técnico** | Acceso completo si tiene permisos | Flujo lineal: Mis OT, checklist, firma |
| **Supervisor** | OT, solicitudes, mapa, emisión | Conformidad, OT sector, alertas |
| **Admin sucursal** | Config, usuarios, planta, OT | Consultas + aprobaciones rápidas |
| **Admin global** | Todas las sucursales | Mismo menú por permisos; config pesada mejor en desktop |
| **Gerencia** | Dashboards, KPIs (futuro M6) | Resumen ejecutivo + alertas |
| **Pañolero** | Stock (futuro M4) | Solicitudes materiales, alertas stock |

**Regla:** el menú y las rutas dependen de **derechos**, no de la plataforma. No hay bloqueo `kIsWeb` en el código actual.

---

## Rutas Flutter implementadas

| Ruta | Módulo | Estado UI |
|------|--------|-----------|
| `/login` | M1 | ✅ |
| `/home` | M3/M6 | 🟡 métricas básicas |
| `/procedimientos` | M3 | 🟡 Ola 1 |
| `/planta` | M2 | 🟡 tabs completos |
| `/ot` | M3 | ✅ mapa lateral + colores + móvil |
| `/ot/necesarias` | M3 | ✅ mapa + preview + técnico |
| `/mis-ot` | M3 | ✅ flujo técnico móvil |
| `/ot/emitir-no-periodica` | M3 | 🟡 |
| `/solicitudes` | M3 | ✅ Ola 1 |
| `/contadores` | M2/M3 | 🟡 listado sin gráfico |
| `/config`, `/usuarios`, `/perfiles`, `/sucursales` | M1 | 🟡 solo lectura |
| `/perfil` | M1 | ✅ |

---

## Olas de entrega

```
Ola 1 — Núcleo operativo     ✅ 2026-07-06
Ola 2 — SGwing UX + móvil    ✅ cerrada web (FCM diferido)
Ola 3 — Stock y compras      ← ACTUAL (Fase 2)
Ola 4 — KPIs + offline       Fase 3
```

Detalle Ola 2: [`faltantes/sgwing-paridad.md`](faltantes/sgwing-paridad.md)  
Roadmap general: [`09-roadmap.md`](09-roadmap.md)

---

## Demo rápida (5 min)

1. `supervisor` / `Sika123!` → `/procedimientos` → asociar a planta o sector
2. `/ot/necesarias` → SILO-104 vencido → emitir
3. `/solicitudes` → conformar → emitir OT con mapa
4. Logout → `tecnico` → `/ot` → trabajar OT en ejecución

API: `http://localhost:3000/v1` · Web: `http://localhost:8080`

---

## Índice de documentos importantes

| Doc | Para qué |
|-----|----------|
| **Este archivo** | Estado global, hecho/falta/mejoras |
| [`01-modulos.md`](01-modulos.md) | Arquitectura por módulo |
| [`07-pantallas.md`](07-pantallas.md) | Inventario de vistas por rol y plataforma |
| [`08-ui-ux.md`](08-ui-ux.md) | Design system y patrones adaptativos |
| [`09-roadmap.md`](09-roadmap.md) | Fases y sprints |
| [`10-infraestructura.md`](10-infraestructura.md) | Dev, Docker, storage, deploy |
| [`faltantes/sgwing-paridad.md`](faltantes/sgwing-paridad.md) | 32 pantallas Sika + prioridades |
| [`referencias/MATRIZ-PARIDAD.md`](referencias/MATRIZ-PARIDAD.md) | Paridad manual SGMWin |
| [`images/Sistema_SGwing.md`](images/Sistema_SGwing.md) | Capturas + notas de negocio |
| [`faltantes/m1-seguridad.md`](faltantes/m1-seguridad.md) | Detalle pendiente M1 |
| [`faltantes/m2-planta.md`](faltantes/m2-planta.md) | Detalle pendiente M2 |
| [`faltantes/m3-mantenimiento.md`](faltantes/m3-mantenimiento.md) | Detalle pendiente M3 |

---

## Cómo mantener actualizado

1. Al cerrar un ítem de Ola 2, marcar en `sgwing-paridad.md` y actualizar la tabla de este doc.
2. Al terminar un módulo, mover ítems de `faltantes/mX-*.md` a “Qué se hizo” aquí.
3. Registrar mejoras descubiertas en la sección **Qué se puede mejorar**.
4. Fecha en el encabezado al hacer revisiones significativas.
