import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api;
  AuthService(this._api);

  Future<({UserModel user, String token})> login(String email, String password) async {
    final res = await _api.post('/login', data: {'email': email, 'password': password});
    final data = res.data['data'];
    final token = data['token'] as String;
    final user  = UserModel.fromJson(data['user']);
    await _api.saveToken(token);
    await _api.saveUser(jsonEncode(data['user']));
    return (user: user, token: token);
  }

  Future<({UserModel user, String token})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String role = 'user',
    String? referralCode,
  }) async {
    final res = await _api.post('/register', data: {
      'name':                  name,
      'email':                 email,
      'password':              password,
      'password_confirmation': passwordConfirmation,
      'role':                  role,
      if (referralCode != null) 'referral_code': referralCode,
    });
    final data = res.data['data'];
    final token = data['token'] as String;
    final user  = UserModel.fromJson(data['user']);
    await _api.saveToken(token);
    await _api.saveUser(jsonEncode(data['user']));
    return (user: user, token: token);
  }

  Future<UserModel?> getStoredUser() async {
    final json = await _api.readUser();
    if (json == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } finally {
      await _api.clearToken();
      await _api.clearUser();
    }
  }
}
