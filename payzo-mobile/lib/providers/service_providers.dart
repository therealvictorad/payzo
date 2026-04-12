import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/bill_service.dart';
import '../services/payment_link_service.dart';
import '../services/payment_service.dart';
import '../services/topup_service.dart';
import '../services/kyc_service.dart';
import '../services/transaction_service.dart';
import '../services/user_service.dart';
import '../services/virtual_card_service.dart';
import '../services/wallet_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(apiServiceProvider)),
);

final walletServiceProvider = Provider<WalletService>(
  (ref) => WalletService(ref.read(apiServiceProvider)),
);

final transactionServiceProvider = Provider<TransactionService>(
  (ref) => TransactionService(ref.read(apiServiceProvider)),
);

final topupServiceProvider = Provider<TopupService>(
  (ref) => TopupService(ref.read(apiServiceProvider)),
);

final billServiceProvider = Provider<BillService>(
  (ref) => BillService(ref.read(apiServiceProvider)),
);

final paymentLinkServiceProvider = Provider<PaymentLinkService>(
  (ref) => PaymentLinkService(ref.read(apiServiceProvider)),
);

final virtualCardServiceProvider = Provider<VirtualCardService>(
  (ref) => VirtualCardService(ref.read(apiServiceProvider)),
);

final paymentServiceProvider = Provider<PaymentService>(
  (ref) => PaymentService(ref.read(apiServiceProvider)),
);

final kycServiceProvider = Provider<KycService>(
  (ref) => KycService(ref.read(apiServiceProvider)),
);

final userServiceProvider = Provider<UserService>(
  (ref) => UserService(ref.read(apiServiceProvider)),
);
