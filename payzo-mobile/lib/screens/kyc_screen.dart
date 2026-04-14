import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../models/kyc_status.dart';
import '../providers/service_providers.dart';
import '../widgets/primary_button.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  KycStatusModel? _kycStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() => _loading = true);
    try {
      final status = await ref.read(kycServiceProvider).getStatus();
      if (mounted) setState(() { _kycStatus = status; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _kycStatus == null
                    ? _ErrorState(onRetry: _fetchStatus)
                    : _buildContent(context),
              ),
            ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final status = _kycStatus!;

    if (status.isVerified) {
      return _VerifiedState(
        kycLevel:   status.kycLevel,
        perTxLimit: status.perTxLimit,
        dailyLimit: status.dailyLimit,
      );
    }

    if (status.isPending) {
      return _PendingState(submittedAt: status.kycSubmittedAt);
    }

    if (status.isRejected) {
      return Column(
        children: [
          _RejectedBanner(reason: status.latestDocument?.rejectionReason),
          const SizedBox(height: 24),
          _SubmissionForm(onSubmitted: _fetchStatus),
        ],
      );
    }

    // tier0 or none — show tier table + form
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TierInfoCard(kycLevel: status.kycLevel),
        const SizedBox(height: 28),
        _SubmissionForm(onSubmitted: _fetchStatus),
      ],
    );
  }
}

// ── Tier Info Card ────────────────────────────────────────────────────────────

class _TierInfoCard extends StatelessWidget {
  final String kycLevel;
  const _TierInfoCard({required this.kycLevel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.shield_outlined, color: cs.primary, size: 22),
            const SizedBox(width: 10),
            Text('Transaction Limits by Tier',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          Text('Per transaction / Daily total',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          _TierRow(
            label:  'Tier 0 — Unverified email',
            perTx:  '₦10,000',
            daily:  '₦20,000/day',
            active: kycLevel == 'tier0',
          ),
          _TierRow(
            label:  'Tier 1 — Email verified',
            perTx:  '₦200,000',
            daily:  '₦500,000/day',
            active: kycLevel == 'tier1',
          ),
          _TierRow(
            label:  'Tier 2 — KYC approved',
            perTx:  '₦5,000,000',
            daily:  '₦20,000,000/day',
            active: kycLevel == 'tier2',
          ),
          const SizedBox(height: 12),
          Text(
            'Submit your ID document below to unlock Tier 2 limits.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  final String label;
  final String perTx;
  final String daily;
  final bool active;

  const _TierRow({
    required this.label,
    required this.perTx,
    required this.daily,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              active ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 16,
              color: active ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? cs.onSurface : cs.onSurfaceVariant,
                )),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(perTx,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? cs.primary : cs.onSurfaceVariant,
                  )),
              Text(daily,
                  style: TextStyle(
                    fontSize: 11,
                    color: active
                        ? cs.primary.withValues(alpha: 0.7)
                        : cs.onSurfaceVariant.withValues(alpha: 0.6),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Submission Form ───────────────────────────────────────────────────────────

class _SubmissionForm extends ConsumerStatefulWidget {
  final VoidCallback onSubmitted;
  const _SubmissionForm({required this.onSubmitted});

  @override
  ConsumerState<_SubmissionForm> createState() => _SubmissionFormState();
}

class _SubmissionFormState extends ConsumerState<_SubmissionForm> {
  final _formKey      = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _dobCtrl      = TextEditingController();
  final _docNumCtrl   = TextEditingController();
  final _addressCtrl  = TextEditingController();

  String  _docType    = 'nin';
  String? _filePath;
  String? _fileName;
  bool    _submitting = false;
  String? _error;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _dobCtrl.dispose();
    _docNumCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await ImagePicker().pickImage(
      source:       ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() { _filePath = picked.path; _fileName = picked.name; });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_filePath == null) {
      setState(() => _error = 'Please select a document file.');
      return;
    }

    setState(() { _submitting = true; _error = null; });

    try {
      await ref.read(kycServiceProvider).submit(
        documentType:   _docType,
        documentNumber: _docNumCtrl.text.trim(),
        fullName:       _fullNameCtrl.text.trim(),
        dateOfBirth:    _dobCtrl.text.trim(),
        address:        _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        filePath:       _filePath!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC submitted. Under review.')),
        );
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) setState(() { _submitting = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submit Verification',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('All information must match your ID document.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            initialValue: _docType,
            decoration: InputDecoration(
              labelText: 'Document Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'nin',             child: Text('NIN — National ID Number')),
              DropdownMenuItem(value: 'bvn',             child: Text('BVN — Bank Verification Number')),
              DropdownMenuItem(value: 'passport',        child: Text('International Passport')),
              DropdownMenuItem(value: 'drivers_license', child: Text("Driver's License")),
            ],
            onChanged: (v) => setState(() => _docType = v!),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _docNumCtrl,
            decoration: InputDecoration(
              labelText: 'Document Number',
              hintText:  'e.g. 12345678901',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) =>
                (v == null || v.trim().length < 6) ? 'Enter a valid document number' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _fullNameCtrl,
            decoration: InputDecoration(
              labelText: 'Full Name (as on document)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _dobCtrl,
            decoration: InputDecoration(
              labelText:  'Date of Birth',
              hintText:   'YYYY-MM-DD',
              border:     OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context:     context,
                initialDate: DateTime(2000),
                firstDate:   DateTime(1920),
                lastDate:    DateTime.now().subtract(const Duration(days: 365 * 18)),
              );
              if (picked != null) {
                _dobCtrl.text = picked.toIso8601String().split('T').first;
              }
            },
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Date of birth is required' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              labelText: 'Address (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // File picker
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _filePath != null
                      ? AppColors.success
                      : cs.outline.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _filePath != null
                    ? AppColors.success.withValues(alpha: 0.05)
                    : cs.surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  Icon(
                    _filePath != null
                        ? Icons.check_circle_outline
                        : Icons.upload_file_outlined,
                    color: _filePath != null ? AppColors.success : cs.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _filePath != null ? 'Document selected' : 'Upload Document',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize:   14,
                            color: _filePath != null ? AppColors.success : cs.onSurface,
                          ),
                        ),
                        Text(
                          _fileName ?? 'JPG, PNG or PDF — max 2MB',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          maxLines:  1,
                          overflow:  TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text('Browse',
                      style: TextStyle(
                          color:      cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize:   13)),
                ],
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:        cs.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(color: cs.error, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          PrimaryButton(
            label:     'Submit for Verification',
            icon:      Icons.verified_user_outlined,
            onTap:     _submit,
            isLoading: _submitting,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Your documents are stored securely and only reviewed by our team.',
              style:     tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status States ─────────────────────────────────────────────────────────────

class _VerifiedState extends StatelessWidget {
  final String kycLevel;
  final double perTxLimit;
  final double dailyLimit;

  const _VerifiedState({
    required this.kycLevel,
    required this.perTxLimit,
    required this.dailyLimit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              color:  AppColors.success.withValues(alpha: 0.1),
              shape:  BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: AppColors.success, size: 44),
          ),
          const SizedBox(height: 24),
          Text('Account Verified',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Your identity has been verified.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color:        AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(kycLevel.toUpperCase(),
                    style: const TextStyle(
                        color:      AppColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize:   16)),
                const SizedBox(height: 6),
                Text(
                  'Per transaction: ₦${perTxLimit.toStringAsFixed(0)}\n'
                  'Daily limit: ₦${dailyLimit.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color:     AppColors.success,
                      fontSize:  13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingState extends StatelessWidget {
  final DateTime? submittedAt;
  const _PendingState({this.submittedAt});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              color:  AppColors.warning.withValues(alpha: 0.1),
              shape:  BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                color: AppColors.warning, size: 44),
          ),
          const SizedBox(height: 24),
          Text('Under Review',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Your documents are being reviewed.\nThis usually takes 1–2 business days.',
            style:     tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (submittedAt != null) ...[
            const SizedBox(height: 16),
            Text(
              'Submitted on ${submittedAt!.toLocal().toString().split(' ').first}',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _RejectedBanner extends StatelessWidget {
  final String? reason;
  const _RejectedBanner({this.reason});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        cs.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: cs.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cancel_outlined, color: cs.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verification Rejected',
                    style: tt.titleSmall?.copyWith(
                        color: cs.error, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  reason ??
                      'Your submission was rejected. Please resubmit with a clearer document.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text('Please resubmit below.',
                    style: tt.bodySmall?.copyWith(
                        color: cs.error, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Failed to load KYC status'),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
