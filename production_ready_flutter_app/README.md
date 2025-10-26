
# Production-Ready Flutter App (Worldwide)

This is a production-ready Flutter application template with:
- Clean architecture & folders
- i18n (English, Hindi, Arabic) via `gen_l10n`
- Dark/Light theme
- State management with Provider
- Error handling (FlutterError + Zone)
- Secure storage wrapper
- API client with retry & timeouts
- Connectivity awareness
- Crash reporting hooks (Sentry/Firebase - optional)
- Build hardening tips & ProGuard rules
- CI sample (GitHub Actions)

## Quick Start
1) Create a fresh Flutter app:
```bash
flutter create my_app
cd my_app
```

2) Copy the contents of this template into your project (replace existing files):
- Replace `pubspec.yaml`, `analysis_options.yaml`, `l10n.yaml`
- Replace `lib/` entirely
- Add `proguard-rules.pro` into `android/app/` (you may need to create it)
- Add `android/app/src/main/res/xml/network_security_config.xml` (create folders)
- Ensure your `android/app/src/main/AndroidManifest.xml` has `android:usesCleartextTraffic="false"` in `<application>`

3) Install deps and generate l10n:
```bash
flutter clean
flutter pub get
flutter gen-l10n
```

4) Run:
```bash
flutter run
```

5) Release builds:
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
flutter build web --release
```

> For Firebase/Sentry, follow their official setup to add platform files and enable Crashlytics/Analytics.

## Running in VS Code

1. **Install prerequisites**
   - Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) and ensure `flutter doctor` passes for your target platforms (Android, iOS, Windows, web).
   - Install VS Code along with the official **Flutter** and **Dart** extensions.

2. **Open the project**
   - Launch VS Code and choose **File ▸ Open Folder…**, then select `production_ready_flutter_app/`.
   - When prompted, click **Get Packages** or run `flutter pub get` in the built-in terminal.

3. **Configure devices**
   - For mobile: start an Android emulator or connect an iOS device/simulator.
   - For Windows desktop: run `flutter config --enable-windows-desktop` and ensure you have the Windows build tools installed.
   - For web: run `flutter config --enable-web`.

4. **Run from VS Code**
   - Press `F5` or use the **Run and Debug** panel, select the desired device from the status bar, and start debugging.
   - The default launch configuration hot-reloads changes and streams logs into the Debug Console.

5. **Common commands**
   ```bash
   flutter pub get          # fetch dependencies
   flutter run -d windows   # Windows desktop build
   flutter run -d chrome    # Web preview
   flutter build apk        # Android release artifact
   ```

6. **Troubleshooting**
   - Use **View ▸ Command Palette… ▸ Flutter: Run Flutter Doctor** for diagnostic output within VS Code.
   - If the IDE does not detect a device, ensure the emulator/device is running and restart the Dart/Flutter extensions.
