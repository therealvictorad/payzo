import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/service_providers.dart';
import '../providers/wallet_provider.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_widgets.dart';

class BillScreen extends ConsumerStatefulWidget {
  const BillScreen({super.key});

  @override
  ConsumerState<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends ConsumerState<BillScreen> {
  final _customerCtrl = TextEditingController();
  final _amountCtrl   = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  String _category = 'tv';
  String _provider = 'DSTV';
  bool   _loading  = false;

  static const _providers = {
    'tv':          ['DSTV', 'GOtv', 'Startimes'],
    'electricity': ['IKEDC', 'EKEDC', 'AEDC', 'IBEDC'],
  };

  @override
  void dispose() {
    _customerCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String cat) => setState(() {
    _category = cat;
    _provider = _providers[cat]!.first;
  });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(billServiceProvider).pay(
        provider:   _provider,
        customerId: _customerCtrl.text.trim(),
        amount:     double.parse(_amountCtrl.text.trim()),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ResultSheet(
        success: success,
        title:   success ? 'Payment Successful!' : 'Payment Failed',
        message: success
            ? '$_provider bill of ₦${_amountCtrl.text} paid for ${_customerCtrl.text}.'
            : (error ?? 'Something went wrong.'),
        onDone: () {
          Navigator.pop(context);
          if (success) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Bill Payment'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Category ─────────────────────────────────────────────
                const ScreenSectionLabel('Category'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _CategoryCard(
                      icon:   Icons.tv_rounded,
                      label:  'TV / Cable',
                      active: _category == 'tv',
                      color:  const Color(0xFF6C63FF),
                      onTap:  () => _onCategoryChanged('tv'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      icon:   Icons.bolt_rounded,
                      label:  'Electricity',
                      active: _category == 'electricity',
                      color:  const Color(0xFFFFB347),
                      onTap:  () => _onCategoryChanged('electricity'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Provider ─────────────────────────────────────────────
                const ScreenSectionLabel('Provider'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _providers[_category]!.map((p) {
                    final active = _provider == p;
                    return GestureDetector(
                      onTap: () => setState(() => _provider = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary.withOpacity(0.15)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            color: active
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Customer ID ──────────────────────────────────────────
                AppTextField(
                  label:      _category == 'tv' ? 'Smart Card / IUC Number' : 'Meter Number',
                  hint:       _category == 'tv' ? 'e.g. 1234567890' : 'e.g. 45012345678',
                  controller: _customerCtrl,
                  prefixIcon: Icons.tag_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter customer ID' : null,
                ),

                const SizedBox(height: 20),

                AppTextField(
                  label:      'Amount (₦)',
                  hint:       '2500',
                  controller: _amountCtrl,
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter amount';
                    final n = double.tryParse(v);
                    if (n == null || n < 100) return 'Minimum amount is ₦100';
                    return null;
                  },
                ),

                const SizedBox(height: 36),

                PrimaryButton(
                  label:     _loading ? 'Processing...' : 'Pay Bill',
                  isLoading: _loading,
                  onTap:     _loading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      );
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: active ? color.withOpacity(0.12) : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(icon, color: active ? color : Theme.of(context).colorScheme.onSurfaceVariant, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
