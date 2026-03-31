class VirtualCardModel {
  final int id;
  final String maskedNumber;
  final String expiry;
  final String cardHolder;
  final String brand; // visa | mastercard
  final String status; // active | frozen | terminated
  final double spendingLimit;
  final DateTime createdAt;

  // Only available on creation response
  final String? fullNumber;
  final String? cvv;

  const VirtualCardModel({
    required this.id,
    required this.maskedNumber,
    required this.expiry,
    required this.cardHolder,
    required this.brand,
    required this.status,
    required this.spendingLimit,
    required this.createdAt,
    this.fullNumber,
    this.cvv,
  });

  factory VirtualCardModel.fromJson(Map<String, dynamic> json) =>
      VirtualCardModel(
        id:            json['id'],
        maskedNumber:  json['masked_number'] ??
                       '**** **** **** ${(json['card_number'] ?? '0000').toString().substring((json['card_number'] ?? '0000').toString().length - 4)}',
        expiry:        json['expiry'],
        cardHolder:    json['card_holder'],
        brand:         json['brand'] ?? 'visa',
        status:        json['status'] ?? 'active',
        spendingLimit: double.parse(json['spending_limit'].toString()),
        createdAt:     DateTime.parse(json['created_at']),
        fullNumber:    json['card_number'],
        cvv:           json['cvv'],
      );
}
