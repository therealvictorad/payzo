import 'dart:io';

class AppConstants {
  // ── API Base URL ────────────────────────────────────────────────────────────
  // Automatically resolves:
  //   Android emulator  → 10.0.2.2      (maps to host machine localhost)
  //   Physical device   → 192.168.0.200 (PC local IP on same WiFi)
  //   iOS simulator     → 127.0.0.1
  //   Production        → replace _productionUrl with your deployed API URL
  static const _emulatorUrl   = 'http://10.0.2.2:8000/api';
  static const _deviceUrl     = 'http://192.168.0.200:8000/api';
  static const _iosUrl        = 'http://127.0.0.1:8000/api';
  static const _productionUrl = 'https://your-production-domain.com/api';

  static String get baseUrl {
    // Flip this to true when deploying to production
    const isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
    if (isProduction) return _productionUrl;

    if (Platform.isIOS) return _iosUrl;

    // Android: detect emulator by checking the ANDROID_EMULATOR env var
    // or fall back to checking if the emulator host is reachable.
    // The most reliable zero-config signal: emulators set ANDROID_EMULATOR=1
    // or we use the --dart-define flag at build time.
    const isEmulator = bool.fromEnvironment('IS_EMULATOR', defaultValue: false);
    return isEmulator ? _emulatorUrl : _deviceUrl;
  }

  static const tokenKey       = 'auth_token';
  static const userKey        = 'auth_user';
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}
