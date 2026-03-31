import 'package:flutter/material.dart';
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

  String get _counterpartyName => _isSent
      ? (transaction.receiver?.name ?? 'Unknown')
      : (transaction.sender?.name ?? 'Unknown');

  String get _initials {
    final parts = _counterpartyName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _counterpartyName.isNotEmpty
        ? _counterpartyName[0].toUpperCase()
        : '?';
  }

  Color get _accentColor => _isSent ? AppColors.error : AppColors.success;

  // Unique avatar color derived from name
  Color get _avatarColor {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00D4AA),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB347),
      const Color(0xFF4ECDC4),
      const Color(0xFFFF8E53),
      const Color(0xFF9B59B6),
      const Color(0xFF3498DB),
    ];
    final index = _counterpartyName.codeUnits.fold(0, (a, b) => a + b);
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) => StaggeredItem(
        index: index,
        child: PressScaleWidget(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
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
                    // ── Colored left accent bar ──────────────────────────
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

                    // ── Content ──────────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            // Avatar with initials
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _avatarColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _avatarColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _initials,
                                  style: TextStyle(
                                    color: _avatarColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 13),

                            // Name + date
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
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        _isSent
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded,
                                        size: 11,
                                        color: _accentColor.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        DateFormat('MMM d, h:mm a').format(
                                            transaction.createdAt.toLocal()),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
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
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isSuccess = status.toLowerCase() == 'success';
    final color = isSuccess ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
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
