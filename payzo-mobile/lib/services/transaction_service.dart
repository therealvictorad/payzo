import 'package:dio/dio.dart';
import '../models/transaction.dart';
import 'api_service.dart';

class TransactionService {
  final ApiService _api;
  TransactionService(this._api);

  Future<TransactionModel> transfer(String receiverEmail, double amount) async {
    try {
      final res = await _api.post('/transfer', data: {
        'receiver_email': receiverEmail,
        'amount': amount,
      });
      return TransactionModel.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<List<TransactionModel>> getHistory({int page = 1}) async {
    try {
      final res = await _api.get('/transactions', params: {'page': page});
      final List data = res.data['data']['data'];
      return data.map((e) => TransactionModel.fromJson(e)).toList();
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
