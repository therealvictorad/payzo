import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../animations/animations.dart';
import '../core/currency.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/service_providers.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/app_text_field.dart';
import '../widgets/pin_entry_sheet.dart';
import '../widgets/primary_button.dart';

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  late final AnimationController _successCtrl;
  late final Animation<double> _successScale;
  late final Animation<double> _successOpacity;

  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _successOpacity = CurvedAnimation(parent: _successCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _amountCtrl.dispose();
    _successCtrl.dispose();
    ref.read(transactionProvider.notifier).resetTransferState();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    final user = ref.read(authProvider).user;
    if (user != null && user.hasTransactionPin) {
      final pin = await PinEntrySheet.show(
        context,
        title:    'Confirm Transfer',
        subtitle: 'Enter your 4-digit transaction PIN to continue.',
      );
      if (pin == null || !mounted) return;

      try {
        await ref.read(transactionServiceProvider).verifyPin(pin);
      } catch (e) {
        if (!mounted) return;
        ref.read(transactionProvider.notifier).setError(e.toString());
        return;
      }
    }

    final success = await ref
        .read(transactionProvider.notifier)
        .transfer(_emailCtrl.text.trim(), amount);

    if (success) {
      await ref.read(walletProvider.notifier).fetch();
      setState(() => _showSuccess = true);
      _successCtrl.forward();
    }
  }

  void _reset() {
    _emailCtrl.clear();
    _amountCtrl.clear();
    _successCtrl.reset();
    ref.read(transactionProvider.notifier).resetTransferState();
    setState(() => _showSuccess = false);
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionProvider);
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim),
              child: child,
            ),
          ),
          child: _showSuccess
              ? _SuccessView(
                  key: const ValueKey('success'),
                  amount: double.tryParse(_amountCtrl.text) ?? 0,
                  receiverEmail: _emailCtrl.text,
                  scaleAnim: _successScale,
                  opacityAnim: _successOpacity,
                  onDone: () => Navigator.pop(context),
                  onSendAnother: _reset,
                )
              : _FormView(
                  key: const ValueKey('form'),
                  formKey: _formKey,
                  emailCtrl: _emailCtrl,
                  amountCtrl: _amountCtrl,
                  isSending: txState.isSending,
                  error: txState.error,
                  walletBalance: walletAsync.valueOrNull?.balance,
                  onSubmit: _submit,
                ),
        ),
      ),
    );
  }
}

// ── Form View ─────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController amountCtrl;
  final bool isSending;
  final String? error;
  final double? walletBalance;
  final VoidCallback onSubmit;

  const _FormView({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.amountCtrl,
    required this.isSending,
    required this.error,
    required this.walletBalance,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance chip
              if (walletBalance != null)
                FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Available: ${formatNaira(walletBalance!)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: AppTextField(
                  label: 'Recipient Email',
                  hint: 'recipient@example.com',
                  controller: emailCtrl,
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: AppTextField(
                  label: 'Amount',
                  hint: '0.00',
                  controller: amountCtrl,
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSubmit(),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    if (walletBalance != null && n > walletBalance!) {
                      return 'Insufficient balance';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Error
              if (error != null)
                FadeSlideIn(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(error!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: PrimaryButton(
                  label: 'Send Money',
                  icon: Icons.send_rounded,
                  onTap: onSubmit,
                  isLoading: isSending,
                ),
              ),
              const SizedBox(height: 20),
              // Disclaimer
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: Center(
                  child: Text(
                    'Transfers are instant and irreversible.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Success View ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final double amount;
  final String receiverEmail;
  final Animation<double> scaleAnim;
  final Animation<double> opacityAnim;
  final VoidCallback onDone;
  final VoidCallback onSendAnother;

  const _SuccessView({
    super.key,
    required this.amount,
    required this.receiverEmail,
    required this.scaleAnim,
    required this.opacityAnim,
    required this.onDone,
    required this.onSendAnother,
  });

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: opacityAnim,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: scaleAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Transfer Successful!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${formatNaira(amount)} sent to',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                receiverEmail,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 48),
              PrimaryButton(label: 'Done', onTap: onDone),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onSendAnother,
                child: const Text(
                  'Send Another',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
}
