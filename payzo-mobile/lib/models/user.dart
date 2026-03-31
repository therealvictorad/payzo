import 'wallet.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? referralCode;
  final WalletModel? wallet;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.referralCode,
    this.wallet,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        role: json['role'] ?? 'user',
        referralCode: json['referral_code'],
        wallet: json['wallet'] != null ? WalletModel.fromJson(json['wallet']) : null,
      );

  UserModel copyWith({WalletModel? wallet}) => UserModel(
        id: id,
        name: name,
        email: email,
        role: role,
        referralCode: referralCode,
        wallet: wallet ?? this.wallet,
      );
}
