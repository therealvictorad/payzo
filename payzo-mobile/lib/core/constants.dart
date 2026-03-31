class AppConstants {
  // ── API Base URL ────────────────────────────────────────────────────────────
  // Android emulator → use 10.0.2.2 (maps to host machine localhost)
  // Physical device  → use your PC's local IP on the same WiFi network
  // Production       → replace with your deployed API URL
  static const baseUrl = 'http://192.168.0.200:8000/api';

  static const tokenKey = 'auth_token';
  static const userKey  = 'auth_user';
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}
