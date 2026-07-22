# Manual de uso — Gestión de Mantenimiento Sika

**Versión:** 2026-07-20  
**App:** Web (`http://localhost:8080`) y Android  
**API demo:** `https://api.sorjuanaliberte.store/v1` (o `http://<IP-PC>:3000/v1` en LAN)

Guía práctica para operar el sistema día a día. Para el inventario técnico y mejoras, ver [`inventario-app.md`](inventario-app.md).

---

## 1. Acceso

### 1.1 Usuarios de demostración

| Usuario | Clave | Rol |
|---------|-------|-----|
| `admin` | `Sika123!` | Administrador (todo) |
| `admin.virrey` | `Sika123!` | Admin de planta Virrey |
| `supervisor` | `Sika123!` | Supervisor de mantenimiento |
| `tecnico` | `Sika123!` | Técnico de planta |
| `panolero` | `Sika123!` | Pañol / stock |

### 1.2 Conectar el celular (Android)

1. Abrí la app e iniciá sesión, o andá a **Perfil**.
2. **Servidor API** → pegá:
   - Remoto / 4G: `https://api.sorjuanaliberte.store/v1`
   - Misma Wi‑Fi que la PC servidor: `http://192.168.x.x:3000/v1`
3. Guardá → la app vuelve al login.
4. Probá con `tecnico` / `Sika123!`.

Si no entra: desde el navegador del celular abrí `https://api.sorjuanaliberte.store/v1/health` (debe decir `"status":"ok"`). La PC servidor tiene que estar encendida con Docker + tunnel.

### 1.3 Iniciar sesión

1. Abrí la app (navegador o Android).
2. Ingresá usuario y clave.
3. Según el rol vas a:
   - **Técnico** → Mis OT  
   - **Pañolero** → Pañol  
   - **Resto** → Inicio  

### 1.4 Cerrar sesión y perfil

1. Menú **Perfil**.
2. Podés: cambiar clave, ver sesiones, revocar todas las sesiones, **cerrar sesión**.
3. En Android/desktop: **Servidor API** — URL del backend sin reinstalar la app.
---

## 2. Técnico — Mis órdenes de trabajo

### 2.1 Ver mis OT

1. Login como `tecnico`.
2. En **Mis OT** ves las órdenes asignadas (rango amplio de fechas).
3. Tirar hacia abajo o tocar actualizar para refrescar.
4. Colores orientativos: rojo pendiente · amarillo en ejecución · verde realizada.

### 2.2 Ejecutar una OT

1. Tocá una OT de la lista.
2. Revisá procedimiento, equipo y comentarios.
3. Si está pendiente, pasala a **en ejecución** (según botones disponibles).
4. Completá el **checklist** de ítems.
5. Si necesitás materiales → **Solicitar materiales** (ver §2.3).
6. Registrá **firma** / cierre.
7. La OT queda **realizada**. Si había materiales aprobados, el stock se descuenta automáticamente.

### 2.3 Pedir materiales al pañol

1. Desde el detalle de la OT → solicitar materiales.
2. Elegí pañol, material y cantidad.
3. La OT puede pasar a **pendiente pañol**.
4. Cuando el pañolero **aprueba**, el material queda reservado y podés seguir.
5. Si **rechaza**, recibís aviso (push en Android) y la OT vuelve a pendiente.

### 2.4 Notificaciones (Android)

- Al asignarte una OT llega un push.
- Tocá la notificación → se abre **Mis OT** en esa orden.
- Si la app está abierta, también puede aparecer un aviso con acción **Ver**.

---

## 3. Pañolero — Stock y pedidos

### 3.1 Pantallas

| Menú | Para qué |
|------|----------|
| **Inicio** | Accesos rápidos del pañol |
| **Stock** | Listado de materiales, cantidades, mínimos, alta/edición |
| **Pedidos** | Solicitudes de OT + pedidos de reposición |
| **Seguimiento** | Movimientos (entradas, salidas, reservas) |
| **Dashboard** | Resumen (más útil en web) |

### 3.2 Consultar y ajustar stock

1. Login `panolero` → **Stock**.
2. Revisá columnas: código, nombre, uso, cantidad, estado (bajo mínimo si aplica).
3. **Añadir** material nuevo o **Editar** mínimos / cantidad.
4. **Utilizar** registra una salida manual.
5. Los ítems bajo mínimo se destacan; conviene generar un pedido (§3.4).

### 3.3 Aprobar o rechazar materiales de una OT

1. Andá a **Pedidos**.
2. En solicitudes pendientes de OT: revisá técnico, OT, material y cantidad.
3. **Aprobar** → reserva stock (no lo descuenta todavía).
4. **Rechazar** → pedí motivo; el técnico es notificado.
5. El descuento físico ocurre cuando el técnico **cierra** la OT.

### 3.4 Pedir stock (reposición)

1. En **Pedidos** → **Analizar** (detecta bajos de mínimo).
2. **Pedir stock** crea un pedido (número tipo PD-####).
3. Cuando llega la mercadería → **Completar** el pedido → entrada de stock.

### 3.5 Seguimiento

1. **Seguimiento** muestra el historial de movimientos del pañol.
2. Filtrá por pañol si hay más de uno.

---

## 4. Supervisor / Admin — Operación diaria

### 4.1 Inicio

- Resumen de OT (pendientes, en ejecución, realizadas, etc.).
- Accesos según derechos del perfil.

### 4.2 Planta y equipos

1. Menú **Equipos** / **Planta**.
2. A la izquierda: **Explorador** (buscar sector o máquina).
3. Centro: mapa / árbol; seleccioná un nodo.
4. Acciones:
   - **Web:** barra de botones (Buscar, Imprimir, Exportar, Agregar, Editar, Mover, etc.).
   - **Móvil:** **Agregar** + **Acciones** (abre la lista completa).
5. En la ficha del equipo: General, Lecturas, Historial, Procedimientos, Documentos.

**Agregar sector o máquina**

1. Seleccioná el nodo padre (planta o sector).
2. **Agregar** → elegí sector o máquina.
3. Completá código, nombre y datos del tipo de equipo.

**Documentos**

1. Ficha del equipo → pestaña Documentos.
2. Subí planos / PDFs / imágenes (storage MinIO).

### 4.3 Procedimientos

1. Menú **Procedimientos**.
2. Buscá por texto / filtros (tipo, sector, periodicidad).
3. Alta o edición del procedimiento (checklist, periodicidad, etc.).
4. **Asociar** a planta, sector o equipo.
5. Al asociar equipos nuevos puede emitirse la primera OT (según reglas del sistema).

### 4.4 Buscar y gestionar OT

1. Menú **Buscar OT**.
2. Usá filtros (fechas, estado, sector, técnico, etc.).
3. Seleccioná una OT: detalle + mapa lateral (en pantallas grandes).
4. Acciones frecuentes:
   - **Asignar** técnico (dispara push en Android)
   - Cambiar estado
   - Completar ejecución / checklist (si aplica)
   - **Derivar** (genera OT correctiva relacionada)
   - **Anular** / **Reabrir**
   - **PDF** / vista previa imprimible

### 4.5 Emitir OT no periódica

1. Menú **OT no periódica**.
2. Elegí equipo (mapa o búsqueda), tipo, fechas, prioridad, técnico (recibe).
3. Confirmá emisión.
4. El técnico ve la OT en Mis OT (y push si está en Android).

### 4.6 Emitir OT necesarias (periódicas)

1. Menú **OT necesarias**.
2. Filtrá por planta/sector.
3. Revisá la lista de próximas / vencidas.
4. Vista previa → asigná técnico por fila si hace falta → **Emitir**.
5. Se envía un push resumen por técnico (no una notificación por cada OT).

### 4.7 Solicitudes de trabajo

1. Menú **Solicitudes**.
2. Alta de solicitud (sector/equipo, descripción).
3. Conformar o rechazar.
4. Desde una solicitud conformada se puede **emitir OT**.

### 4.8 Contadores

1. Menú **Contadores**.
2. Consultá lecturas por equipo.
3. Reinicio (si tenés permiso; puede pedir confirmación de admin según flujo).

---

## 5. Administrador — Configuración

### 5.1 Usuarios

1. **Config** → **Usuarios**.
2. Alta: nombre de usuario, clave, perfil, sucursal, sector (opcional).
3. Edición / baja lógica (activo).

### 5.2 Perfiles y derechos

1. **Config** → **Perfiles**.
2. Creá un perfil (ej. “Supervisor Planta 2”).
3. **Derechos**: marcá Total o Parcial por rama (programación, archivos, stock, configuración…).
4. Los menús de la app aparecen según esos derechos.

### 5.3 Sucursales / plantas

1. **Config** → **Plantas** / sucursales.
2. Alta de sucursal (código, nombre).
3. Los usuarios quedan acotados por sucursal (RLS).

### 5.4 Árbol de derechos

- Pantalla de consulta del catálogo completo de permisos (`/derechos`).

---

## 6. Flujo completo recomendado (demo)

```text
Supervisor emite/asigna OT
        ↓
Técnico recibe push → abre Mis OT
        ↓
Técnico pide materiales (si falta)
        ↓
Pañolero aprueba (reserva)
        ↓
Técnico ejecuta checklist + firma → cierra OT
        ↓
Stock se descuenta; si quedó bajo mínimo → alerta a pañol
        ↓
Pañolero genera pedido de reposición → completa entrada
```

---

## 7. Android en planta (conectividad)

1. La API debe estar en un host alcanzable (LAN o Tunnel), no solo en “localhost” de otra PC.
2. En **Perfil → Servidor API** poné por ejemplo:  
   `http://192.168.0.20:3000/v1`
3. Emulador en la misma máquina que la API: `http://10.0.2.2:3000/v1`
4. Script útil en desarrollo: `scripts/android-adb-reverse.ps1` (redirige el puerto del emulador).
5. Activá notificaciones del sistema para la app.

---

## 8. Impresión y exportación

| Qué | Cómo |
|-----|------|
| OT | Desde detalle OT → PDF / vista HTML → imprimir desde el navegador |
| Planta | Toolbar → Vista previa / Imprimir o Exportar CSV |
| Listados OT | Opciones de impresión / CSV según toolbar |

---

## 9. Estados de una OT (referencia rápida)

| Estado | Significado |
|--------|-------------|
| Necesaria de emitir | Venció programación; aún no emitida |
| Pendiente | Emitida; espera ejecución / técnico |
| Pendiente pañol | Esperando materiales |
| En ejecución | Técnico trabajando |
| Realizada | Cerrada (con consumo de stock si había reserva) |
| Anulada | Cancelada (se liberan reservas) |

---

## 10. Problemas frecuentes

| Síntoma | Qué revisar |
|---------|-------------|
| No puedo entrar | Usuario/clave; API arriba (`/v1/health`) |
| Android no conecta | URL en Perfil; firewall; misma red Wi‑Fi |
| No llegan push | App Android (no web); permisos notificación; `FIREBASE_*` en API; token registrado tras login |
| No veo un menú | Derechos del perfil; pedir a admin que habilite |
| Stock no baja al cerrar | ¿La solicitud estaba **aprobada**? Solo las aprobadas consumen |
| Pañol no ve solicitud | OT en pendiente_panol; refresh en Pedidos |

---

## 11. Glosario breve

| Término | Significado |
|---------|-------------|
| OT | Orden de trabajo |
| Pañol | Depósito de materiales / repuestos |
| Procedimiento | Plantilla de mantenimiento (checklist + frecuencia) |
| Alcance | Asociación proc. ↔ planta / sector / equipo |
| Reserva | Stock apartado para una OT (aún no descontado) |
| RLS | Seguridad de datos por sucursal en la base |

---

## 12. Dónde pedir ayuda / docs técnicas

- Inventario y mejoras: [`inventario-app.md`](inventario-app.md)
- Estado del proyecto: [`00-estado-proyecto.md`](00-estado-proyecto.md)
- Paridad SGwing: [`faltantes/sgwing-paridad.md`](faltantes/sgwing-paridad.md)
- Infra / Docker: [`10-infraestructura.md`](10-infraestructura.md)
