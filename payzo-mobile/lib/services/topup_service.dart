import 'package:dio/dio.dart';
import '../models/transaction.dart';
import 'api_service.dart';

class TopupService {
  final ApiService _api;
  TopupService(this._api);

  Future<TransactionModel> topup({
    required String phoneNumber,
    required String network,
    required String type,
    required double amount,
  }) async {
    try {
      final res = await _api.post('/topup', data: {
        'phone_number': phoneNumber,
        'network':      network,
        'type':         type,
        'amount':       amount,
      });
      return TransactionModel.fromJson(res.data['data']);
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
