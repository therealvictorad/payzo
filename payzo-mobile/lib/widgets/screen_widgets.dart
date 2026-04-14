import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Small uppercase section label used across feature screens.
class ScreenSectionLabel extends StatelessWidget {
  final String text;
  const ScreenSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelMedium,
      );
}

/// Bottom sheet result (success or error) used across feature screens.
class ResultSheet extends StatelessWidget {
  final bool success;
  final String title;
  final String message;
  final VoidCallback onDone;

  const ResultSheet({
    super.key,
    required this.success,
    required this.title,
    required this.message,
    required this.onDone,
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
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: (success ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_rounded : Icons.close_rounded,
                color: success ? AppColors.success : AppColors.error,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(title, style: tt.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              style: tt.bodyMedium?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: success ? AppColors.success : cs.primary,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      );
  }
}
