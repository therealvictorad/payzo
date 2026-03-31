import 'package:dio/dio.dart';
import '../models/virtual_card.dart';
import 'api_service.dart';

class VirtualCardService {
  final ApiService _api;
  VirtualCardService(this._api);

  Future<VirtualCardModel> createCard() async {
    try {
      final res = await _api.post('/cards');
      return VirtualCardModel.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<List<VirtualCardModel>> getCards() async {
    try {
      final res = await _api.get('/cards');
      final List data = res.data['data'];
      return data.map((e) => VirtualCardModel.fromJson(e)).toList();
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
