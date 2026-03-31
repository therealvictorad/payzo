import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/payment_link.dart';
import '../providers/service_providers.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_widgets.dart';

class PaymentLinkScreen extends ConsumerStatefulWidget {
  const PaymentLinkScreen({super.key});

  @override
  ConsumerState<PaymentLinkScreen> createState() => _PaymentLinkScreenState();
}

class _PaymentLinkScreenState extends ConsumerState<PaymentLinkScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _amountCtrl  = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _payCodeCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  bool _creating = false;
  bool _paying   = false;
  List<PaymentLinkModel> _links = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchLinks();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _payCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLinks() async {
    try {
      final links = await ref.read(paymentLinkServiceProvider).getMyLinks();
      if (mounted) setState(() => _links = links);
    } catch (_) {}
  }

  Future<void> _createLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _creating = true);
    try {
      final link = await ref.read(paymentLinkServiceProvider).create(
        amount:      double.parse(_amountCtrl.text.trim()),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      _fetchLinks();
      if (mounted) _showCreatedSheet(link);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _payLink() async {
    final code = _payCodeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _paying = true);
    try {
      await ref.read(paymentLinkServiceProvider).pay(code);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => ResultSheet(
            success: true,
            title:   'Payment Successful!',
            message: 'Payment for link $code completed.',
            onDone:  () { Navigator.pop(context); _payCodeCtrl.clear(); },
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _showCreatedSheet(PaymentLinkModel link) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.link_rounded, color: AppColors.success, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Link Created!', style: tt.titleLarge),
            const SizedBox(height: 8),
            Text('Share this code to receive ₦${link.amount.toStringAsFixed(2)}', style: tt.bodyMedium),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(link.code, style: tt.titleMedium?.copyWith(color: cs.primary, letterSpacing: 1)),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: link.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!'), duration: Duration(seconds: 2)),
                      );
                    },
                    child: Icon(Icons.copy_rounded, color: cs.primary, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ResultSheet(
        success: false,
        title:   'Failed',
        message: msg,
        onDone:  () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Payment Links'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabCtrl,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: const [Tab(text: 'Create Link'), Tab(text: 'Pay a Link')],
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // ── Tab 1: Create ──────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label:      'Amount (₦)',
                      hint:       '5000',
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter amount';
                        if ((double.tryParse(v) ?? 0) < 1) return 'Invalid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label:      'Description (optional)',
                      hint:       'e.g. Payment for services',
                      controller: _descCtrl,
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label:     _creating ? 'Creating...' : 'Generate Link',
                      isLoading: _creating,
                      onTap:     _creating ? null : _createLink,
                    ),
                    if (_links.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text('My Links', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ..._links.map((l) => _LinkTile(link: l)),
                    ],
                  ],
                ),
              ),
            ),

            // ── Tab 2: Pay ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label:      'Payment Code',
                    hint:       'PAY-XXXXXXXX',
                    controller: _payCodeCtrl,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label:     _paying ? 'Processing...' : 'Pay Now',
                    isLoading: _paying,
                    onTap:     _paying ? null : _payLink,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LinkTile extends StatelessWidget {
  final PaymentLinkModel link;
  const _LinkTile({required this.link});

  Color get _statusColor {
    switch (link.status) {
      case 'paid':    return AppColors.success;
      case 'expired': return AppColors.textMuted;
      default:        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(link.code, style: tt.titleSmall),
                const SizedBox(height: 3),
                Text(link.description ?? 'No description', style: tt.bodySmall),
                const SizedBox(height: 3),
                Text(DateFormat('MMM d, y').format(link.createdAt), style: tt.labelSmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₦${link.amount.toStringAsFixed(2)}', style: tt.titleMedium),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(link.status.toUpperCase(), style: TextStyle(color: _statusColor, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
