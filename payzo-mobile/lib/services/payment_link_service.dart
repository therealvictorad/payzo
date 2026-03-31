import 'package:dio/dio.dart';
import '../models/payment_link.dart';
import 'api_service.dart';

class PaymentLinkService {
  final ApiService _api;
  PaymentLinkService(this._api);

  Future<PaymentLinkModel> create({
    required double amount,
    String? description,
  }) async {
    try {
      final res = await _api.post('/payment-links', data: {
        'amount':      amount,
        'description': description,
      });
      return PaymentLinkModel.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<List<PaymentLinkModel>> getMyLinks({int page = 1}) async {
    try {
      final res = await _api.get('/payment-links', params: {'page': page});
      final List data = res.data['data']['data'];
      return data.map((e) => PaymentLinkModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> pay(String code) async {
    try {
      final res = await _api.post('/pay/$code');
      return res.data['data'];
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  String _parseError(DioException e) {
    final msg = e.response?.data?['message'];
    if (msg != null) return msg as String;
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Request timed out. Check your connection.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
