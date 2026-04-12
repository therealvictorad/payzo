import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

// ── Public reusable widget ────────────────────────────────────────────────────

class QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? sublabel;       // optional descriptor e.g. "Instant"
  final Gradient gradient;
  final Color glowColor;
  final VoidCallback onTap;
  final int staggerIndex;       // controls entrance delay

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
    this.sublabel,
    this.staggerIndex = 0,
  });

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard>
    with TickerProviderStateMixin {
  // ── Press animation ───────────────────────────────────────────────────────
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  // ── Icon bounce on tap ────────────────────────────────────────────────────
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconRotate;

  // ── Entrance animation ────────────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entranceSlide;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Press
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );

    // Icon bounce
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 0.75, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
    ]).animate(_iconCtrl);
    _iconRotate = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.easeInOut),
    );

    // Entrance — stagger by index
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entranceOpacity = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    Future.delayed(
      Duration(milliseconds: 240 + (widget.staggerIndex * 70)),
      () { if (mounted) _entranceCtrl.forward(); },
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _iconCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _pressCtrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _pressCtrl.reverse();
    _iconCtrl
      ..reset()
      ..forward();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _entranceOpacity,
        child: SlideTransition(
          position: _entranceSlide,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, child) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      // Press glow only — ambient shadow lives in _CardBody
                      BoxShadow(
                        color: widget.glowColor
                            .withOpacity(0.45 * _glowAnim.value),
                        blurRadius: 24,
                        spreadRadius: -4,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: _CardBody(
                  icon: widget.icon,
                  label: widget.label,
                  sublabel: widget.sublabel,
                  gradient: widget.gradient,
                  glowColor: widget.glowColor,
                  iconScale: _iconScale,
                  iconRotate: _iconRotate,
                  isPressed: _isPressed,
                ),
              ),
            ),
          ),
        ),
      );
}

// ── Card body (separated to avoid rebuilding the whole tree) ──────────────────

class _CardBody extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Gradient gradient;
  final Color glowColor;
  final Animation<double> iconScale;
  final Animation<double> iconRotate;
  final bool isPressed;

  const _CardBody({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.glowColor,
    required this.iconScale,
    required this.iconRotate,
    required this.isPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Icon container with gradient ──────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([iconScale, iconRotate]),
              builder: (_, __) => Transform.scale(
                scale: iconScale.value,
                child: Transform.rotate(
                  angle: iconRotate.value,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withOpacity(isDark ? 0.3 : 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Label ─────────────────────────────────────────────────
            Text(
              label,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),

            if (sublabel != null) ...[
              const SizedBox(height: 1),
              Text(
                sublabel!,
                style: TextStyle(
                  color: glowColor.withOpacity(isDark ? 0.8 : 0.65),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
