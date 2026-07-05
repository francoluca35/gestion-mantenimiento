# 09 — Roadmap de desarrollo

Plan por fases con criterios de aceptación, estimaciones y dependencias.

---

## Resumen

| Fase | Duración estimada | Entregable |
|------|-------------------|------------|
| **0 — Análisis** | 2 semanas | Documentación completa (este repo `docs/`) |
| **1 — MVP** | 8-10 semanas | OT manual end-to-end + push |
| **2 — Operaciones** | 8-10 semanas | Stock, pañol, compras, emisión automática |
| **3 — Inteligencia** | 6-8 semanas | KPIs, offline, gráficos avanzados |

**Total estimado:** 24-30 semanas (~6-7 meses)

---

## Fase 0 — Análisis y especificación ✅

**Duración:** 2 semanas
**Estado:** En progreso

### Entregables

| # | Documento | Estado |
|---|-----------|--------|
| 01 | Módulos | ✅ |
| 02 | Entidades | ✅ |
| 03 | Relaciones | ✅ |
| 04 | Flujos de negocio | ✅ |
| 05 | Permisos | ✅ |
| 06 | APIs | ✅ |
| 07 | Pantallas | ✅ |
| 08 | UI/UX | ✅ |
| 09 | Roadmap | ✅ |

### Pendiente Fase 0

- [ ] Validar con demo de SGMWin (si disponible)
- [ ] Revisar con equipo Sika: módulos, prioridades, sucursales
- [ ] Definir infraestructura (VPS, dominio, certificados)
- [ ] Crear proyecto Firebase (solo FCM)
- [ ] Wireframes de alta fidelidad (Figma, opcional)

---

## Fase 1 — MVP

**Duración:** 8-10 semanas
**Objetivo:** Un técnico puede recibir, ver y cerrar una OT desde el celular.

### Sprint 1-2: Infraestructura + M1 Seguridad (3 semanas)

| Tarea | Detalle |
|-------|---------|
| Setup monorepo | NestJS + Flutter + PostgreSQL |
| CI/CD básico | Lint, test, build |
| Migraciones DB | Tablas M1 + seed de derechos |
| RLS | Políticas por sucursal |
| Auth JWT | Login, refresh, guards |
| CRUD usuarios/perfiles | Con árbol de derechos |
| CRUD sucursales | |
| Tests | Auth + permisos |

**Criterio de aceptación:**
- Login funcional con JWT
- Usuario técnico solo ve lo que su perfil permite
- Admin global ve todas las sucursales
- RLS bloquea acceso cross-sucursal

### Sprint 3-4: M2 Planta (2 semanas)

| Tarea | Detalle |
|-------|---------|
| Árbol de ubicaciones | CRUD + mover nodos |
| CRUD equipos | Con campos dinámicos JSON |
| Tipos de equipo | Editor de campos detalle/lectura |
| Lecturas/contadores | Agregar + listar |

**Criterio de aceptación:**
- Árbol de 4 niveles funcional (Planta Virrey → Silos → Sector → Equipo)
- Equipo con detalle dinámico según tipo
- Derivador de OT puede mantener el árbol

### Sprint 5-7: M3 Mantenimiento MVP (3 semanas)

| Tarea | Detalle |
|-------|---------|
| CRUD procedimientos | Con periodicidad |
| Emitir OT manual | Wizard completo |
| Asignar técnico | Con cambio de estado |
| Buscar OT | Filtros básicos |
| Cerrar OT | Checklist + firma |
| Timeline de estados | Historial de cambios |
| Solicitudes de trabajo | Crear + conformidad |

**Criterio de aceptación:**
- Supervisor emite OT → asigna técnico → técnico cierra con firma
- Estados transicionan correctamente
- OT aparece en historial del equipo

### Sprint 8: M7 Notificaciones + Flutter Android (2 semanas)

| Tarea | Detalle |
|-------|---------|
| FCM setup | Firebase + registro de tokens |
| Evento ot.asignada | Push al técnico |
| Flutter Android | Inicio, Mis OT, Detalle, Firma, Cerrar |
| Flutter Web básico | Login, dashboard, tabla OT, emitir |

**Criterio de aceptación:**
- Técnico recibe push al asignarle OT
- Técnico ve, ejecuta y cierra OT desde Android
- Admin emite OT desde web

---

## Fase 2 — Operaciones

**Duración:** 8-10 semanas
**Objetivo:** Flujo completo con materiales, pañol, compras y emisión automática.

### Sprint 9-10: M4 Pañol (3 semanas)

| Tarea | Detalle |
|-------|---------|
| Stock por pañol | CRUD + mínimos |
| Solicitud de materiales | Flujo aprobación |
| Movimientos de stock | Entrada, salida, reserva |
| Alertas stock mínimo | Job + push |
| Flutter Android pañolero | Solicitudes, aprobar/rechazar |

**Criterio de aceptación:**
- OT pasa a `pendiente_pañol` al solicitar materiales
- Pañolero aprueba → stock reservado → técnico puede ejecutar
- Pañolero rechaza → técnico notificado, puede reintentar
- Alerta cuando stock < mínimo

### Sprint 11-12: M3 extensión + PDF (2 semanas)

| Tarea | Detalle |
|-------|---------|
| Emisión automática | Cron por periodicidad |
| Emisión por contador | Umbral de lectura |
| PDF de OT | Puppeteer + plantilla HTML |
| Mano de obra en OT | Horas normales/extra |
| Materiales en OT | Consumo real |
| Fotos en OT | Upload a S3/R2 |

**Criterio de aceptación:**
- OT se emiten automáticamente sin PC prendido
- PDF de OT con datos actualizados
- Fotos adjuntas visibles en web y mobile

### Sprint 13-14: M5 Compras (3 semanas)

| Tarea | Detalle |
|-------|---------|
| Proveedores | CRUD + calificación |
| Órdenes de compra | Flujo completo |
| Autorización por monto | `monto_maximo_oc` |
| Vale de consumo | Emitir + PDF |
| Push OC > umbral | Notificar gerente |

**Criterio de aceptación:**
- OC se autoriza solo si usuario tiene monto suficiente
- Recepción de OC actualiza stock
- Vale de consumo vinculado a OT

---

## Fase 3 — Inteligencia

**Duración:** 6-8 semanas
**Objetivo:** KPIs, offline, gráficos avanzados.

### Sprint 15-16: M6 Indicadores (3 semanas)

| Tarea | Detalle |
|-------|---------|
| Esquema analytics | Vistas materializadas |
| KPIs | TMEF, TMPR, ICO, IMC, etc. |
| Dashboard gerencial | Cards + gráficos |
| Pareto de fallas | Por causa/síntoma |
| Gantt | Programado vs realizado |
| Backlog | Evolución temporal |
| Costos | Por equipo/sector/período |

**Criterio de aceptación:**
- Dashboard carga en < 2s (desde analytics, no transaccional)
- KPIs coinciden con fórmulas del manual SGMWin
- Gráficos interactivos en desktop

### Sprint 17-18: Offline + polish (3 semanas)

| Tarea | Detalle |
|-------|---------|
| SQLite local | sqflite en Flutter |
| Cola de sync | Push/pull con resolución de conflictos |
| Préstamo de herramientas | Retiro/devolución |
| Editor de derechos | UI Total/Parcial (desktop) |
| Pantalla admin sucursal | Dashboard con Configuración |
| Performance | Optimización queries, índices |
| Testing E2E | Flujos críticos |

**Criterio de aceptación:**
- Técnico cierra OT sin señal → sincroniza al recuperar conexión
- No hay pérdida de datos en sync
- Editor de derechos funcional para administrador

---

## Hitos

| Hito | Fase | Fecha objetivo |
|------|------|----------------|
| Documentación completa | 0 | Semana 2 |
| Login + permisos funcionando | 1 | Semana 3 |
| Primera OT emitida y cerrada | 1 | Semana 8 |
| Demo MVP a Sika | 1 | Semana 10 |
| Flujo pañol completo | 2 | Semana 13 |
| Emisión automática | 2 | Semana 15 |
| OC + compras | 2 | Semana 18 |
| Dashboard KPIs | 3 | Semana 21 |
| Offline funcional | 3 | Semana 24 |
| Release producción | 3 | Semana 26 |

---

## Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Complejidad del árbol de derechos | Alto | Seed fijo, validar con admin Sika en Fase 1 |
| Offline sync conflictos | Alto | Server-wins, pruebas en campo reales |
| Performance KPIs | Medio | Esquema analytics separado desde Fase 1 |
| Campos dinámicos (TipoEquipo) | Medio | JSONB + validación schema |
| Adopción técnicos | Alto | UX mobile simple, capacitación, piloto en 1 sector |
| Conectividad en parque industrial | Alto | Offline en Fase 3, pero diseñar para baja conectividad desde Fase 1 |

---

## Equipo sugerido

| Rol | Cantidad | Fases |
|-----|----------|-------|
| Backend (NestJS) | 1 | 0-3 |
| Flutter (mobile + web) | 1-2 | 1-3 |
| DevOps / Infra | 0.5 | 0-3 |
| QA | 0.5 | 1-3 |
| Product Owner (Sika) | 0.25 | 0-3 |

---

## Próximo paso inmediato

1. **Validar** esta documentación con el equipo
2. **Setup** del monorepo (NestJS + Flutter + PostgreSQL)
3. **Sprint 1** — M1 Seguridad: auth + permisos + RLS
