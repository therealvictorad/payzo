class KycStatusModel {
  final String kycLevel;   // tier0 | tier1 | tier2
  final String kycStatus;  // none | pending | verified | rejected
  final double perTxLimit;
  final double dailyLimit;
  final DateTime? kycSubmittedAt;
  final KycDocumentModel? latestDocument;

  const KycStatusModel({
    required this.kycLevel,
    required this.kycStatus,
    required this.perTxLimit,
    required this.dailyLimit,
    this.kycSubmittedAt,
    this.latestDocument,
  });

  bool get isVerified => kycStatus == 'verified';
  bool get isPending  => kycStatus == 'pending';
  bool get isRejected => kycStatus == 'rejected';
  bool get isNone     => kycStatus == 'none';

  factory KycStatusModel.fromJson(Map<String, dynamic> json) => KycStatusModel(
        kycLevel:       json['kyc_level'] ?? 'tier0',
        kycStatus:      json['kyc_status'] ?? 'none',
        perTxLimit:     double.parse((json['per_tx_limit'] ?? 10000).toString()),
        dailyLimit:     double.parse((json['daily_limit'] ?? 20000).toString()),
        kycSubmittedAt: json['kyc_submitted_at'] != null
                            ? DateTime.parse(json['kyc_submitted_at'])
                            : null,
        latestDocument: json['latest_document'] != null
                            ? KycDocumentModel.fromJson(json['latest_document'])
                            : null,
      );
}

class KycDocumentModel {
  final int id;
  final String documentType;
  final String status;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  const KycDocumentModel({
    required this.id,
    required this.documentType,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
  });

  factory KycDocumentModel.fromJson(Map<String, dynamic> json) => KycDocumentModel(
        id:              json['id'],
        documentType:    json['document_type'],
        status:          json['status'],
        rejectionReason: json['rejection_reason'],
        submittedAt:     DateTime.parse(json['submitted_at']),
        reviewedAt:      json['reviewed_at'] != null
                             ? DateTime.parse(json['reviewed_at'])
                             : null,
      );
}
