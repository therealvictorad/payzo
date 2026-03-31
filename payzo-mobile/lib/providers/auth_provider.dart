import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'service_providers.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserModel? user, bool? isLoading, String? error, bool clearUser = false}) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState());

  final Ref _ref;

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _ref.read(authServiceProvider).login(email, password);
      state = AuthState(user: result.user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String role = 'user',
    String? referralCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _ref.read(authServiceProvider).register(
            name:                 name,
            email:                email,
            password:             password,
            passwordConfirmation: passwordConfirmation,
            role:                 role,
            referralCode:         referralCode,
          );
      state = AuthState(user: result.user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _ref.read(authServiceProvider).logout();
    state = const AuthState();
  }

  Future<void> restoreUser() async {
    final user = await _ref.read(authServiceProvider).getStoredUser();
    if (user != null) state = AuthState(user: user);
  }

  void updateWalletBalance(double balance) {
    if (state.user == null) return;
    final updatedWallet = state.user!.wallet?.copyWith(balance: balance);
    if (updatedWallet != null) {
      state = state.copyWith(user: state.user!.copyWith(wallet: updatedWallet));
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Invalid email or password.';
    if (msg.contains('422')) return 'Please check your input and try again.';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
