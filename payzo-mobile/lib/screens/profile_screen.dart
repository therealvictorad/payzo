import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _avatarPath;
  static const _avatarKey = 'profile_avatar_path';

  // Editable fields (local state for now)
  final _nicknameCtrl     = TextEditingController();
  final _mobileCtrl       = TextEditingController();
  final _addressCtrl      = TextEditingController();
  String _gender          = 'Prefer not to say';
  String? _dateOfBirth;
  bool _isSaving          = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    _nicknameCtrl.text = user.nickname ?? '';
    _mobileCtrl.text   = user.mobile ?? '';
    _addressCtrl.text  = user.address ?? '';
    _gender            = user.gender ?? 'Prefer not to say';
    _dateOfBirth       = user.dateOfBirth;
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
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

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final success = await ref.read(authProvider.notifier).updateProfile(
        nickname:    _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
        gender:      _gender == 'Prefer not to say' ? null : _gender,
        dateOfBirth: _dateOfBirth,
        mobile:      _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
        address:     _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profile updated successfully!' : (ref.read(authProvider).error ?? 'Failed to update profile')),
          backgroundColor: success ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final tt      = Theme.of(context).textTheme;
    final user    = ref.watch(authProvider).user;
    final name    = user?.name ?? 'User';
    final email   = user?.email ?? '';
    final tier    = user?.kycLevel ?? 'tier0';
    final initials = name.trim().split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Profile', style: tt.titleLarge),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  )
                : Text('Save',
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Avatar ────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            width: 88, height: 88,
                            decoration: BoxDecoration(
                              gradient: _avatarPath == null
                                  ? AppColors.cardGradient
                                  : null,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: _avatarPath != null
                                ? ClipOval(
                                    child: Image.file(File(_avatarPath!),
                                        width: 88,
                                        height: 88,
                                        fit: BoxFit.cover))
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
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: cs.surface, width: 2),
                              ),
                              child: Icon(Icons.camera_alt_rounded,
                                  color: cs.onPrimary, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(name,
                        style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    // Account tier badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _tierColor(tier).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tier.toUpperCase(),
                        style: tt.labelSmall?.copyWith(
                            color: _tierColor(tier),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Personal Info ─────────────────────────────────────────
              const _SectionLabel(label: 'PERSONAL INFORMATION'),
              const SizedBox(height: 12),

              _InfoTile(
                icon: Icons.person_outline_rounded,
                label: 'Full Name',
                value: name,
              ),
              _EditableTile(
                icon: Icons.badge_outlined,
                label: 'Nickname',
                controller: _nicknameCtrl,
                hint: 'Add a nickname',
              ),
              _EditableTile(
                icon: Icons.phone_outlined,
                label: 'Mobile Number',
                controller: _mobileCtrl,
                hint: 'e.g. 08012345678',
                keyboardType: TextInputType.phone,
              ),
              _DropdownTile(
                icon: Icons.wc_outlined,
                label: 'Gender',
                value: _gender,
                options: const [
                  'Male',
                  'Female',
                  'Prefer not to say',
                ],
                onChanged: (v) => setState(() => _gender = v!),
              ),
              _TappableTile(
                icon: Icons.cake_outlined,
                label: 'Date of Birth',
                value: _dateOfBirth ?? 'Tap to set',
                onTap: _pickDob,
              ),
              _InfoTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email,
              ),
              _EditableTile(
                icon: Icons.location_on_outlined,
                label: 'Address',
                controller: _addressCtrl,
                hint: 'Enter your address',
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // ── Account Info ──────────────────────────────────────────
              const _SectionLabel(label: 'ACCOUNT INFORMATION'),
              const SizedBox(height: 12),

              _InfoTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Account Number',
                value: 'PAY${user?.id.toString().padLeft(8, '0') ?? '00000000'}',
              ),
              _InfoTile(
                icon: Icons.shield_outlined,
                label: 'Account Tier',
                value: _tierLabel(tier),
                valueColor: _tierColor(tier),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'tier2': return AppColors.success;
      case 'tier1': return AppColors.primary;
      default:      return AppColors.warning;
    }
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'tier2': return 'Tier 2 — Fully Verified';
      case 'tier1': return 'Tier 1 — Email Verified';
      default:      return 'Tier 0 — Unverified';
    }
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

// ── Info Tile (read-only) ─────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TileIcon(icon: icon),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
              const SizedBox(height: 2),
              Text(value,
                  style: tt.titleSmall?.copyWith(
                      color: valueColor ?? cs.onSurface)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Editable Tile ─────────────────────────────────────────────────────────────

class _EditableTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;

  const _EditableTile({
    required this.icon,
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TileIcon(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5))),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: tt.titleSmall?.copyWith(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: tt.bodySmall
                        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.35)),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tappable Tile ─────────────────────────────────────────────────────────────

class _TappableTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TappableTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _TileIcon(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: tt.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 2),
                  Text(value,
                      style: tt.titleSmall?.copyWith(color: cs.onSurface)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Dropdown Tile ─────────────────────────────────────────────────────────────

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  const _DropdownTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5))),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isDense: true,
                    isExpanded: true,
                    style: tt.titleSmall?.copyWith(color: cs.onSurface),
                    items: options
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
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
