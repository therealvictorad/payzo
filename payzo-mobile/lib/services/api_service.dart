import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';

class ApiService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  final _uuid    = const Uuid();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl:        AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Accept':       'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Log requests in debug builds only — never in release
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody:  true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ));
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Bearer token
          final token = await _storage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Attach idempotency key on every mutating request
          if (['POST', 'PUT', 'PATCH'].contains(options.method)) {
            options.headers['Idempotency-Key'] = _uuid.v4();
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

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> postForm(String path, {required FormData formData}) =>
      _dio.post(path, data: formData,
          options: Options(contentType: 'multipart/form-data'));

  Future<Response> delete(String path) => _dio.delete(path);

  Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: AppConstants.tokenKey);

  Future<bool> hasToken() async =>
      (await _storage.read(key: AppConstants.tokenKey)) != null;

  Future<void> saveUser(String userJson) =>
      _storage.write(key: AppConstants.userKey, value: userJson);

  Future<String?> readUser() => _storage.read(key: AppConstants.userKey);

  Future<void> clearUser() => _storage.delete(key: AppConstants.userKey);
}
