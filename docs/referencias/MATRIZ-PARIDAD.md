# Matriz de paridad — SGMWin → Sistema nuevo

Mapa capítulo a capítulo del manual legado contra módulos, rutas actuales y mejoras modernas.

**Leyenda:** ✅ Listo · 🟡 Parcial · ❌ Falta · 🚀 Mejora (no existía en SGMWin)

**Última revisión:** 2026-07-06

**Estado global:** [`docs/00-estado-proyecto.md`](../00-estado-proyecto.md)

**Referencias visuales Sika:** [`docs/images/Sistema_SGwing.md`](../images/Sistema_SGwing.md) · Checklist 32 pantallas: [`docs/faltantes/sgwing-paridad.md`](../faltantes/sgwing-paridad.md)

---

## Resumen ejecutivo

| Capítulo | Módulo(s) | Paridad global | Prioridad |
|----------|-----------|----------------|-----------|
| 1 Introducción | — (dominio) | N/A | Documentación |
| 2 Comenzar a trabajar | M1 | 🟡 60% | Alta |
| 3 Archivos maestros | M2, M3, M4 | 🟡 48% | **Crítica** |
| 4 Administración trabajos | M3, M7 | 🟡 55% | **Crítica** |
| 5 Análisis trabajos | M6 | ❌ 5% | Media |
| 6 Administración stock | M4, M5 | ❌ 0% | Alta (Fase 2) |
| 7 Análisis stock | M4, M6 | ❌ 0% | Media |
| 8 Configuración | M1 | 🟡 50% | Alta |
| 9–12 Anexos | M6, M2 | ❌ 0% | Baja |
| **SGwing (capturas Sika)** | M2, M3, M7 | 🟡 48% | Ver `sgwing-paridad.md` |

---

## Cap. 1 — Introducción

| Sección manual | Nuevo sistema | Estado | Notas / modernización |
|----------------|---------------|--------|------------------------|
| Glosario (OT, procedimiento, TMEF…) | `docs/02-entidades.md` | ✅ | Glosario en docs |
| KPIs (TMEF, TMPR, IMP, ICO…) | M6 Indicadores | ❌ | 🚀 Dashboard tiempo real, alertas automáticas |
| Tipos de mantenimiento | Enum en Prisma | ✅ | preventivo, correctivo, mejora, preventivo_no_periodico |

---

## Cap. 2 — Comenzar a trabajar

| Sección manual | Ruta / API | Estado | Notas / modernización |
|----------------|------------|--------|------------------------|
| Login usuario | `/login` | ✅ | JWT + refresh |
| Usuario administrador (todas sucursales) | Rol `admin` | ✅ | |
| Supervisor de sucursales | Rol `supervisor` | 🟡 | Falta UI gestión multi-sucursal |
| Usuario de sucursal | Filtro por `sucursalId` | ✅ | RLS pendiente prod |
| Selector de sucursal al ingresar | — | ❌ | 🚀 Recordar última planta (localStorage) |
| Barra de herramientas SGMWin | Sidebar colapsable | 🟡 | Orden SGMWin aplicado; faltan atajos |

---

## Cap. 3 — Archivos maestros

### 3.1 Procedimientos

| Función SGMWin | Ruta nueva | Estado | Notas |
|----------------|------------|--------|-------|
| Agregar procedimiento | `/procedimientos` | 🟡 | Formulario + observaciones + planilla lecturas |
| Sector responsable | Campo `sectorResponsableId` | ✅ | |
| Tipo procedimiento | Enum fijo | ✅ | No editable como catálogo SGMWin |
| Valores estimados (HH, operarios, duración…) | Campos Prisma | ✅ | |
| Periodicidad tiempo/evento | `periodicidadDias`, contador | 🟡 | UI tiempo OK; falta evento por contador |
| Criterio programación + tolerancia | Campos nuevos | ✅ | |
| Reserva materiales | Botón placeholder | ❌ | Depende M4 |
| Buscar simple / avanzada | Listado + filtros | 🟡 | Falta búsqueda avanzada (sgwing-02) |
| Modificar / borrar / listar | CRUD API | 🟡 | Falta export Excel (sgwing-05) |
| Incluir procedimiento | — | ❌ | Herencia entre procedimientos |
| Asociar a planta / sector / equipo | mapa + `asociar-alcance` / `asociar-equipo` | 🟡 | UI mapa OK; falta imprimir OT en diálogo (sgwing-06) |
| Histórico / versiones | — | ❌ | sgwing-07 |

### 3.2 Equipos

| Función SGMWin | Ruta nueva | Estado | Notas |
|----------------|------------|--------|-------|
| Árbol equipos / ubicaciones | `/planta` explorer | 🟡 | sgwing-08 OK; falta plano gráfico |
| CRUD equipo | API + UI | 🟡 | Campos dinámicos JSON parcial (sgwing-11) |
| Fuera de servicio | `/planta` toggle | ✅ | |
| Historial equipo | tab + `GET equipos/:id/historial` | 🟡 | sgwing-10 |
| Procedimientos asociados | tab + API alcances | 🟡 | Falta filtro por nodo planta/sector (sgwing-13/14) |
| Documentos adjuntos | — | ❌ | sgwing-15 |
| Repuestos por equipo | — | ❌ | M4 |
| Lecturas en ficha equipo | tab Lecturas en `/planta` | 🟡 | `/contadores` aparte (sgwing-29) |
| Baja de equipos | — | ❌ | |
| Copiar / pegar / listar equipo | — | ❌ | sgwing-09 |

### 3.3 Catálogos auxiliares (cap. 3)

| Catálogo SGMWin | Módulo | Estado |
|-----------------|--------|--------|
| Tipos de equipo (+ detalle/lectura tablas) | M2 | 🟡 |
| Mano de obra | M3/M4 | ❌ |
| Proveedores | M5 | ❌ |
| Materiales | M4 | ❌ |
| Recursos / Herramientas | M4 | ❌ |
| Responsables / Sectores | M2 | 🟡 |
| Depósitos, rubros, marcas, unidades… | M4/M5 | ❌ |
| Eventos, tareas, motivos OT pendiente | M3 | ❌ |
| Síntomas, acciones | M3 | ❌ |

---

## Cap. 4 — Administración de trabajos

### 4.1 Emisión OT

| Función SGMWin | Ruta nueva | Estado | Notas |
|----------------|------------|--------|-------|
| OT periódica — al asociar procedimiento | API emitir | 🟡 | Emitir 1ª OT en equipos nuevos |
| OT periódica — necesarias (vencidas) | `/ot/necesarias` | 🟡 | Lógica OK; falta mapa + vista previa (sgwing-30/31) |
| OT periódica — emisión rápida | `/ot/emitir-periodica` | 🟡 | Pantalla dedicada |
| OT periódica — gráfica Gantt | — | ❌ | sgwing-23 |
| OT no periódica — manual | `/ot/emitir-no-periodica` | 🟡 | Mapa equipo OK; falta sector, recibe, fechas inicio/fin (sgwing-25) |
| OT no periódica — desde equipo | — | 🟡 | Vía mapa, sin flujo dedicado |
| OT no periódica — desde solicitud | `/solicitudes` | ✅ | Conformidad + emitir OT con mapa |
| Imprimir OT / PDF | — | ❌ | sgwing-12, sgwing-31 |
| Programación masiva OT necesarias | `/ot/necesarias/emitir` | 🟡 | Falta técnico por fila + push |

### 4.2 Ciclo de vida OT

| Función SGMWin | Ruta nueva | Estado |
|----------------|------------|--------|
| Buscar OT | `/ot` | 🟡 | **Falta mapa lateral** (sgwing-16, sgwing-32) |
| OT pendiente → ejecución → realizada | `/ot` acciones | ✅ | |
| Colores por estado (verde/rojo/amarillo) | `/ot` | 🟡 | sgwing-17 |
| Motivos OT pendiente | — | ❌ | sgwing-20/22 |
| OT derivada | — | ❌ | sgwing-24 |
| Postergar / reemplazar procedimiento | — | ❌ |
| Anular OT | API | ✅ |
| Reabrir OT | — | ❌ |
| Materiales / MO / recursos en OT | — | ❌ |
| Lecturas en cierre OT | Checklist | 🟡 |
| Firma técnico | `/ot` | ✅ |
| Exportar Excel | — | ❌ |

### 4.3 Solicitudes de trabajo

| Función SGMWin | Ruta nueva | Estado |
|----------------|------------|--------|
| Agregar solicitud | `/solicitudes` | ✅ | |
| Buscar / modificar / listar | `/solicitudes` | 🟡 | Falta editar solicitud |
| Conformidad + calificación | `/solicitudes` | ✅ | sgwing-28 |
| Emitir OT desde solicitud | `/solicitudes` | ✅ | Con mapa de planta |
| Adjuntos / email urgente | — | ❌ | 🚀 Push FCM en lugar de email |

### 4.4 Contadores

| Función SGMWin | Ruta nueva | Estado |
|----------------|------------|--------|
| Buscar equipo + lecturas | `/contadores` + tab `/planta` | 🟡 | sgwing-29 |
| Agregar / modificar / borrar lectura | API parcial | 🟡 | |
| Reiniciar contador (clave admin) | — | ❌ | sgwing-29 |
| Graficar lecturas | — | ❌ | sgwing-29 |
| Extrapolación uso promedio (OT necesarias) | — | ❌ |

### 4.5 Programación y reportes operativos

| Función SGMWin | Estado | Modernización |
|----------------|--------|---------------|
| Presupuesto de trabajos | ❌ | 🚀 Vista financiera en dashboard |
| Programado vs realizado | ❌ | M6 |
| Backlog / trabajos atrasados | ❌ | 🚀 Alertas automáticas |
| Resumen situación OT | Home métricas | 🟡 |

---

## Cap. 5 — Análisis información trabajos

| Área SGMWin | Módulo | Estado | Modernización |
|-------------|--------|--------|---------------|
| Costos por equipo/sector | M6 | ❌ | Drill-down interactivo |
| Materiales utilizados | M6 | ❌ | Cruce con M4 |
| Mano de obra utilizada | M6 | ❌ | |
| Fallas / síntomas | M6 | ❌ | Pareto automático |
| Gráficas Pareto | M6 | ❌ | Anexo 3 |
| TMEF, TMPR, IMP, ICO, ICM | M6 | ❌ | 🚀 Tiempo real vs reporte batch |

---

## Cap. 6 — Administración del stock

| Área SGMWin | Módulo | Estado |
|-------------|--------|--------|
| Gestión pañol / depósitos | M4 | ❌ |
| Comprobantes (ingreso/egreso) | M4 | ❌ |
| Vale de materiales desde OT | M4 | ❌ |
| Órdenes de compra | M5 | ❌ |
| Reserva automática al emitir OT | M4 | ❌ |
| Inventario físico | M4 | ❌ |

**Modernización:** escaneo código barras móvil, stock en tiempo real, alertas mínimo.

---

## Cap. 7 — Análisis información stock

| Área SGMWin | Módulo | Estado |
|-------------|--------|--------|
| Listados valorizados | M6 | ❌ |
| Consumo por equipo/OT | M6 | ❌ |
| Rotación / ABC | M6 | ❌ |

---

## Cap. 8 — Configuración

| Área SGMWin | Ruta / módulo | Estado |
|-------------|---------------|--------|
| Usuarios | M1 API | 🟡 |
| Perfiles y derechos (árbol) | M1 seed | 🟡 |
| Sucursales | M1/M2 | 🟡 |
| Parámetros sistema | — | ❌ |
| Backup / restauración | — | ❌ | 🚀 Backups cloud automatizados |
| Licencias SGMWin | — | N/A | SaaS / self-hosted |

---

## Cap. 9–12 — Anexos

| Anexo | Estado | Alternativa moderna |
|-------|--------|---------------------|
| 9 REPORT PRO | ❌ | Export CSV/PDF nativo + API |
| 10 Planos planta | ❌ | 🚀 Plano interactivo SVG en `/planta` |
| 11 Gráficas Gantt | ❌ | 🚀 Timeline web (FullCalendar / custom) |
| 12 Edición texto Windows | N/A | No aplica (web/móvil) |

---

## Mapa menú SGMWin → rutas actuales

| # | SGMWin / SGwing | Ruta Flutter | Paridad |
|---|-----------------|--------------|---------|
| 1 | Procedimientos | `/procedimientos` | 🟡 |
| 2 | Equipos | `/planta` | 🟡 |
| 3 | Buscar OT | `/ot` | 🟡 |
| 4 | OT no periódica | `/ot/emitir-no-periodica` | 🟡 |
| 5 | Solicitudes | `/solicitudes` | ✅ |
| 6 | Contadores | `/contadores` | 🟡 |
| 7 | OT necesarias | `/ot/necesarias` | 🟡 |
| — | OT periódica (fuera menú) | `/ot/emitir-periodica` | 🟡 |

Detalle captura por captura: [`docs/faltantes/sgwing-paridad.md`](../faltantes/sgwing-paridad.md)

---

## Paridad SGwing — resumen 32 pantallas

| Bloque | Pantallas | Estado | Siguiente paso P0 |
|--------|-----------|--------|-------------------|
| Procedimientos | 01–07 | 🟡 55% | Diálogo asociar completo (06) |
| Equipos | 08–15 | 🟡 50% | Proc. por nodo planta/sector (13–14) |
| OT | 16–32 | 🟡 42% | Mapa en `/ot` y `/ot/necesarias` (16, 30–32) |

---

## Roadmap sugerido (post-Ola 1)

### Ola 1 — Paridad operativa núcleo ✅ (cerrada 2026-07-06)

1. ✅ Asociar procedimientos ↔ equipos / sector / planta (UI + API alcances)
2. ✅ OT necesarias con lógica periodicidad real
3. ✅ Solicitudes: conformidad + emitir OT con mapa
4. ✅ Planta: lecturas, historial, procedimientos, fuera de servicio
5. ✅ Procedimientos: observaciones + planilla lecturas

### Ola 2 — SGwing UX + sin papel (4–6 semanas) ← **actual**

Ver sprint A–E en [`docs/faltantes/sgwing-paridad.md`](../faltantes/sgwing-paridad.md).

**P0 inmediato:**

1. Mapa en Buscar OT + mapa en detalle OT (sgwing-16, 32)
2. Mapa en OT necesarias + emisión con técnico y vista previa (sgwing-30, 31)
3. Colores OT verde/rojo/amarillo (sgwing-17)
4. PDF OT + push al asignar técnico (sgwing-12, 25, 31)
5. Procedimientos asociados filtrados por nodo en `/planta` (sgwing-14)

### Ola 3 — Stock y compras (Fase 2 roadmap)

1. M4 Pañol completo (cap. 6) + reserva materiales (sgwing-04)
2. Documentos de equipo (sgwing-15)
3. M5 órdenes de compra

### Ola 4 — Inteligencia (Fase 3)

1. KPIs cap. 5 (M6)
2. Gantt / programación (sgwing-23, anexo 11)
3. Offline Android técnico
4. Cron emisión automática OT periódicas

---

## Cómo mantener esta matriz

1. Al implementar una función, actualizar la fila correspondiente.
2. Vincular PR/commits con ID de sección del manual (`cap4-ot-necesarias`).
3. Usar capítulos en `sgmwin-manual/` como spec para tests e2e.
4. Usar `sgwing-XX` como ID de pantalla en PRs y en `sgwing-paridad.md`.
5. Regenerar manual si cambia el DOCX fuente.
