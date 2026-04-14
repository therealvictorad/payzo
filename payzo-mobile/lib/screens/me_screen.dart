import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/service_providers.dart';
import '../providers/wallet_provider.dart';
import '../widgets/pin_entry_sheet.dart';

class MeScreen extends ConsumerStatefulWidget {
  const MeScreen({super.key});

  @override
  ConsumerState<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends ConsumerState<MeScreen> {
  String? _avatarPath;
  static const _avatarKey = 'profile_avatar_path';

  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).fetch();
    });
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path  = prefs.getString(_avatarKey);
    if (path != null && File(path).existsSync() && mounted) {
      setState(() => _avatarPath = path);
    }
  }

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarSourceSheet(
        onSource: (source) async {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          final picked = await ImagePicker().pickImage(
            source: source, imageQuality: 80, maxWidth: 512,
          );
          if (picked == null || !mounted) return;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_avatarKey, picked.path);
          setState(() => _avatarPath = picked.path);
        },
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LogoutSheet(
        onLogout: () => _performLogout(context),
      ),
    );
  }

  /// Single reusable logout function — works for both authenticated
  /// and guest users. Clears auth state (no-op for guests since there
  /// is no session), then wipes the entire navigation stack and lands
  /// on the auth screen so back-button can never return to the shell.
  Future<void> _performLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();

    final isAuthenticated = ref.read(authProvider).user != null;
    if (isAuthenticated) {
      await ref.read(authProvider.notifier).logout();
    } else {
      ref.read(authProvider.notifier).clearError();
    }

    if (!mounted) return;

    navigator.pushNamedAndRemoveUntil(
      AppRoutes.auth,
      (route) => false,
    );
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _showChangePinSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChangePinSheet(
        onSave: (pin, confirm) async {
          try {
            await ref.read(transactionServiceProvider).setPin(pin, confirm);
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Transaction PIN updated successfully.')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs          = Theme.of(context).colorScheme;
    final user        = ref.watch(authProvider).user;
    final walletAsync = ref.watch(walletProvider);
    final name        = user?.name ?? 'User';
    final email       = user?.email ?? '';
    final firstName   = name.split(' ').first;
    final initials    = name.trim().split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header card ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 2),
                            ),
                            child: _avatarPath != null
                                ? ClipOval(
                                    child: Image.file(File(_avatarPath!),
                                        fit: BoxFit.cover))
                                : Center(
                                    child: Text(
                                      initials.isNotEmpty ? initials : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary, width: 1.5),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 11, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hi, $firstName 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              )),
                          const SizedBox(height: 2),
                          Text(email,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 10),
                          Text('Total Balance',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              )),
                          walletAsync.when(
                            loading: () => const SizedBox(
                              height: 20,
                              child: LinearProgressIndicator(
                                  backgroundColor: Colors.white24,
                                  color: Colors.white),
                            ),
                            error: (_, __) => const Text('—',
                                style: TextStyle(color: Colors.white)),
                            data: (w) => Text(
                              '₦${w.balance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Security ──────────────────────────────────────────────
              const _SectionLabel(label: 'SECURITY'),
              const SizedBox(height: 10),
              _NavTile(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: _showChangePasswordSheet,
              ),
              _NavTile(
                icon: Icons.pin_outlined,
                label: 'Transaction PIN',
                onTap: _showChangePinSheet,
              ),
              _NavTileTrailing(
                icon: Icons.fingerprint_rounded,
                label: 'Biometric Login',
                trailing: 'Coming soon',
                onTap: () => _showComingSoon('Biometric Login'),
              ),
              _NavTileTrailing(
                icon: Icons.verified_user_outlined,
                label: 'Two-Factor Authentication',
                trailing: 'Coming soon',
                onTap: () => _showComingSoon('Two-Factor Authentication'),
              ),

              const SizedBox(height: 28),

              // ── Preferences ───────────────────────────────────────────
              const _SectionLabel(label: 'PREFERENCES'),
              const SizedBox(height: 10),
              _ToggleTile(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                value: ref.watch(themeModeProvider) == ThemeMode.dark,
                onChanged: (v) => ref
                    .read(themeModeProvider.notifier)
                    .setMode(v ? ThemeMode.dark : ThemeMode.light),
              ),
              _ToggleTile(
                icon: Icons.notifications_outlined,
                label: 'Push Notifications',
                value: _notificationsEnabled,
                onChanged: (v) =>
                    setState(() => _notificationsEnabled = v),
              ),
              _NavTile(
                icon: Icons.language_outlined,
                label: 'Language',
                onTap: () => _showComingSoon('Language'),
              ),
              _NavTileTrailing(
                icon: Icons.currency_exchange_rounded,
                label: 'Default Currency',
                trailing: 'NGN',
                onTap: () => _showComingSoon('Default Currency'),
              ),

              const SizedBox(height: 28),

              // ── Identity Verification ─────────────────────────────────────────────────────────────────────────────────
              const _SectionLabel(label: 'IDENTITY VERIFICATION'),
              const SizedBox(height: 10),
              _KycTile(
                kycStatus: user?.kycStatus ?? 'none',
                kycLevel:  user?.kycLevel  ?? 'tier0',
                onTap: () => Navigator.pushNamed(context, AppRoutes.kyc),
              ),

              const SizedBox(height: 28),

              // ── Support & Legal ───────────────────────────────────────
              const _SectionLabel(label: 'SUPPORT & LEGAL'),
              const SizedBox(height: 10),
              _NavTile(
                icon: Icons.help_outline_rounded,
                label: 'Help Center',
                onTap: () => _showComingSoon('Help Center'),
              ),
              _NavTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Contact Support',
                onTap: () => _showComingSoon('Contact Support'),
              ),
              _NavTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () => _showComingSoon('Privacy Policy'),
              ),
              _NavTile(
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                onTap: () => _showComingSoon('Terms of Service'),
              ),
              _NavTileTrailing(
                icon: Icons.info_outline_rounded,
                label: 'App Version',
                trailing: '1.0.0',
                onTap: () {},
              ),

              const SizedBox(height: 28),

              // ── Sign Out ─────────────────────────────────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutSheet(context),
                  icon: Icon(Icons.logout_rounded,
                      size: 18, color: cs.error),
                  label: Text('Sign Out',
                      style: TextStyle(
                          color: cs.error,
                          fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    side: BorderSide(
                        color: cs.error.withValues(alpha: 0.4), width: 0.8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5), letterSpacing: 1.2)),
      ],
    );
  }
}

// ── Nav Tile ──────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _TileIcon(icon: icon),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(label,
                        style: tt.titleSmall
                            ?.copyWith(color: cs.onSurface))),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurface.withValues(alpha: 0.3), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Tile with trailing ────────────────────────────────────────────────────

class _NavTileTrailing extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback onTap;
  const _NavTileTrailing(
      {required this.icon,
      required this.label,
      required this.trailing,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _TileIcon(icon: icon),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(label,
                        style: tt.titleSmall
                            ?.copyWith(color: cs.onSurface))),
                Text(trailing,
                    style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurface.withValues(alpha: 0.3), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Toggle Tile ───────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TileIcon(icon: icon),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: tt.titleSmall?.copyWith(color: cs.onSurface))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Tile Icon ─────────────────────────────────────────────────────────────────

class _TileIcon extends StatelessWidget {
  final IconData icon;
  const _TileIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: cs.primary, size: 18),
    );
  }
}

// ── Avatar Source Sheet ───────────────────────────────────────────────────────

class _AvatarSourceSheet extends StatelessWidget {
  final void Function(ImageSource) onSource;
  const _AvatarSourceSheet({required this.onSource});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Text('Update Profile Photo', style: tt.titleMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => onSource(ImageSource.camera)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => onSource(ImageSource.gallery)),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: cs.primary, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: tt.labelLarge?.copyWith(color: cs.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── KYC Tile ─────────────────────────────────────────────────────────────────

class _KycTile extends StatelessWidget {
  final String kycStatus;
  final String kycLevel;
  final VoidCallback onTap;
  const _KycTile(
      {required this.kycStatus,
      required this.kycLevel,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final config = switch (kycStatus) {
      'verified' => (
          color: AppColors.success,
          bg:    AppColors.success.withValues(alpha: 0.08),
          icon:  Icons.verified_user_rounded,
          label: 'Verified — ${kycLevel.toUpperCase()}',
          sub:   'Your identity has been verified.',
          cta:   'View',
        ),
      'pending' => (
          color: AppColors.warning,
          bg:    AppColors.warning.withValues(alpha: 0.08),
          icon:  Icons.hourglass_top_rounded,
          label: 'Verification Pending',
          sub:   'Your documents are under review.',
          cta:   'View Status',
        ),
      'rejected' => (
          color: cs.error,
          bg:    cs.error.withValues(alpha: 0.08),
          icon:  Icons.cancel_outlined,
          label: 'Verification Rejected',
          sub:   'Tap to resubmit your documents.',
          cta:   'Resubmit',
        ),
      _ => (
          color: AppColors.primary,
          bg:    AppColors.primary.withValues(alpha: 0.07),
          icon:  Icons.shield_outlined,
          label: 'Verify Your Identity',
          sub:   'Unlock higher transaction limits.',
          cta:   'Start',
        ),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: config.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: config.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: config.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(config.icon, color: config.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(config.label,
                      style: tt.titleSmall?.copyWith(
                          color: config.color,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(config.sub,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: config.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(config.cta,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl   = TextEditingController();
  final _newCtrl       = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _loading        = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    if (newPass.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters.');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    // TODO: wire to AuthService.changePassword(current, newPass) when endpoint is ready
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password change — coming soon'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Change Password', style: tt.titleLarge),
            const SizedBox(height: 20),
            _PasswordField(
                controller: _currentCtrl,
                label: 'Current Password',
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent)),
            const SizedBox(height: 12),
            _PasswordField(
                controller: _newCtrl,
                label: 'New Password',
                obscure: _obscureNew,
                onToggle: () =>
                    setState(() => _obscureNew = !_obscureNew)),
            const SizedBox(height: 12),
            _PasswordField(
                controller: _confirmCtrl,
                label: 'Confirm New Password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm)),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Update Password',
                        style: tt.labelLarge?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  const _PasswordField(
      {required this.controller,
      required this.label,
      required this.obscure,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: cs.onSurface.withValues(alpha: 0.4),
            size: 18,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ── Change PIN Sheet ──────────────────────────────────────────────────────────

class _ChangePinSheet extends StatefulWidget {
  final Future<void> Function(String pin, String confirm) onSave;
  const _ChangePinSheet({required this.onSave});

  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  bool    _loading = false;
  String? _error;

  Future<void> _handleSetPin() async {
    final newPin = await PinEntrySheet.show(
      context,
      title:    'Set New PIN',
      subtitle: 'Enter a 4-digit transaction PIN.',
    );
    if (newPin == null || !mounted) return;

    final confirmPin = await PinEntrySheet.show(
      context,
      title:    'Confirm New PIN',
      subtitle: 'Re-enter your new PIN to confirm.',
    );
    if (confirmPin == null || !mounted) return;

    if (newPin != confirmPin) {
      setState(() => _error = 'PINs do not match. Please try again.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await widget.onSave(newPin, confirmPin);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 32 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 28),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pin_outlined, color: cs.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text('Transaction PIN', style: tt.titleLarge),
          const SizedBox(height: 8),
          Text('Your PIN is required before every transfer.',
              style: tt.bodySmall, textAlign: TextAlign.center),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!,
                  style: tt.bodySmall?.copyWith(color: cs.error),
                  textAlign: TextAlign.center),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleSetPin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Set PIN',
                      style: tt.labelLarge?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w700)),
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
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 28),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.logout_rounded, color: cs.error, size: 28),
          ),
          const SizedBox(height: 18),
          Text('Sign Out', style: tt.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Are you sure you want to sign out\nof your Payzo account?',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.outlineVariant, width: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size(0, 54),
                  ),
                  child: Text('Cancel',
                      style: tt.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
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
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Sign Out',
                      style: tt.labelLarge?.copyWith(
                          color: cs.onError,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
