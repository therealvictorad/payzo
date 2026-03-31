import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import 'service_providers.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final bool transferSuccess;

  const TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.transferSuccess = false,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool? transferSuccess,
  }) =>
      TransactionState(
        transactions: transactions ?? this.transactions,
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
        error: error,
        transferSuccess: transferSuccess ?? this.transferSuccess,
      );
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  TransactionNotifier(this._ref) : super(const TransactionState());

  final Ref _ref;

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _ref.read(transactionServiceProvider).getHistory();
      state = state.copyWith(transactions: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> transfer(String receiverEmail, double amount) async {
    state = state.copyWith(isSending: true, error: null, transferSuccess: false);
    try {
      final tx = await _ref.read(transactionServiceProvider).transfer(receiverEmail, amount);
      state = state.copyWith(
        isSending: false,
        transferSuccess: true,
        transactions: [tx, ...state.transactions],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSending: false, error: _parseError(e));
      return false;
    }
  }

  void resetTransferState() {
    state = state.copyWith(transferSuccess: false, error: null);
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('422')) return 'Invalid input. Check the email or amount.';
    if (msg.contains('Insufficient')) return 'Insufficient wallet balance.';
    if (msg.contains('yourself')) return 'You cannot send money to yourself.';
    return 'Transfer failed. Please try again.';
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>(
  (ref) => TransactionNotifier(ref),
);
