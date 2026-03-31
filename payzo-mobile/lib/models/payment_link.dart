class PaymentLinkModel {
  final int id;
  final String code;
  final double amount;
  final String? description;
  final String status; // active | paid | expired
  final DateTime createdAt;
  final DateTime? paidAt;

  const PaymentLinkModel({
    required this.id,
    required this.code,
    required this.amount,
    this.description,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  factory PaymentLinkModel.fromJson(Map<String, dynamic> json) =>
      PaymentLinkModel(
        id:          json['id'],
        code:        json['code'],
        amount:      double.parse(json['amount'].toString()),
        description: json['description'],
        status:      json['status'] ?? 'active',
        createdAt:   DateTime.parse(json['created_at']),
        paidAt:      json['paid_at'] != null
                         ? DateTime.parse(json['paid_at'])
                         : null,
      );
}
