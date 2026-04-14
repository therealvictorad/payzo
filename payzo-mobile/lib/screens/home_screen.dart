import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../animations/animations.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/kyc_banner.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/transaction_item.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(walletProvider.notifier).fetch(),
      ref.read(transactionProvider.notifier).fetchHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user       = ref.watch(authProvider).user;
    final walletAsync = ref.watch(walletProvider);
    final txState    = ref.watch(transactionProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs     = Theme.of(context).colorScheme;
    final size   = MediaQuery.sizeOf(context);
    final hPad   = size.width < 360 ? 14.0 : 20.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.surface, cs.surface, cs.surfaceContainerLow],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -size.height * 0.08,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.75,
                height: size.width * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cs.primary.withValues(alpha: isDark ? 0.13 : 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.15,
              left: -size.width * 0.25,
              child: Container(
                width: size.width * 0.65,
                height: size.width * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cs.secondary.withValues(alpha: isDark ? 0.08 : 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: RefreshIndicator(
                color: cs.primary,
                backgroundColor: cs.surfaceContainerHighest,
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    // ── Header ──────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _Header(
                        user: user,
                        hPad: hPad,
                        onAvatarTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                      ),
                    ),

                    // ── Balance Card ─────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                        child: walletAsync.when(
                          loading: () => const WalletCardSkeleton(),
                          error: (e, _) =>
                              _ErrorCard(message: e.toString(), onRetry: _loadData),
                          data: (wallet) => _BalanceCard(
                            wallet: wallet,
                            userName: user?.name ?? '',
                            onRecentActivity: () => Navigator.pushNamed(
                                context, AppRoutes.transactions),
                          ),
                        ),
                      ),
                    ),

                    // ── KYC Banner ───────────────────────────────────────────
                    if (user != null && user.kycStatus != 'verified')
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                          child: KycBanner(
                            kycStatus: user.kycStatus,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.kyc)
                                .then((_) => _loadData()),
                          ),
                        ),
                      ),

                    // ── Action Row ───────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _ActionRow(
                        hPad: hPad,
                        onToPayzo: () => Navigator.pushNamed(context, AppRoutes.send)
                            .then((_) => _loadData()),
                        onToBank: () => Navigator.pushNamed(context, AppRoutes.send)
                            .then((_) => _loadData()),
                        onWithdraw: () => Navigator.pushNamed(context, AppRoutes.topup)
                            .then((_) => _loadData()),
                      ),
                    ),

                    // ── Quick Actions ────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _QuickActionsSection(
                        hPad: hPad,
                        onSend: () => Navigator.pushNamed(context, AppRoutes.send)
                            .then((_) => _loadData()),
                        onHistory: () =>
                            Navigator.pushNamed(context, AppRoutes.transactions),
                        onTopup: () =>
                            Navigator.pushNamed(context, AppRoutes.topup)
                                .then((_) => _loadData()),
                        onBills: () =>
                            Navigator.pushNamed(context, AppRoutes.bills)
                                .then((_) => _loadData()),
                        onPaymentLinks: () =>
                            Navigator.pushNamed(context, AppRoutes.paymentLinks),
                      ),
                    ),

                    // ── Section Header ───────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        hPad: hPad,
                        title: 'Recent Activity',
                        actionLabel: 'See all',
                        onAction: () => Navigator.pushNamed(
                            context, AppRoutes.transactions),
                        count: txState.transactions.length,
                      ),
                    ),

                    // ── Transaction List ─────────────────────────────────────
                    if (txState.isLoading)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const TransactionItemSkeleton(),
                          childCount: 4,
                        ),
                      )
                    else if (txState.transactions.isEmpty)
                      const SliverToBoxAdapter(
                        child: FadeSlideIn(
                          child: _EmptyTransactions(),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => TransactionItem(
                            transaction: _recentTx(txState)[i],
                            currentUserId: user?.id ?? 0,
                            index: i,
                          ),
                          childCount: _recentTx(txState).length,
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

List<TransactionModel> _recentTx(TransactionState s) =>
    s.transactions.take(5).toList();

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final dynamic user;
  final double hPad;
  final VoidCallback onAvatarTap;

  const _Header({required this.user, required this.hPad, required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Avatar
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.40),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (user?.name ?? 'U').isNotEmpty
                            ? (user?.name ?? 'U')[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${(user?.name ?? 'there').split(' ').first} 👋',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Welcome back',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _IconBtn(
                icon: Icons.notifications_outlined,
                onTap: () => _showComingSoon(context, 'Notifications'),
              ),
              const SizedBox(width: 8),
              _IconBtn(
                icon: Icons.qr_code_scanner_outlined,
                onTap: () => _showComingSoon(context, 'QR Scanner'),
              ),
              const SizedBox(width: 8),
              _IconBtn(
                icon: Icons.headset_mic_outlined,
                onTap: () => _showComingSoon(context, 'Support'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Balance Card ─ animated count-up ─────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final dynamic wallet;
  final String userName;
  final VoidCallback onRecentActivity;

  const _BalanceCard({
    required this.wallet,
    required this.userName,
    required this.onRecentActivity,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7B6EF6), Color(0xFFAA5CF7), Color(0xFFD16BF0)],
            stops: [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -16,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'TOTAL BALANCE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CountUpText(
                  value: (wallet?.balance as num?)?.toDouble() ?? 0.0,
                  prefix: '\u20a6',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Available to spend',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    child: InkWell(
                      onTap: onRecentActivity,
                      splashColor: Colors.white.withValues(alpha: 0.18),
                      highlightColor: Colors.white.withValues(alpha: 0.08),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22), width: 0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                color: Colors.white, size: 13),
                            SizedBox(width: 6),
                            Text(
                              'Recent Activity',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white70, size: 9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

// ── Action Row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final VoidCallback onToPayzo;
  final VoidCallback onToBank;
  final VoidCallback onWithdraw;
  final double hPad;

  const _ActionRow({
    required this.onToPayzo,
    required this.onToBank,
    required this.onWithdraw,
    required this.hPad,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
        child: Row(
          children: [
            Expanded(child: _ActionCard(label: 'Send', icon: Icons.swap_horiz_rounded, onTap: onToPayzo)),
            const SizedBox(width: 8),
            Expanded(child: _ActionCard(label: 'Top Up', icon: Icons.account_balance_wallet_outlined, onTap: onToBank)),
            const SizedBox(width: 8),
            Expanded(child: _ActionCard(label: 'Withdraw', icon: Icons.download_rounded, onTap: onWithdraw)),
          ],
        ),
      );
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: cs.primary.withValues(alpha: 0.10),
        highlightColor: cs.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withValues(alpha: 0.18),
                      cs.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: cs.primary, size: 21),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onSend;
  final VoidCallback onHistory;
  final VoidCallback onTopup;
  final VoidCallback onBills;
  final VoidCallback onPaymentLinks;
  final double hPad;

  const _QuickActionsSection({
    required this.onSend,
    required this.onHistory,
    required this.onTopup,
    required this.onBills,
    required this.onPaymentLinks,
    required this.hPad,
  });

  @override
  Widget build(BuildContext context) {
    // 2×2 grid data — same 4 actions, same callbacks
    final actions = [
      _ActionData(
        icon: Icons.send_rounded,
        label: 'Send',
        sublabel: 'Instant',
        gradient: AppColors.cardGradient,
        glowColor: AppColors.primary,
        onTap: onSend,
      ),
      _ActionData(
        icon: Icons.phone_android_rounded,
        label: 'Top-up',
        sublabel: 'Airtime',
        gradient: const LinearGradient(
          colors: [Color(0xFFFFCC00), Color(0xFFFF9500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        glowColor: const Color(0xFFFFCC00),
        onTap: onTopup,
      ),
      _ActionData(
        icon: Icons.receipt_rounded,
        label: 'Bills',
        sublabel: 'Pay bills',
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        glowColor: const Color(0xFFFF6B6B),
        onTap: onBills,
      ),
      _ActionData(
        icon: Icons.link_rounded,
        label: 'Pay Link',
        sublabel: 'Share',
        gradient: AppColors.accentGradient,
        glowColor: AppColors.accent,
        onTap: onPaymentLinks,
      ),
      _ActionData(
        icon: Icons.receipt_long_rounded,
        label: 'History',
        sublabel: 'All time',
        gradient: const LinearGradient(
          colors: [Color(0xFF9B59B6), Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        glowColor: const Color(0xFF9B59B6),
        onTap: onHistory,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTag(label: 'QUICK ACTIONS'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
            children: List.generate(
              actions.length,
              (i) => QuickActionCard(
                icon: actions[i].icon,
                label: actions[i].label,
                sublabel: actions[i].sublabel,
                gradient: actions[i].gradient,
                glowColor: actions[i].glowColor,
                onTap: actions[i].onTap,
                staggerIndex: i,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple data holder — no widget overhead
class _ActionData {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Gradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _ActionData({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
    this.sublabel,
  });
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final int count;
  final double hPad;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.count,
    required this.hPad,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(20),
              splashColor: cs.primary.withValues(alpha: 0.10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Tag ───────────────────────────────────────────────────────────────

class _SectionTag extends StatelessWidget {
  final String label;
  const _SectionTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature — coming soon'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

// ── Icon Button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer,
      shape: const CircleBorder(),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: cs.primary.withValues(alpha: 0.15),
        highlightColor: cs.primary.withValues(alpha: 0.08),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: cs.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.15),
                  cs.primary.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.12),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: cs.primary.withValues(alpha: 0.7),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Send money or top up to get started',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: cs.error.withValues(alpha: 0.18),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: cs.error,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                backgroundColor: cs.error.withValues(alpha: 0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: cs.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
  }
}


