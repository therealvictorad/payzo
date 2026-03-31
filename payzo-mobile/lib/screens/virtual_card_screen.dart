import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/virtual_card.dart';
import '../providers/service_providers.dart';
import '../widgets/primary_button.dart';

class VirtualCardScreen extends ConsumerStatefulWidget {
  const VirtualCardScreen({super.key});

  @override
  ConsumerState<VirtualCardScreen> createState() => _VirtualCardScreenState();
}

class _VirtualCardScreenState extends ConsumerState<VirtualCardScreen> {
  List<VirtualCardModel> _cards = [];
  bool _loading  = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    setState(() => _loading = true);
    try {
      _cards = await ref.read(virtualCardServiceProvider).getCards();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createCard() async {
    setState(() => _creating = true);
    try {
      final card = await ref.read(virtualCardServiceProvider).createCard();
      setState(() => _cards.insert(0, card));
      if (mounted) _showNewCardSheet(card);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _showNewCardSheet(VirtualCardModel card) {
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
            Icon(Icons.credit_card_rounded, color: cs.primary, size: 48),
            const SizedBox(height: 12),
            Text('Card Created!', style: tt.titleLarge),
            const SizedBox(height: 6),
            Text('Save these details — CVV is shown only once.', style: tt.bodySmall?.copyWith(color: cs.error), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // Full card details shown once
            _DetailRow('Card Number', card.fullNumber ?? card.maskedNumber),
            _DetailRow('Expiry', card.expiry),
            _DetailRow('CVV', card.cvv ?? '***'),
            _DetailRow('Card Holder', card.cardHolder),
            _DetailRow('Brand', card.brand.toUpperCase()),
            _DetailRow('Spending Limit', '₦${card.spendingLimit.toStringAsFixed(2)}'),
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
                child: const Text('I\'ve saved my details', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Virtual Cards'),
          elevation: 0,
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: cs.primary))
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_cards.isEmpty) ...[
                      const Spacer(),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.credit_card_off_rounded, color: cs.onSurfaceVariant, size: 36),
                            ),
                            const SizedBox(height: 16),
                            Text('No virtual cards yet', style: tt.titleMedium),
                            const SizedBox(height: 6),
                            Text('Create one to start making online payments', style: tt.bodySmall, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ] else ...[
                      Text('Your Cards', style: tt.labelMedium?.copyWith(letterSpacing: 0.8)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _cards.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (_, i) => _CardWidget(card: _cards[i]),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    if (_cards.isEmpty || !_cards.any((c) => c.status == 'active'))
                      PrimaryButton(
                        label:     _creating ? 'Creating Card...' : 'Create Virtual Card',
                        isLoading: _creating,
                        onTap:     _creating ? null : _createCard,
                      ),
                  ],
                ),
              ),
      );
  }
}

class _CardWidget extends StatelessWidget {
  final VirtualCardModel card;
  const _CardWidget({required this.card});

  @override
  Widget build(BuildContext context) => Container(
        height: 190,
        decoration: BoxDecoration(
          gradient: card.brand == 'visa'
              ? const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : const LinearGradient(colors: [Color(0xFF1A0A0A), Color(0xFF2D1515)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (card.brand == 'visa' ? AppColors.primary : AppColors.error).withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              top: -30, right: -20,
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.brand.toUpperCase(),
                        style: TextStyle(
                          color: card.brand == 'visa' ? const Color(0xFF1A73E8) : const Color(0xFFEB001B),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      _StatusBadge(status: card.status),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    card.maskedNumber,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CARD HOLDER', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(card.cardHolder, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('EXPIRES', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(card.expiry, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'active':     return AppColors.success;
      case 'frozen':     return AppColors.warning;
      case 'terminated': return AppColors.error;
      default:           return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(color: _color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: tt.bodyMedium),
          Row(
            children: [
              Text(value, style: tt.titleSmall),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: value)),
                child: Icon(Icons.copy_rounded, color: cs.onSurfaceVariant, size: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
