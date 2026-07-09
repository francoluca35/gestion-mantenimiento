# Manual SGMWin — Extracción capítulo por capítulo

Referencia funcional 1:1 del sistema legado **SGMWin** (L&M Ingeniería). Base para paridad, pruebas de aceptación y el reemplazo moderno.

## Fuente original

| Archivo | Descripción |
|---------|-------------|
| [`MANUAL SGMWIN3.docx`](../MANUAL%20SGMWIN3.docx) | Manual oficial (Word) |
| [`_manual-raw.txt`](../_manual-raw.txt) | Texto plano extraído (~4953 líneas) |
| [`tools/split-sgmwin-manual.ps1`](../../../tools/split-sgmwin-manual.ps1) | Script de división y limpieza |

Regenerar capítulos:

```powershell
powershell -ExecutionPolicy Bypass -File tools/split-sgmwin-manual.ps1
```

## Capítulos

| # | Archivo | Tema | Líneas aprox. |
|---|---------|------|---------------|
| 0 | [00-indice.md](./00-indice.md) | Índice completo del manual | 632 |
| 1 | [01-introduccion.md](./01-introduccion.md) | Conceptos, glosario, KPIs | 164 |
| 2 | [02-comenzar-a-trabajar.md](./02-comenzar-a-trabajar.md) | Login, sucursales, primeros pasos | 110 |
| 3 | [03-archivos-maestros.md](./03-archivos-maestros.md) | Procedimientos, equipos, catálogos | 1193 |
| 4 | [04-administracion-trabajos.md](./04-administracion-trabajos.md) | OT, solicitudes, contadores, presupuesto | 798 |
| 5 | [05-analisis-trabajos.md](./05-analisis-trabajos.md) | Costos, fallas, gráficas OT | 388 |
| 6 | [06-administracion-stock.md](./06-administracion-stock.md) | Pañol, comprobantes, órdenes de compra | 410 |
| 7 | [07-analisis-stock.md](./07-analisis-stock.md) | Reportes y análisis de stock | 192 |
| 8 | [08-configuracion.md](./08-configuracion.md) | Usuarios, perfiles, derechos, sistema | 335 |
| 9 | [09-anexo-1-report-pro.md](./09-anexo-1-report-pro.md) | REPORT PRO (reportes externos) | 36 |
| 10 | [10-anexo-2-planos.md](./10-anexo-2-planos.md) | Planos de planta | 5 |
| 11 | [11-anexo-3-graficas.md](./11-anexo-3-graficas.md) | Gráficas Gantt / programación | 46 |
| 12 | [12-anexo-4-edicion-texto.md](./12-anexo-4-edicion-texto.md) | Tips Windows (Ctrl+C/V) | 13 |

## Cómo usar esta extracción

1. **Paridad funcional** — Cruzar cada sección con [`MATRIZ-PARIDAD.md`](../MATRIZ-PARIDAD.md).
2. **Criterios de aceptación** — Cada `##` del manual puede convertirse en un caso de prueba.
3. **Priorización** — Cap. 3 + 4 = núcleo operativo (M2 + M3). Cap. 6 + 7 = M4/M5. Cap. 5 + 8 = M6/M1.
4. **Mejoras modernas** — Ver columna *Modernización* en la matriz (push, sin papel, web+móvil, API).

## Notas sobre la extracción

- Las referencias `> **Figura X**` apuntan a capturas del manual impreso; no se incluyen imágenes.
- Algunos títulos quedaron duplicados o partidos por artefactos del DOCX; el contenido operativo está completo.
- Los callouts originales (NOTA, AVISO, SUGERENCIA) se integraron al párrafo o se omitieron si eran repetidos.

## Documentos relacionados

- [`../MATRIZ-PARIDAD.md`](../MATRIZ-PARIDAD.md) — Estado implementación vs manual
- [`../../images/Sistema_SGwing.md`](../../images/Sistema_SGwing.md) — Capturas visuales Sika (32 pantallas)
- [`../../faltantes/sgwing-paridad.md`](../../faltantes/sgwing-paridad.md) — Checklist imagen a imagen
- [`../../01-modulos.md`](../../01-modulos.md) — Arquitectura del sistema nuevo
- [`../../09-roadmap.md`](../../09-roadmap.md) — Plan por fases
- [`../../faltantes/`](../../faltantes/) — Gaps por módulo
