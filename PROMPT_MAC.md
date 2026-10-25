# Prompt para el Mac (copiar y pegar)

Copia todo el bloque siguiente y pégalo en un asistente de IA, o úsalo como checklist tú mismo.

---

Tengo un **Mac sin nada instalado** para desarrollo. Necesito compilar la app Flutter **Switcher GPS** en iOS.

1. Clona el repo: **https://github.com/jnarios-ops/switcher2026** (rama **`master`**, commit **`5579798`**).
2. Entra en la carpeta **`switcher_gps`** del clone.
3. Abre y sigue **paso a paso** el archivo **`MAC_SETUP.md`** que está en esa carpeta. Ese archivo cubre:
   - Instalar **Xcode** desde la App Store
   - `xcode-select --switch` y aceptar la licencia (`xcodebuild -runFirstLaunch`)
   - Instalar **Flutter stable** y agregarlo al **PATH**
   - Ejecutar **`flutter doctor`** y corregir lo que indique
   - Desde `switcher_gps/`, ejecutar **`flutter create . --platforms=ios`** para generar la carpeta **`ios/`**
   - **`flutter pub get`**
   - Probar con **`flutter run`** (simulador o iPhone) o abrir **`ios/Runner.xcworkspace`** en Xcode
4. **Apple ID gratis:** basta para probar en un **iPhone** real.
5. **Apple Developer Program (pago):** necesario solo para publicar en la **App Store** / TestFlight de producción.
6. **No modifiques** el código Android ni reescribas el historial de git del repo.

Si algo falla, dime el comando exacto y la salida de `flutter doctor -v`.

---
