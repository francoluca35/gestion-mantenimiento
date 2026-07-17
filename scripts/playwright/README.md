# Playwright UI smoke — Flutter web

Requiere API (`:3000`) y Flutter web (`:8080`) corriendo.

```powershell
# Terminal 1 — API
cd apps/api
npm run start:dev

# Terminal 2 — Flutter web
cd apps/client
flutter run -d chrome --web-port=8080

# Terminal 3 — bot
cd scripts/playwright
npm install
npx playwright install chromium
npm test
```

Headed (ver el browser):

```powershell
npm run test:headed
```

Reporte HTML:

```powershell
npm run report
```

Screenshots en `test-results/screenshots/`.

Notas:
- Flutter CanvasKit no expone inputs HTML; el login real se hace vía API + inyección de `SharedPreferences` (`flutter.access_token` / `flutter.refresh_token`).
- El test de login por teclado es best-effort y no corta el suite si falla el foco del canvas.
