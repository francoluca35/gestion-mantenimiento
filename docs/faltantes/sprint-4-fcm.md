# Sprint 4 — Push FCM + Mis OT

**Estado:** ✅ **CERRADO** (2026-07-17)  
**Rama:** `Sprint-4/1-comunicacion`

---

## Criterios de cierre

| Criterio | Estado |
|----------|--------|
| Push FCM al asignar / emitir OT | ✅ `PushService` |
| Emisión en lote: 1 push resumen por técnico | ✅ |
| Prune tokens inválidos | ✅ |
| Android: registro token + refresh + logout | ✅ |
| Foreground / background / tap → Mis OT | ✅ deep-link `?numero=` |
| Mis OT usable en móvil/tablet | ✅ layout cómodo + refresh |
| URL API runtime (Perfil) + adb reverse | ✅ |
| Credenciales `FIREBASE_*` en API local | ✅ |
| Shell móvil: menú «Más» con destinos overflow | ✅ |

---

## Qué se entregó

### API
- `PushService` centraliza FCM (firebase-admin v14 modular: `cert` + `getMessaging`).
- Emitir / asignar OT usan `PushService`.
- Emisión en lote (`/ot/necesarias/emitir`): **una notificación resumen por técnico**.
- Prune de tokens inválidos.
- Log al arrancar: `FCM listo` o `FCM deshabilitado`.

### Flutter Android
- Handlers foreground / background / tap → `/mis-ot?numero=N`.
- SnackBar en foreground con acción “Ver”.
- Registro de token + `onTokenRefresh`; logout borra token en API.
- `POST_NOTIFICATIONS` + canal `ot_asignadas` + `usesCleartextTraffic`.
- `minSdk 23` (requerido por `firebase_messaging`).

### Mis OT + shell móvil
- Rango de fechas amplio; pull-to-refresh; empty state técnico.
- Query `?numero=` selecciona la OT al cargar.
- Layout móvil/tablet con más aire, botones full-width, sin overflow.
- Bottom nav: ítem **Más** (↑) abre menú con todos los destinos.

### URL API en dispositivo
- Override en SharedPreferences desde **Perfil → Servidor API**.
- Script USB: `scripts/android-adb-reverse.ps1` → `http://127.0.0.1:3000/v1`.

---

## Activar push (ops)

1. Firebase Console → Service accounts → Generate new private key.
2. En `apps/api/.env`:

```
FIREBASE_PROJECT_ID=mantenimiento-app-75a63
FIREBASE_CLIENT_EMAIL=...@....iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

3. Reiniciar API → log `FCM listo`.
4. App Android: login `tecnico` → aceptar notificaciones.
5. Supervisor asigna OT → push en el dispositivo + log `[push] … ok`.

Sin credenciales la app sigue OK y la API loguea `[push:disabled]`.

## Smoke post-deploy (ops, no bloquea cierre)

| Paso | Cómo |
|------|------|
| Token registrado | Login técnico en Android → fila en `dispositivos_fcm` |
| Push al asignar | Supervisor asigna OT → bandeja Android + deep-link |
| Lote | Emitir necesarias a un técnico → **1** notificación resumen |
| Rotar key | Si la private key se filtró en chat, regenerar en Firebase Console |

## Conectividad celular ↔ API

| Método | Pasos |
|--------|--------|
| Misma Wi‑Fi | Perfil: `http://<IP-PC>:3000/v1` · firewall TCP 3000 |
| Hotspot PC | IP típica `192.168.137.1` |
| USB + adb reverse | `scripts/android-adb-reverse.ps1` → `http://127.0.0.1:3000/v1` |

Probar: `http://…:3000/v1/health` → `{"status":"ok"…}`.
