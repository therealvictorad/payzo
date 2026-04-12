class WalletModel {
  final int id;
  final int? userId;
  final double balance;

  const WalletModel({
    required this.id,
    this.userId,
    required this.balance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        id:      json['id'],
        userId:  json['user_id'],
        balance: double.parse(json['balance'].toString()),
      );

  WalletModel copyWith({double? balance}) => WalletModel(
        id:      id,
        userId:  userId,
        balance: balance ?? this.balance,
      );
}
