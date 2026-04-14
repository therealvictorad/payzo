import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../animations/animations.dart';
import '../core/currency.dart';
import '../core/theme.dart';
import '../models/transaction.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final int currentUserId;
  final int index;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.currentUserId,
    required this.index,
  });

  bool get _isSent => transaction.senderId == currentUserId;

  String get _counterpartyName {
    switch (transaction.type) {
      case 'airtime': return 'Airtime Top-up';
      case 'bill':    return transaction.meta?['provider'] ?? 'Bill Payment';
      case 'payment_link': return _isSent
          ? (transaction.receiver?.name ?? 'Payment Link')
          : (transaction.sender?.name ?? 'Payment Link');
      default: return _isSent
          ? (transaction.receiver?.name ?? 'Unknown')
          : (transaction.sender?.name ?? 'Unknown');
    }
  }

  String get _initials {
    final parts = _counterpartyName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _counterpartyName.isNotEmpty ? _counterpartyName[0].toUpperCase() : '?';
  }

  Color get _accentColor {
    if (transaction.status == 'reversed') return AppColors.warning;
    return _isSent ? AppColors.error : AppColors.success;
  }

  Color get _avatarColor {
    final colors = [
      const Color(0xFF6C63FF), const Color(0xFF00D4AA),
      const Color(0xFFFF6B6B), const Color(0xFFFFB347),
      const Color(0xFF4ECDC4), const Color(0xFFFF8E53),
      const Color(0xFF9B59B6), const Color(0xFF3498DB),
    ];
    final idx = _counterpartyName.codeUnits.fold(0, (a, b) => a + b);
    return colors[idx % colors.length];
  }

  IconData get _typeIcon {
    switch (transaction.type) {
      case 'airtime':      return Icons.phone_android_rounded;
      case 'bill':         return Icons.receipt_rounded;
      case 'payment_link': return Icons.link_rounded;
      default:             return _isSent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => StaggeredItem(
        index: index,
        child: PressScaleWidget(
          onTap: () => _showDetail(context),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Colored left accent bar
                    Container(
                      width: 3.5,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: _avatarColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _avatarColor.withValues(alpha: 0.3),
                                    width: 1),
                              ),
                              child: Center(
                                child: Text(_initials,
                                    style: TextStyle(
                                      color: _avatarColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    )),
                              ),
                            ),
                            const SizedBox(width: 13),

                            // Name + date + reference
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _counterpartyName,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(_typeIcon, size: 11,
                                          color: _accentColor.withValues(alpha: 0.8)),
                                      const SizedBox(width: 3),
                                      Text(
                                        DateFormat('MMM d, h:mm a')
                                            .format(transaction.createdAt.toLocal()),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 11,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Reference number
                                  if (transaction.reference != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      transaction.reference!,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.55),
                                        fontSize: 9.5,
                                        letterSpacing: 0.3,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Amount + status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${_isSent ? '−' : '+'}${formatNaira(transaction.amount)}',
                                  style: TextStyle(
                                    color: _accentColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                _StatusPill(status: transaction.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TransactionDetailSheet(
        transaction: transaction,
        isSent: _isSent,
        counterpartyName: _counterpartyName,
        accentColor: _accentColor,
      ),
    );
  }
}

// ── Transaction Detail Sheet ──────────────────────────────────────────────────

class _TransactionDetailSheet extends StatelessWidget {
  final TransactionModel transaction;
  final bool isSent;
  final String counterpartyName;
  final Color accentColor;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.isSent,
    required this.counterpartyName,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Amount
          Text(
            '${isSent ? '−' : '+'}${formatNaira(transaction.amount)}',
            style: TextStyle(
              color: accentColor,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          _StatusPill(status: transaction.status),
          const SizedBox(height: 24),

          // Details
          _DetailRow(label: 'Type',   value: transaction.type.replaceAll('_', ' ').toUpperCase()),
          _DetailRow(label: isSent ? 'To' : 'From', value: counterpartyName),
          _DetailRow(
            label: 'Date',
            value: DateFormat('MMM d, yyyy • h:mm a')
                .format(transaction.createdAt.toLocal()),
          ),
          if (transaction.reference != null)
            _DetailRow(
              label: 'Reference',
              value: transaction.reference!,
              copyable: true,
            ),
          if (transaction.meta != null) ...[
            if (transaction.meta!['phone_number'] != null)
              _DetailRow(label: 'Phone', value: transaction.meta!['phone_number']),
            if (transaction.meta!['network'] != null)
              _DetailRow(label: 'Network', value: transaction.meta!['network']),
            if (transaction.meta!['provider'] != null)
              _DetailRow(label: 'Provider', value: transaction.meta!['provider']),
            if (transaction.meta!['customer_id'] != null)
              _DetailRow(label: 'Customer ID', value: transaction.meta!['customer_id']),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Text('Close',
                  style: tt.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;

  const _DetailRow({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant)),
          Row(
            children: [
              Text(value,
                  style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600)),
              if (copyable) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reference copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Icon(Icons.copy_rounded,
                      size: 14, color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status Pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  Color _color(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'success':    return AppColors.success;
      case 'reversed':   return AppColors.warning;
      case 'pending':
      case 'processing': return AppColors.primary;
      default:           return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
