# Setup iOS en Mac (desde cero)

Guía breve para compilar **Switcher GPS** en un Mac sin herramientas previas.

## 0. Obtener el código

```bash
git clone https://github.com/jnarios-ops/switcher2026.git
cd switcher2026
```

Si el repo incluye solo la carpeta del app, entra en `switcher_gps/` antes de los pasos siguientes.

---

## 1. Xcode

Instala **Xcode** desde la **App Store** (descarga grande; puede tardar).

Luego en Terminal:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

(Acepta la licencia cuando lo pida.)

---

## 2. Flutter (stable)

Instala Flutter stable según [flutter.dev/docs/get-started/install/macos](https://docs.flutter.dev/get-started/install/macos) (zip o git clone en `~/development/flutter`).

Añade al PATH (ejemplo en `~/.zshrc`):

```bash
export PATH="$PATH:$HOME/development/flutter/bin"
```

Cierra y abre Terminal, luego:

```bash
flutter channel stable
flutter upgrade
```

---

## 3. `flutter doctor`

```bash
flutter doctor
```

Corrige lo que marque en rojo/amarillo (CocoaPods, licencia Xcode, etc.). Si pide Pods:

```bash
sudo gem install cocoapods
```

Vuelve a ejecutar `flutter doctor` hasta que iOS/Xcode queden OK.

---

## 4. Generar `ios/` (no viene en el repo)

Desde la carpeta del proyecto (`switcher_gps/`):

```bash
flutter create . --platforms=ios
flutter pub get
```

---

## 5. Ejecutar en simulador o iPhone

Simulador o dispositivo conectado:

```bash
flutter devices
flutter run
```

O abre el workspace en Xcode, elige Team y ejecuta:

```bash
open ios/Runner.xcworkspace
```

- **Apple ID gratis:** sirve para probar en tu **iPhone** (desarrollo).
- **Apple Developer Program (pago):** necesario para **App Store** / TestFlight público.

Bundle ID recomendado (alinear con Android): `cl.switcher.gps`.

---

## Notas

- No hace falta copiar `build/` ni `.dart_tool/` desde otra máquina; se regeneran con `flutter pub get` y al compilar.
- La app es un WebView del portal; en iOS revisa permisos de **ubicación** en `ios/Runner/Info.plist` si el mapa lo pide (`NSLocationWhenInUseUsageDescription`).
