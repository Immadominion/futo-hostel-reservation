/// App-wide configuration.
///
/// Both values are compile-time constants so they can be overridden at build
/// time with `--dart-define`, e.g.:
///
///   flutter run                                   # live backend (default)
///   flutter run --dart-define=USE_DEMO_DATA=true  # offline demo data
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1
///
/// [useDemoData] is the single switch between the live API and the built-in
/// static demo data. When true, no network calls are made anywhere in the app —
/// handy for a guaranteed-offline demo if the backend is asleep/unreachable.
class AppConfig {
  AppConfig._();

  // Not `const` so widget tests can force demo mode offline
  // (`AppConfig.useDemoData = true`) without a build flag.
  static bool useDemoData =
      bool.fromEnvironment('USE_DEMO_DATA', defaultValue: false);

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://futo-hostel-reservation-backend.onrender.com/api/v1',
  );
}
