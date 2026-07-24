# Paridad SGMWin / SGwing — estado y camino al 100%

**Producto:** GestionMantenimiento (Flutter Web + Android + NestJS API)  
**Fecha:** 2026-07-21  
**Meta:** paridad funcional **100%** con SGMWin/SGwing **y** mejoras modernas (móvil, push, demo 24/7, UX).

**Referencias:**
- Checklist 32 pantallas Sika → [`faltantes/sgwing-paridad.md`](faltantes/sgwing-paridad.md)
- Matriz manual SGMWin → [`referencias/MATRIZ-PARIDAD.md`](referencias/MATRIZ-PARIDAD.md)
- Inventario por rol → [`inventario-app.md`](inventario-app.md)
- Estado técnico → [`00-estado-proyecto.md`](00-estado-proyecto.md)

**Leyenda:** ✅ Listo · 🟡 Parcial · ❌ Falta · 🚀 Mejora (mejor que el legado)

---

## 1. Resumen ejecutivo

| Área | Estimación hoy | Para 100% |
|------|----------------|-----------|
| **SGwing (32 pantallas)** | ~93–95% | Versiones UI, Gantt drag/programación, pulido solicitudes/listados |
| **SGMWin (manual completo)** | ~55–65% | Compras, indicadores, anexos Report Pro, catálogos auxiliares |
| **Mejoras vs legado** | Alto | Offline, dashboards, UX móvil, PDF/API modernos |

**Lectura corta:**  
Con lo operativo de planta (seguridad, planta, OT, pañol, push, móvil) **ya se puede usar en demo/planta**.  
El **100% SGMWin** exige sobre todo **M5 Compras**, **M6 Indicadores avanzados** y **anexos/reportes** del manual viejo.  
El **100% SGwing (lo que Sika mostró en capturas)** está **casi cerrado**; faltan detalles finos.

---

## 2. Qué tenemos hoy (y qué hace)

### 2.1 Plataforma

| Pieza | Qué hace |
|-------|----------|
| **API NestJS** `/v1` | Auth JWT, derechos, CRUD, OT, planta, pañol, storage, FCM |
| **Flutter Web** | Oficina / supervisor / admin en Chrome |
| **Flutter Android** | Técnico / planta vía APK + URL pública Cloudflare |
| **Postgres + Docker demo** | Stack 24/7, backups, tunnel `api.sorjuanaliberte.store` |
| **Roles** | `admin`, `admin.virrey`, `supervisor`, `tecnico`, `panolero` |

### 2.2 Módulos listos (operativos)

| Módulo | Estado | Qué hace el usuario |
|--------|--------|---------------------|
| **M1 Seguridad** | ✅ ~92% | Login, usuarios, perfiles, derechos, sucursales, sesiones, **recuperar clave** |
| **M2 Planta** | ✅ ~90% | Árbol planta→sector→equipo, ficha, lecturas, historial, documentos, copiar/pegar/mover |
| **M3 Mantenimiento** | ✅ ~92% | Procedimientos, emitir/asignar/ejecutar/cerrar OT, necesarias, PDF, Motivos, **Gantt**, **OT derivada con vínculo**, emisión auto (cron + contador al cargar lectura) |
| **M4 Pañol** | ✅ ~95% | Stock, mínimos, solicitudes materiales OT, pedidos reposición, movimientos, alertas |
| **M7 Notificaciones** | ✅ ~95% | Push FCM al asignar OT / stock (Android) |

### 2.3 Features recientes (2026-07-21)

| Feature | Qué hace | Dónde probar |
|---------|----------|--------------|
| Recuperar clave | Código demo + nueva clave sin sesión | Login → “¿Olvidaste tu clave?” |
| KPIs home | Pendientes, ejecución, realizadas, % cumplimiento, conformidad | `/home` (admin/supervisor) |
| Gantt OT | Barras por fecha/estado del período | Más → Gantt OT / `/ot/gantt` |
| PDF binario | Descarga `.pdf` (fallback HTML) | Detalle OT → PDF |
| Emisión por contador | Al cargar lectura, emite OT si supera umbral | Ficha equipo → Lecturas |
| OT derivada vinculada | Guarda OT origen + lista hijas | Detalle OT → Derivada |
| Versiones procedimiento | Snapshot al editar (API) | `GET /procedimientos/:id/versiones` |

### 2.4 Paridad SGwing (32 pantallas) — foto actual

| Bloque | Pantallas | Estado |
|--------|-----------|--------|
| Procedimientos 01–07 | Buscar, avanzada, alta, materiales, export, asociar, versiones | ✅ salvo **UI versiones (07)** 🟡/❌ |
| Equipos 08–15 | Mapa, toolbar, historial, alta, print, proc asociados, docs | ✅ (~95%); falta **repuestos por equipo** |
| OT 16–32 | Buscar+mapa, colores, toolbars, filtros, derivada, no periódica, solicitudes, contadores, necesarias | ✅; Gantt ✅ (vista); solicitudes listado 🟡 |

---

## 3. Qué falta para paridad 100%

### 3.A — Cerrar SGwing al 100% (prioridad alta / corta)

| # | Ítem | Hoy | Trabajo |
|---|------|-----|---------|
| 1 | **UI historial de versiones** de procedimiento (sgwing-07) | API ✅, UI ❌ | Pantalla/timeline en `/procedimientos` + restaurar versión (opcional) |
| 2 | **Gantt programación** (no solo lectura) | Vista barras ✅ | Drag fechas, asignar técnico, conflictos (paridad real SGMWin) |
| 3 | **Repuestos por equipo** | ❌ | Tab en ficha equipo ligado a stock M4 |
| 4 | **Solicitudes** listado tipo SGwing-26 | 🟡 | Columnas/acciones 1:1 captura |
| 5 | **PDF OT** siempre binario fiable en Docker | 🟡 (fallback HTML) | Chromium en imagen API o motor PDF liviano |
| 6 | **Selector de sucursal al login** | ❌ | Admin global elige planta y se recuerda |
| 7 | **Extrapolación contador** (promedio / proyección SGMWin) | ❌ | Regla al evaluar necesarias por contador |

### 3.B — Capítulos SGMWin aún débiles (prioridad media–alta)

| Capítulo / tema | Estado | Qué falta |
|-----------------|--------|-----------|
| **M5 Compras** | ❌ 0% | Proveedores, OC, autorización por monto, vínculo stock |
| **M6 Indicadores** | 🟡 ~10% | TMEF, TMPR, IMP, ICO, Pareto, dashboard gerencial real (hoy solo chips OT) |
| **Análisis stock** | ❌ | Reportes consumo, rotación, valorización |
| **Mano de obra / herramientas / recursos** | ❌ | Catálogos y carga en OT |
| **Incluir procedimiento** (herencia) | ❌ | Plantilla que hereda de otro procedimiento |
| **Tipos de equipo** como catálogo editable rico | 🟡 | Tablas detalle/lectura 1:1 SGMWin |
| **Motivos / eventos / tareas** catálogo completo | 🟡 | Motivos OT ✅; resto parcial |
| **Planos gráficos / layout planta** | 🟡 | Mapa árbol OK; falta plano visual tipo CAD/layout |
| **Report Pro / anexos impresión avanzada** | ❌ | Plantillas multi-reporte del manual |
| **Baja formal de equipos** con trazabilidad | 🟡 | Fuera de servicio ✅; baja documental parcial |

### 3.C — Mejoras “mejor que SGMWin” (para producto premium)

| Mejora | Por qué | Estado |
|--------|---------|--------|
| **Offline técnico + sync** | Planta sin señal | ❌ |
| **Deep links / push ricos** | Ya hay base FCM | 🟡 |
| **Auditoría completa** | Quién cambió qué | 🟡 parcial |
| **Multi-idioma / accesibilidad guantes** | Planta real | ❌ |
| **CI/CD + ambientes** | Dev / demo / prod | 🟡 demo OK |
| **Storage prod R2/S3** | Fotos/firmas escalables | 🟡 código listo, deploy falta |
| **PWA instalable / Play Store firmada** | Distribución | ❌ |

---

## 4. Roadmap sugerido hacia 100% + mejorado

### Fase A — Cerrar SGwing (2–4 semanas)
1. UI versiones procedimiento (+ opcional restaurar)  
2. Repuestos por equipo  
3. Pulido solicitudes + PDF Docker estable  
4. Selector sucursal al login  
5. Gantt editable liviano (fechas / técnico)

**Salida:** checklist `sgwing-01`…`32` en ✅.

### Fase B — Paridad SGMWin operativa (1–2 meses)
1. **M5 Compras** (proveedores + OC mínimas)  
2. Catálogos auxiliares (mano de obra, herramientas, marcas, rubros…)  
3. Incluir/heredar procedimiento  
4. Reportes impresión avanzados (subset Report Pro)

**Salida:** capítulos 3–4–6–8 del manual en ✅/🟡 alto.

### Fase C — Análisis y gerencia (1–2 meses)
1. **M6** TMEF / ICO / Pareto / dashboards  
2. Análisis stock  
3. Alertas gerenciales + home ejecutivo

**Salida:** capítulos 5 y 7 del manual.

### Fase D — Mejoras modernas (en paralelo o después)
1. Offline técnico  
2. Play Store / firmado  
3. Hardening prod (RLS estricto, CI, backups restore drill)

---

## 5. Tabla “¿se puede usar ya?”

| Caso de uso | ¿Hoy? |
|-------------|-------|
| Técnico ejecuta OT en celular (Mis OT, firma, fotos) | ✅ |
| Supervisor emite OT periódicas / no periódicas | ✅ |
| Planta: equipos, docs, lecturas, historial | ✅ |
| Pañol: stock y materiales de OT | ✅ |
| Push al asignar | ✅ |
| Demo PC + dominio Cloudflare | ✅ |
| Compras / OC | ❌ |
| KPIs industriales SGMWin (TMEF…) | ❌ (solo resumen OT) |
| Offline total | ❌ |
| Paridad visual 100% de las 32 capturas SGwing | 🟡 ~95% |

---

## 6. Criterio de “100% alcanzado”

Se considera **paridad 100% SGwing** cuando:
- Las 32 filas de [`sgwing-paridad.md`](faltantes/sgwing-paridad.md) estén ✅  
- Flujo demo Sika (emitir → asignar → ejecutar → pañol → cerrar) sin workarounds  

Se considera **paridad 100% SGMWin + mejorado** cuando:
- Capítulos 2–8 de [`MATRIZ-PARIDAD.md`](referencias/MATRIZ-PARIDAD.md) en ✅ (anexos 9–12 al menos 🟡 usable)  
- M5 + M6 cerrados  
- Al menos: móvil técnico offline-ready **o** plan explícito diferido firmado por Sika  
- Mejoras 🚀 documentadas como “superan al legado” (push, web+móvil unificado, recuperar clave, Gantt web, etc.)

---

## 7. Mantenimiento de este documento

1. Al cerrar un ítem de Fase A–D, actualizar tablas de §3 y % de §1.  
2. Sincronizar ticks en `sgwing-paridad.md` y `MATRIZ-PARIDAD.md`.  
3. Actualizar fecha del encabezado.

**Próximo foco recomendado:** Fase A ítem 1 (UI versiones procedimiento) + ítem 3 (repuestos por equipo).
