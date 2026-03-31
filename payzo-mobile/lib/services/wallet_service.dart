import '../models/wallet.dart';
import 'api_service.dart';

class WalletService {
  final ApiService _api;
  WalletService(this._api);

  Future<WalletModel> getWallet() async {
    final res = await _api.get('/wallet');
    return WalletModel.fromJson(res.data['data']);
  }
}
