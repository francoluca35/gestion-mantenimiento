# Sprint 4 — Push FCM + Mis OT

## Qué se hizo

### API
- `PushService` centraliza FCM (firebase-admin v14 modular: `cert` + `getMessaging`).
- Emitir / asignar OT usan `PushService`.
- Emisión en lote (`/ot/necesarias/emitir`): **una notificación resumen por técnico** (no N pushes).
- Prune de tokens inválidos.
- Log al arrancar: `FCM listo` o `FCM deshabilitado`.

### Flutter Android
- Handlers foreground / background / tap → `/mis-ot?numero=N` (deep-link a la OT).
- SnackBar en foreground con acción “Ver” (misma ruta).
- Registro de token + `onTokenRefresh`; logout borra token en API.
- `POST_NOTIFICATIONS` + canal `ot_asignadas` + `usesCleartextTraffic` (HTTP local).
- `minSdk 23` (requerido por `firebase_messaging`).

### Mis OT
- Rango de fechas ~1 año atrás / 60 días adelante.
- Pull-to-refresh + botón actualizar en top bar.
- Empty state orientado al técnico.
- Query `?numero=` selecciona la OT al cargar.

### URL API en dispositivo
- Override en SharedPreferences desde **Perfil → Servidor API** (solo Android/desktop).
- Sin rebuild al cambiar IP / usar `127.0.0.1` con adb reverse.
- Vacío = valor de `--dart-define=API_BASE_URL` (default localhost).

## Activar push en el entorno

1. Firebase Console → Project settings → Service accounts → Generate new private key.
2. En `apps/api/.env`:

```
FIREBASE_PROJECT_ID=mantenimiento-app-75a63
FIREBASE_CLIENT_EMAIL=...@....iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

3. Reiniciar API. Debe loguear `FCM listo`.
4. App Android: login `tecnico` → aceptar notificaciones.
5. Supervisor asigna OT / emite con “recibe” → push en el dispositivo.

Sin credenciales, la app sigue funcionando y la API loguea `[push:disabled]`.

## Conectividad celular ↔ API

La APK **no** usa datos móviles para llegar a una IP LAN. Opciones:

| Método | Pasos |
|--------|--------|
| Misma Wi‑Fi | Celular y PC en la misma red (no Wi‑Fi invitado). En Perfil: `http://<IP-PC>:3000/v1`. Firewall: puerto TCP 3000 inbound. |
| Hotspot PC | Activar zona Wi‑Fi móvil en Windows; conectar el celular. IP típica PC: `192.168.137.1`. |
| USB + adb reverse | `powershell -ExecutionPolicy Bypass -File scripts/android-adb-reverse.ps1` → en Perfil: `http://127.0.0.1:3000/v1` |

Probar antes en el navegador del celular: `http://…:3000/v1/health` → `{"status":"ok"…}`.

## Pendiente de validación

- Push end-to-end en dispositivo real (token registrado + log `[push] … ok 1`).
- Rotar service account si la private key se filtró en chat local.
