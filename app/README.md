# Roost Student App

The default Flutter entry point, `lib/main.dart`, is the FUTO student hostel
reservation app. It requires the live backend for sign-in, hostel availability,
reservations, and payment flow; there is no offline demo-data mode.

## Run the student app

```bash
flutter pub get
flutter run
# explicitly select the student entry point:
flutter run -t lib/main.dart
```

To point a local Android emulator build at another API:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1
```

## Build a student APK

Install Android Studio and the Android SDK, then run:

```bash
flutter build apk --release
```

The APK is created at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The current release configuration is debug-key signed for testing. Create and
configure a private Android signing key before Play Store distribution.

## Optional admin app

The administrative mobile app has a separate entry point and is optional:

```bash
flutter run -t lib/main_admin.dart
flutter build apk --release -t lib/main_admin.dart
```

It requires a backend admin account. The static web dashboard is in `../admin/`.
