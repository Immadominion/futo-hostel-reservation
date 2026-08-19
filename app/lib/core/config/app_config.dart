/// App-wide configuration.
///
/// The API base URL is a compile-time constant and can be overridden at build
/// time with `--dart-define`, e.g.:
///
///   flutter run
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1
class AppConfig {
  AppConfig._();

  // Demo mode is available only to widget tests that set this explicitly.
  // Production/debug app launches always require the live API.
  static bool useDemoData = false;

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://futo-hostel-reservation-backend.onrender.com/api/v1',
  );

  /// Where Paystack redirects after checkout (PaystackService.callbackUrl on
  /// the backend). The payment WebView watches for navigation starting with
  /// this and intercepts it — checkout is "done" the moment that happens, so
  /// the page behind it never actually needs to load.
  static String get paystackCallbackUrl => '$apiBaseUrl/payments/callback';
}
