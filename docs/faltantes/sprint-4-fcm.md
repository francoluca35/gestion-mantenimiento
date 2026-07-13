# Sprint 4 — Push FCM + Mis OT

## Qué se hizo

### API
- `PushService` centraliza FCM (`sendEachForMulticast`, prune de tokens inválidos).
- Emitir / asignar OT usan `PushService`.
- Emisión en lote (`/ot/necesarias/emitir`): **una notificación resumen por técnico** (no N pushes).
- Log al arrancar: `FCM listo` o `FCM deshabilitado`.

### Flutter Android
- Handlers foreground / background / tap → `/mis-ot`.
- SnackBar en foreground con acción “Ver”.
- Registro de token + `onTokenRefresh`; logout borra token en API.
- `POST_NOTIFICATIONS` + canal `ot_asignadas` en `AndroidManifest`.

### Mis OT
- Rango de fechas ~1 año atrás / 60 días adelante.
- Pull-to-refresh + botón actualizar en top bar.
- Empty state orientado al técnico.

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
