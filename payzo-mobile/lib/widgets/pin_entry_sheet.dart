import 'package:flutter/material.dart';

/// A 4-digit PIN entry bottom sheet.
/// Usage:
///   final pin = await PinEntrySheet.show(context, title: 'Enter PIN');
///   if (pin != null) { /* proceed */ }
class PinEntrySheet extends StatefulWidget {
  final String title;
  final String? subtitle;

  const PinEntrySheet({super.key, required this.title, this.subtitle});

  static Future<String?> show(
    BuildContext context, {
    String title = 'Enter Transaction PIN',
    String? subtitle,
  }) {
    return showModalBottomSheet<String>(
      context:          context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PinEntrySheet(title: title, subtitle: subtitle),
    );
  }

  @override
  State<PinEntrySheet> createState() => _PinEntrySheetState();
}

class _PinEntrySheetState extends State<PinEntrySheet> {
  final List<String> _digits = [];

  void _onKey(String digit) {
    if (_digits.length >= 4) return;
    setState(() => _digits.add(digit));
    if (_digits.length == 4) {
      // Small delay so user sees the 4th dot fill before sheet closes
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) Navigator.pop(context, _digits.join());
      });
    }
  }

  void _onDelete() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color:        cs.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color:        cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          Text(widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 6),
            Text(widget.subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 32),

          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _digits.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin:   const EdgeInsets.symmetric(horizontal: 10),
                width:    18, height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: filled ? cs.primary : cs.outline,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 36),

          // Keypad
          _Keypad(onKey: _onKey, onDelete: _onDelete),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onDelete;

  const _Keypad({required this.onKey, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 80, height: 64);
            if (k == 'del') {
              return _KeyButton(
              onTap: onDelete,
              child: const Icon(Icons.backspace_outlined, size: 22),
            );
            }
            return _KeyButton(
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600)),
              onTap: () => onKey(k),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _KeyButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color:        cs.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 80, height: 64,
          child: Center(child: child),
        ),
      ),
    );
  }
}
