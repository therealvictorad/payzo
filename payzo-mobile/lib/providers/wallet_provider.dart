import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet.dart';
import 'service_providers.dart';

class WalletNotifier extends StateNotifier<AsyncValue<WalletModel>> {
  WalletNotifier(this._ref) : super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(walletServiceProvider).getWallet(),
    );
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, AsyncValue<WalletModel>>(
  (ref) => WalletNotifier(ref),
);
