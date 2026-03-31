import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../animations/animations.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
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
    final auth = ref.watch(authProvider);
    final walletAsync = ref.watch(walletProvider);
    final txState = ref.watch(transactionProvider);
    final user = auth.user;

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
                      cs.primary.withOpacity(isDark ? 0.13 : 0.07),
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
                      cs.secondary.withOpacity(isDark ? 0.08 : 0.05),
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
                        onCards: () =>
                            Navigator.pushNamed(context, AppRoutes.virtualCards),
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
                      SliverToBoxAdapter(
                        child: FadeSlideIn(
                          child: _EmptyTransactions(),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => TransactionItem(
                            transaction: txState.transactions[i],
                            currentUserId: user?.id ?? 0,
                            index: i,
                          ),
                          childCount: txState.transactions.take(5).length,
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

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LogoutSheet(
        onLogout: () async {
          Navigator.pop(context);
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        },
      ),
    );
  }
}

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
                          color: cs.primary.withOpacity(0.40),
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
                    'Hi, Victor 👋',
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
              _IconBtn(icon: Icons.notifications_outlined, onTap: () {}, badge: true),
              const SizedBox(width: 8),
              _IconBtn(icon: Icons.qr_code_scanner_outlined, onTap: () {}),
              const SizedBox(width: 8),
              _IconBtn(icon: Icons.headset_mic_outlined, onTap: () {}),
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
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7B6EF6), Color(0xFFAA5CF7), Color(0xFFD16BF0)],
            stops: [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.45),
              blurRadius: 36,
              spreadRadius: -6,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: const Color(0xFFD16BF0).withOpacity(0.20),
              blurRadius: 60,
              spreadRadius: -10,
              offset: const Offset(0, 28),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle top-right
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              right: 40,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'TOTAL BALANCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CountUpText(
                  value: (wallet?.balance as num?)?.toDouble() ?? 0.0,
                  prefix: '₦',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Available to spend',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Material(
                    color: Colors.white.withOpacity(0.14),
                    child: InkWell(
                      onTap: onRecentActivity,
                      splashColor: Colors.white.withOpacity(0.18),
                      highlightColor: Colors.white.withOpacity(0.08),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.22), width: 0.8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, color: Colors.white, size: 15),
                            SizedBox(width: 8),
                            Text(
                              'Recent Activity',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 10),
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
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
        child: Row(
          children: [
            Expanded(child: _ActionCard(label: 'To Payzo', icon: Icons.swap_horiz_rounded, onTap: onToPayzo)),
            const SizedBox(width: 10),
            Expanded(child: _ActionCard(label: 'To Bank', icon: Icons.account_balance_outlined, onTap: onToBank)),
            const SizedBox(width: 10),
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
        splashColor: cs.primary.withOpacity(0.10),
        highlightColor: cs.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
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
                      cs.primary.withOpacity(0.18),
                      cs.primary.withOpacity(0.08),
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
  final VoidCallback onCards;
  final double hPad;

  const _QuickActionsSection({
    required this.onSend,
    required this.onHistory,
    required this.onTopup,
    required this.onBills,
    required this.onPaymentLinks,
    required this.onCards,
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
        icon: Icons.credit_card_rounded,
        label: 'Cards',
        sublabel: 'Virtual',
        gradient: const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        glowColor: const Color(0xFF4ECDC4),
        onTap: onCards,
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
      padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTag(label: 'QUICK ACTIONS'),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
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
              splashColor: cs.primary.withOpacity(0.10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.10),
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

// ── Icon Button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: cs.surfaceContainer,
          shape: const CircleBorder(),
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            splashColor: cs.primary.withOpacity(0.15),
            highlightColor: cs.primary.withOpacity(0.08),
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
        ),
        if (badge)
          Positioned(
            top: 8,
            right: 8,
            child: PulseGlow(
              color: cs.error,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: cs.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.surface,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyTransactions extends StatelessWidget {
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
                  cs.primary.withOpacity(0.15),
                  cs.primary.withOpacity(0.06),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.12),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: cs.primary.withOpacity(0.7),
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
          color: cs.error.withOpacity(0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: cs.error.withOpacity(0.18),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.1),
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
                backgroundColor: cs.error.withOpacity(0.1),
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

// ── Logout Sheet ──────────────────────────────────────────────────────────────

class _LogoutSheet extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutSheet({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: cs.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Sign Out',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to sign out\nof your Payzo account?',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: cs.outlineVariant,
                        width: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(0, 54),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                      minimumSize: const Size(0, 54),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
}
