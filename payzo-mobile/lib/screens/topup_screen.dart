import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../animations/animations.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/service_providers.dart';
import '../providers/wallet_provider.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_widgets.dart';
import 'paystack_webview_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class TopupScreen extends ConsumerStatefulWidget {
  const TopupScreen({super.key});

  @override
  ConsumerState<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends ConsumerState<TopupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // ── Custom animated tab bar ──────────────────────────────────
            _TabSwitcher(controller: _tabCtrl),

            // ── Tab content ──────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _AirtimeTab(),
                  _WalletFundingTab(),
                ],
              ),
            ),
          ],
        ),
      );

  PreferredSizeWidget _buildAppBar() {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: const Text('Top Up'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: cs.outlineVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom animated pill tab switcher
// ─────────────────────────────────────────────────────────────────────────────

class _TabSwitcher extends StatelessWidget {
  final TabController controller;
  const _TabSwitcher({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: controller,
            padding: const EdgeInsets.all(4),
            indicator: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: cs.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_android_rounded, size: 16),
                    SizedBox(width: 7),
                    Text('Airtime'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 16),
                    SizedBox(width: 7),
                    Text('Fund Wallet'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Airtime / Data
// ─────────────────────────────────────────────────────────────────────────────

class _AirtimeTab extends ConsumerStatefulWidget {
  const _AirtimeTab();

  @override
  ConsumerState<_AirtimeTab> createState() => _AirtimeTabState();
}

class _AirtimeTabState extends ConsumerState<_AirtimeTab>
    with AutomaticKeepAliveClientMixin {
  final _phoneCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _formKey    = GlobalKey<FormState>();

  String _network = 'MTN';
  String _type    = 'airtime';
  bool   _loading = false;

  static const _networks = ['MTN', 'Airtel', 'Glo', '9mobile'];
  static const _quickAmounts = ['100', '200', '500', '1000'];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(topupServiceProvider).topup(
            phoneNumber: _phoneCtrl.text.trim(),
            network:     _network,
            type:        _type,
            amount:      double.parse(_amountCtrl.text.trim()),
          );
      await ref.read(walletProvider.notifier).fetch();
      if (mounted) _showResult(true);
    } catch (e) {
      if (mounted) _showResult(false, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showResult(bool success, [String? error]) {
    final amount = _amountCtrl.text;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ResultSheet(
        success: success,
        title:   success ? 'Top-up Successful!' : 'Top-up Failed',
        message: success
            ? '₦$amount ${_type == 'airtime' ? 'airtime' : 'data'} sent to ${_phoneCtrl.text} on $_network.'
            : (error ?? 'Something went wrong.'),
        onDone: () {
          Navigator.pop(context);
          if (success) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Form(
        key: _formKey,
        child: FadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Type toggle ────────────────────────────────────────────
              const ScreenSectionLabel('Select Type'),
              const SizedBox(height: 10),
              _TypeToggle(
                selected: _type,
                onChanged: (v) => setState(() => _type = v),
              ),

              const SizedBox(height: 24),

              // ── Network grid ───────────────────────────────────────────
              const ScreenSectionLabel('Network Provider'),
              const SizedBox(height: 10),
              _NetworkGrid(
                networks:  _networks,
                selected:  _network,
                onChanged: (v) => setState(() => _network = v),
              ),

              const SizedBox(height: 24),

              // ── Phone ──────────────────────────────────────────────────
              AppTextField(
                label:        'Phone Number',
                hint:         '08012345678',
                controller:   _phoneCtrl,
                prefixIcon:   Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter phone number';
                  if (v.length < 10) return 'Invalid phone number';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Amount ─────────────────────────────────────────────────
              AppTextField(
                label:        'Amount (₦)',
                hint:         '100',
                controller:   _amountCtrl,
                prefixIcon:   Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  final n = double.tryParse(v);
                  if (n == null || n < 50) return 'Minimum amount is ₦50';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // ── Quick amounts ──────────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts
                    .map((a) => _QuickChip(
                          label: '₦$a',
                          onTap: () => _amountCtrl.text = a,
                        ))
                    .toList(),
              ),

              const SizedBox(height: 36),

              PrimaryButton(
                label:     _loading ? 'Processing...' : 'Top Up Now',
                isLoading: _loading,
                icon:      _loading ? null : Icons.send_rounded,
                onTap:     _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Wallet Funding via Paystack
// ─────────────────────────────────────────────────────────────────────────────

class _WalletFundingTab extends ConsumerStatefulWidget {
  const _WalletFundingTab();

  @override
  ConsumerState<_WalletFundingTab> createState() => _WalletFundingTabState();
}

class _WalletFundingTabState extends ConsumerState<_WalletFundingTab> {
  final _amountCtrl = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  bool  _loading        = false;
  bool  _syncingBalance = false;

  static const _quickAmounts = ['500', '1000', '2000', '5000', '10000'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
      }
      return;
    }

    final naira      = double.parse(_amountCtrl.text.trim());
    final amountKobo = (naira * 100).toInt();

    setState(() => _loading = true);

    try {
      final result = await ref.read(paymentServiceProvider).initializePayment(
            amountInKobo: amountKobo,
            email:        user.email,
          );

      if (!mounted) return;
      setState(() => _loading = false);

      final success = await openPaystackWebView(
        context:          context,
        authorizationUrl: result.authorizationUrl,
        reference:        result.reference,
      );

      if (!mounted) return;

      if (success) await _refreshBalance(naira);

      if (mounted) _showResult(success, naira);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showResult(false, 0, e.toString());
    }
  }

  // Fetch wallet balance after payment, with a delay to allow webhook to settle.
  // Retries once if the balance hasn't increased by the expected amount.
  Future<void> _refreshBalance(double paidAmount) async {
    if (!mounted) return;
    setState(() => _syncingBalance = true);

    final balanceBefore = ref.read(walletProvider).valueOrNull?.balance ?? 0.0;

    // First fetch — wait 2s for webhook to credit the wallet
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await ref.read(walletProvider.notifier).fetch();

    final balanceAfter = ref.read(walletProvider).valueOrNull?.balance ?? 0.0;

    // Retry once if balance hasn't updated yet
    if (balanceAfter <= balanceBefore && mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      await ref.read(walletProvider.notifier).fetch();
    }

    if (mounted) setState(() => _syncingBalance = false);
  }

  void _showResult(bool success, double amount, [String? error]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ResultSheet(
        success: success,
        title:   success ? 'Wallet Funded!' : 'Payment Failed',
        message: success
            ? '₦${amount.toStringAsFixed(0)} has been added to your wallet.'
            : (error ?? 'Payment was not completed.'),
        onDone: () {
          Navigator.pop(context);
          if (success) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Form(
        key: _formKey,
        child: FadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Balance syncing banner ─────────────────────────────────
              if (_syncingBalance)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Updating balance...',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Info card ──────────────────────────────────────────────
              const _FundingInfoCard(),

              const SizedBox(height: 28),

              // ── Amount ─────────────────────────────────────────────────
              const ScreenSectionLabel('Enter Amount'),
              const SizedBox(height: 10),
              AppTextField(
                label:        'Amount (₦)',
                hint:         '1,000',
                controller:   _amountCtrl,
                prefixIcon:   Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter an amount';
                  final n = double.tryParse(v);
                  if (n == null || n < 100) return 'Minimum amount is ₦100';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // ── Quick amounts ──────────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts
                    .map((a) => _QuickChip(
                          label: '₦$a',
                          onTap: () => _amountCtrl.text = a,
                        ))
                    .toList(),
              ),

              const SizedBox(height: 28),

              // ── Fund Wallet button ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Fund Wallet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Security badge ─────────────────────────────────────────
              const _SecurityBadge(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _TypeChip(
            value:    'airtime',
            label:    'Airtime',
            icon:     Icons.phone_in_talk_outlined,
            selected: selected == 'airtime',
            onTap:    () => onChanged('airtime'),
          ),
          const SizedBox(width: 10),
          _TypeChip(
            value:    'data',
            label:    'Data',
            icon:     Icons.wifi_rounded,
            selected: selected == 'data',
            onTap:    () => onChanged('data'),
          ),
        ],
      );
}

class _TypeChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _NetworkGrid extends StatelessWidget {
  final List<String> networks;
  final String selected;
  final ValueChanged<String> onChanged;

  const _NetworkGrid({
    required this.networks,
    required this.selected,
    required this.onChanged,
  });

  static const _colors = {
    'MTN':     Color(0xFFFFCC00),
    'Airtel':  Color(0xFFFF4444),
    'Glo':     Color(0xFF00A651),
    '9mobile': Color(0xFF006633),
  };

  @override
  Widget build(BuildContext context) => Row(
        children: networks.asMap().entries.map((e) {
          final n      = e.value;
          final isLast = e.key == networks.length - 1;
          final active = selected == n;
          final color  = _colors[n] ?? AppColors.primary;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(n);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: active
                        ? color.withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n,
                        style: TextStyle(
                          color: active ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Wallet funding specific widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FundingInfoCard extends StatelessWidget {
  const _FundingInfoCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withValues(alpha: 0.1),
              cs.secondary.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add money to your wallet',
                    style: tt.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Instant funding via card, bank transfer or USSD.',
                    style: tt.bodySmall?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 13, color: AppColors.success),
            const SizedBox(width: 6),
            Text(
              'Secured by Paystack',
              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
