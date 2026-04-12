import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Shown on HomeScreen when user is not KYC verified.
/// Tapping it navigates to KycScreen.
class KycBanner extends StatelessWidget {
  final String kycStatus; // none | pending | rejected
  final VoidCallback onTap;

  const KycBanner({super.key, required this.kycStatus, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final config = switch (kycStatus) {
      'pending'  => (
          color: const Color(0xFFCA8A04),
          bg:    const Color(0xFFFEF9C3),
          icon:  Icons.hourglass_top_rounded,
          title: 'Verification Pending',
          sub:   'Your documents are under review.',
          cta:   'View Status',
        ),
      'rejected' => (
          color: cs.error,
          bg:    cs.error.withOpacity(0.08),
          icon:  Icons.cancel_outlined,
          title: 'Verification Rejected',
          sub:   'Tap to resubmit your documents.',
          cta:   'Resubmit',
        ),
      _ => (
          color: AppColors.primary,
          bg:    AppColors.primary.withOpacity(0.07),
          icon:  Icons.verified_user_outlined,
          title: 'Verify Your Account',
          sub:   'Unlock higher transaction limits.',
          cta:   'Verify Now',
        ),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:        config.bg,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: config.color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color:        config.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(config.icon, color: config.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(config.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: config.color,
                      )),
                  Text(config.sub,
                      style: TextStyle(
                        fontSize: 11,
                        color: config.color.withOpacity(0.75),
                      )),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:        config.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                config.cta,
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
