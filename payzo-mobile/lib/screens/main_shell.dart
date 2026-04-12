import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'me_screen.dart';
import 'virtual_card_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    VirtualCardScreen(),
    MeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withOpacity(0.5), width: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  _NavItem(
                    icon:     Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label:    'Home',
                    active:   _currentIndex == 0,
                    onTap:    () => setState(() => _currentIndex = 0),
                  ),
                  _NavItem(
                    icon:     Icons.credit_card_outlined,
                    activeIcon: Icons.credit_card_rounded,
                    label:    'Cards',
                    active:   _currentIndex == 1,
                    onTap:    () => setState(() => _currentIndex = 1),
                  ),
                  _NavItem(
                    icon:     Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label:    'Me',
                    active:   _currentIndex == 2,
                    onTap:    () => setState(() => _currentIndex = 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: active ? cs.primary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                active ? activeIcon : icon,
                color: active ? cs.primary : cs.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize:   10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color:      active ? cs.primary : cs.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
