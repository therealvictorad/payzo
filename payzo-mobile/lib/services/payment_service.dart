import 'package:dio/dio.dart';
import 'api_service.dart';

class PaymentInitResult {
  final String authorizationUrl;
  final String reference;

  const PaymentInitResult({
    required this.authorizationUrl,
    required this.reference,
  });
}

class PaymentService {
  final ApiService _api;
  PaymentService(this._api);

  Future<PaymentInitResult> initializePayment({
    required int amountInKobo,
    required String email,
  }) async {
    try {
      final res = await _api.post('/payments/initialize', data: {
        'amount': amountInKobo,
        'email': email,
      });
      final data = res.data['data'];
      return PaymentInitResult(
        authorizationUrl: data['authorization_url'],
        reference: data['reference'],
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<String> verifyPayment(String reference) async {
    try {
      final res = await _api.get('/payments/verify/$reference');
      return res.data['data']['status'] as String;
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
