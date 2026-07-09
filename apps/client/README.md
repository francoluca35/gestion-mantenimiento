# Client — Flutter (Android + Web)

Un solo código Dart para **todos los roles** (técnico, supervisor, admin, gerencia, pañolero). La UI se adapta al ancho de pantalla y a los permisos del usuario.

Ver [`docs/00-estado-proyecto.md`](../../docs/00-estado-proyecto.md).

## Arranque

```bash
cd apps/client
flutter pub get

# Web
flutter run -d chrome

# Android emulador (API en el host)
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1
```

## Estructura

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/
│   ├── theme/
│   ├── network/
│   └── layout/          # AdaptiveScaffold (mobile vs desktop)
├── features/
│   ├── auth/
│   └── home/
└── shared/widgets/
```

Layout adaptativo:

- **Móvil (<600px):** bottom nav + flujo lineal por rol
- **Desktop (≥900px):** sidebar + panel principal + detalle lateral

Ver [07-pantallas.md](../../docs/07-pantallas.md) y [08-ui-ux.md](../../docs/08-ui-ux.md).
