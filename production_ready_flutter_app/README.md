
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
