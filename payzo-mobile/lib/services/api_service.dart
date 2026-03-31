import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class ApiService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  /// Saves the auth token securely.
  Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);

  /// Clears the stored auth token.
  Future<void> clearToken() => _storage.delete(key: AppConstants.tokenKey);

  /// Returns true if a token is stored.
  Future<bool> hasToken() async =>
      (await _storage.read(key: AppConstants.tokenKey)) != null;

  /// Saves the user JSON securely.
  Future<void> saveUser(String userJson) =>
      _storage.write(key: AppConstants.userKey, value: userJson);

  /// Reads the stored user JSON.
  Future<String?> readUser() => _storage.read(key: AppConstants.userKey);

  /// Clears the stored user JSON.
  Future<void> clearUser() => _storage.delete(key: AppConstants.userKey);
}
