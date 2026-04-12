class AppConstants {
  // ── Base URLs ─────────────────────────────────────────────────────────────
  //
  // All URLs are injected at build time via --dart-define. Never hardcode
  // production URLs or IPs in source. Examples:
  //
  // Dev (emulator):
  //   flutter run --dart-define=BASE_URL=http://10.0.2.2:8000/api/v1
  //
  // Dev (physical device on LAN):
  //   flutter run --dart-define=BASE_URL=http://192.168.x.x:8000/api/v1
  //
  // Release:
  //   flutter build apk --dart-define=BASE_URL=https://api.yourapp.com/api/v1
  //
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1', // safe emulator fallback for local dev only
  );

  // ── Storage keys ──────────────────────────────────────────────────────────
  static const tokenKey = 'auth_token';
  static const userKey  = 'auth_user';

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}
