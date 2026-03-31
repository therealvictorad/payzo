import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  String? _avatarPath;

  static const _avatarKey = 'profile_avatar_path';

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_avatarKey);
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
          // Wait for sheet to fully dismiss before launching picker
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          final picked = await ImagePicker().pickImage(
            source: source,
            imageQuality: 80,
            maxWidth: 512,
          );
          if (picked == null || !mounted) return;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_avatarKey, picked.path);
          setState(() => _avatarPath = picked.path);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? 'User';
    final email = user?.email ?? '';
    final initials = name.trim().split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profile', style: tt.titleLarge),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar + Info ──────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: _avatarPath == null ? AppColors.cardGradient : null,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withOpacity(0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: _avatarPath != null
                                ? ClipOval(
                                    child: Image.file(
                                      File(_avatarPath!),
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      initials.isNotEmpty ? initials : 'U',
                                      style: tt.headlineMedium?.copyWith(
                                        color: cs.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: cs.surface, width: 2),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: cs.onPrimary,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(name,
                        style: tt.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(email, style: tt.bodyMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Verified ✓',
                          style: tt.labelMedium?.copyWith(color: AppColors.success)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Account ────────────────────────────────────────────────
              _SectionLabel(label: 'ACCOUNT'),
              const SizedBox(height: 10),
              _InfoTile(icon: Icons.person_outline_rounded, label: 'Full Name', value: name),
              _InfoTile(icon: Icons.email_outlined, label: 'Email', value: email),

              const SizedBox(height: 28),

              // ── Security ───────────────────────────────────────────────
              _SectionLabel(label: 'SECURITY'),
              const SizedBox(height: 10),
              _NavTile(icon: Icons.lock_outline_rounded, label: 'Change Password',
                  onTap: () => _showChangePasswordSheet(context)),
              _NavTile(icon: Icons.pin_outlined, label: 'Change PIN',
                  onTap: () => _showChangePinSheet(context)),
              _ToggleTile(icon: Icons.fingerprint_rounded, label: 'Biometric Login',
                  value: _biometricEnabled,
                  onChanged: (v) => setState(() => _biometricEnabled = v)),
              _ToggleTile(icon: Icons.verified_user_outlined, label: 'Two-Factor Authentication',
                  value: _twoFactorEnabled,
                  onChanged: (v) => setState(() => _twoFactorEnabled = v)),

              const SizedBox(height: 28),

              // ── Preferences ────────────────────────────────────────────
              _SectionLabel(label: 'PREFERENCES'),
              const SizedBox(height: 10),
              _ToggleTile(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                value: ref.watch(themeModeProvider) == ThemeMode.dark,
                onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(
                    v ? ThemeMode.dark : ThemeMode.light),
              ),
              _ToggleTile(icon: Icons.notifications_outlined, label: 'Push Notifications',
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v)),
              _NavTile(icon: Icons.language_outlined, label: 'Language',
                  trailing: 'English', onTap: () {}),
              _NavTile(icon: Icons.currency_exchange_rounded, label: 'Default Currency',
                  trailing: 'USD', onTap: () {}),

              const SizedBox(height: 28),

              // ── Support & Legal ────────────────────────────────────────
              _SectionLabel(label: 'SUPPORT & LEGAL'),
              const SizedBox(height: 10),
              _NavTile(icon: Icons.help_outline_rounded, label: 'Help Center', onTap: () {}),
              _NavTile(icon: Icons.chat_bubble_outline_rounded, label: 'Contact Support', onTap: () {}),
              _NavTile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
              _NavTile(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {}),
              _NavTile(icon: Icons.info_outline_rounded, label: 'App Version',
                  trailing: '1.0.0', onTap: null),

              const SizedBox(height: 32),

              // ── Sign Out ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutSheet(context),
                  icon: Icon(Icons.logout_rounded, size: 18, color: cs.error),
                  label: Text('Sign Out',
                      style: tt.labelLarge?.copyWith(
                          color: cs.error, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    side: BorderSide(color: cs.error.withOpacity(0.4), width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
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
          if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
        },
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _showChangePinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ChangePinSheet(),
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
                color: cs.onSurface.withOpacity(0.5), letterSpacing: 1.2)),
      ],
    );
  }
}

// ── Shared tile icon ──────────────────────────────────────────────────────────

class _TileIcon extends StatelessWidget {
  final IconData icon;
  const _TileIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: cs.primary, size: 18),
    );
  }
}

// ── Info Tile ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _TileIcon(icon: icon),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: tt.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.5))),
              const SizedBox(height: 2),
              Text(value, style: tt.titleSmall?.copyWith(color: cs.onSurface)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Nav Tile ──────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  const _NavTile({required this.icon, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: cs.primary.withOpacity(0.10),
          highlightColor: cs.primary.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _TileIcon(icon: icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: tt.titleSmall?.copyWith(color: cs.onSurface)),
                ),
                if (trailing != null)
                  Text(trailing!,
                      style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.5))),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded,
                      color: cs.onSurface.withOpacity(0.3), size: 18),
                ],
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
      {required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _TileIcon(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: tt.titleSmall?.copyWith(color: cs.onSurface)),
          ),
          Switch(value: value, onChanged: onChanged),
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
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
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
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: cs.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.logout_rounded, color: cs.error, size: 28),
          ),
          const SizedBox(height: 18),
          Text('Sign Out',
              style: tt.titleLarge?.copyWith(letterSpacing: -0.3)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size(0, 54),
                  ),
                  child: Text('Cancel',
                      style: tt.labelLarge?.copyWith(
                          color: cs.onSurface.withOpacity(0.6))),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Sign Out',
                      style: tt.labelLarge?.copyWith(
                          color: cs.onError, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Change Password Sheet ─────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Change Password', style: tt.titleLarge),
            const SizedBox(height: 20),
            _PasswordField(controller: _currentCtrl, label: 'Current Password',
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent)),
            const SizedBox(height: 12),
            _PasswordField(controller: _newCtrl, label: 'New Password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew)),
            const SizedBox(height: 12),
            _PasswordField(controller: _confirmCtrl, label: 'Confirm New Password',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Update Password',
                    style: tt.labelLarge?.copyWith(
                        color: cs.onPrimary, fontWeight: FontWeight.w700)),
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
      {required this.controller, required this.label,
       required this.obscure, required this.onToggle});

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
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: cs.onSurface.withOpacity(0.4),
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
  const _ChangePinSheet();
  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  final _currentPin = TextEditingController();
  final _newPin = TextEditingController();
  final _confirmPin = TextEditingController();

  @override
  void dispose() {
    _currentPin.dispose();
    _newPin.dispose();
    _confirmPin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Change PIN', style: tt.titleLarge),
            const SizedBox(height: 20),
            _PinField(controller: _currentPin, label: 'Current PIN'),
            const SizedBox(height: 12),
            _PinField(controller: _newPin, label: 'New PIN'),
            const SizedBox(height: 12),
            _PinField(controller: _confirmPin, label: 'Confirm New PIN'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Update PIN',
                    style: tt.labelLarge?.copyWith(
                        color: cs.onPrimary, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _PinField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: tt.bodyLarge?.copyWith(color: cs.onSurface, letterSpacing: 8),
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }
}

// ── Avatar Source Sheet ────────────────────────────────────────────────────

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
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
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
          const SizedBox(height: 24),
          Text('Update Profile Photo', style: tt.titleMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => onSource(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => onSource(ImageSource.gallery),
                ),
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
  const _SourceOption({required this.icon, required this.label, required this.onTap});

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
              Text(label, style: tt.labelLarge?.copyWith(color: cs.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}
