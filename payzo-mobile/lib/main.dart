import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes.dart';
import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/bill_screen.dart';
import 'screens/kyc_screen.dart';
import 'screens/main_shell.dart';
import 'screens/payment_link_screen.dart';
import 'screens/pin_setup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/send_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/topup_screen.dart';
import 'screens/transactions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final container = ProviderContainer();
  await container.read(themeModeProvider.notifier).init();

  runApp(UncontrolledProviderScope(container: container, child: const PayzoApp()));
}

class PayzoApp extends ConsumerWidget {
  const PayzoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Payzo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:       return _route(const SplashScreen());
          case AppRoutes.auth:          return _route(const AuthScreen(startWithLogin: true));
          case AppRoutes.login:        return _route(const AuthScreen(startWithLogin: true));
          case AppRoutes.register:     return _route(const AuthScreen(startWithLogin: false));
          case AppRoutes.shell:        return _route(const MainShell());
          case AppRoutes.send:         return _route(const SendScreen());
          case AppRoutes.transactions: return _route(const TransactionsScreen());
          case AppRoutes.topup:        return _route(const TopupScreen());
          case AppRoutes.bills:        return _route(const BillScreen());
          case AppRoutes.paymentLinks: return _route(const PaymentLinkScreen());
          case AppRoutes.profile:      return _route(const ProfileScreen());
          case AppRoutes.pinSetup:     return _route(const PinSetupScreen());
          case AppRoutes.kyc:          return _route(const KycScreen());
          default:                     return _route(const SplashScreen());
        }
      },
    );
  }

  PageRouteBuilder _route(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, animation, __, child) {
          final fade  = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      );
}
