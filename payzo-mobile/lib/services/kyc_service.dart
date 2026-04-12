import 'package:dio/dio.dart';
import '../models/kyc_status.dart';
import 'api_service.dart';

class KycService {
  final ApiService _api;
  KycService(this._api);

  /// GET /api/v1/kyc/status
  Future<KycStatusModel> getStatus() async {
    try {
      final res = await _api.get('/kyc/status');
      return KycStatusModel.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// POST /api/v1/kyc/submit — multipart form upload
  Future<void> submit({
    required String documentType,
    required String documentNumber,
    required String fullName,
    required String dateOfBirth,
    required String filePath,
    String? address,
  }) async {
    try {
      final formData = FormData.fromMap({
        'document_type':   documentType,
        'document_number': documentNumber,
        'full_name':       fullName,
        'date_of_birth':   dateOfBirth,
        if (address != null) 'address': address,
        'document': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      await _api.postForm('/kyc/submit', formData: formData);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  String _parseError(DioException e) {
    final errors = e.response?.data?['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = (errors.values.first as List).first;
      return first.toString();
    }
    final msg = e.response?.data?['message'];
    if (msg != null) return msg as String;
    return 'Something went wrong. Please try again.';
  }
}
