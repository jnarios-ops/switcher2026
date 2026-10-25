# Switcher GPS (Flutter)

App de clientes: envuelve el panel de [switcher.cl/clientes](https://switcher.cl/clientes) (login + mapa, vehículos, alertas, geocercas, cuenta y soporte).

Nombre en el teléfono: **Switcher GPS**. Paquete: `cl.switcher.gps`.

## Build APK

```powershell
cd switcher_gps
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release
Copy-Item build\app\outputs\flutter-apk\app-release.apk dist\Switcher-GPS-1.0.0.apk
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

## Auto-update forzado

Al abrir consulta `app_releases` (`app_id = gps`). Si hay un `version_code` mayor, descarga el APK y abre el instalador. No hay opción de continuar sin actualizar.

1. Ejecutar SQL: [`../site/database/supabase_app_releases_app_id.sql`](../site/database/supabase_app_releases_app_id.sql) (después del SQL original de releases).
2. Subir versión en `pubspec.yaml` (`1.0.0+1` → name + code).
3. Build y publicar:

```powershell
$env:SUPABASE_SERVICE_ROLE_KEY = 'tu_service_role'
.\tools\publish_apk.ps1 -Notes "Descripción del cambio"
```

Los clientes deben permitir **Instalar apps desconocidas** para Switcher GPS la primera vez.
