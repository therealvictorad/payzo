import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../providers/service_providers.dart';
import '../widgets/pin_entry_sheet.dart';

/// Shown after first login when the user has no transaction PIN set.
/// Can be skipped — they'll be prompted again on first transfer.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handleSetup() async {
    // Step 1 — enter PIN
    final pin = await PinEntrySheet.show(
      context,
      title:    'Create Transaction PIN',
      subtitle: 'This PIN protects every transfer you make.',
    );
    if (pin == null || !mounted) return;

    // Step 2 — confirm PIN
    final confirm = await PinEntrySheet.show(
      context,
      title:    'Confirm Your PIN',
      subtitle: 'Re-enter the same 4-digit PIN.',
    );
    if (confirm == null || !mounted) return;

    if (pin != confirm) {
      setState(() => _error = 'PINs do not match. Please try again.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(transactionServiceProvider).setPin(pin, confirm);
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.shell);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 32),

              Text('Secure Your Account',
                  style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 12),
              Text(
                'Set a 4-digit transaction PIN.\nYou\'ll need it every time you send money.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),

              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: cs.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: tt.bodySmall?.copyWith(color: cs.error)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Set PIN button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleSetup,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Set Transaction PIN',
                          style: tt.labelLarge?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                ),
              ),

              const SizedBox(height: 16),

              // Skip
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.shell),
                child: Text(
                  'Skip for now',
                  style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
