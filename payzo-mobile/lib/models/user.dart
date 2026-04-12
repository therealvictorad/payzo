import 'wallet.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? referralCode;
  final bool hasTransactionPin;
  final String kycLevel;
  final String kycStatus;
  final WalletModel? wallet;
  final String? nickname;
  final String? gender;
  final String? dateOfBirth;
  final String? mobile;
  final String? address;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.referralCode,
    this.hasTransactionPin = false,
    this.kycLevel = 'tier0',
    this.kycStatus = 'none',
    this.wallet,
    this.nickname,
    this.gender,
    this.dateOfBirth,
    this.mobile,
    this.address,
  });

  bool get isKycVerified => kycStatus == 'verified';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:                json['id'],
        name:              json['name'],
        email:             json['email'],
        role:              json['role'] ?? 'user',
        referralCode:      json['referral_code'],
        hasTransactionPin: json['has_transaction_pin'] ?? false,
        kycLevel:          json['kyc_level'] ?? 'tier0',
        kycStatus:         json['kyc_status'] ?? 'none',
        wallet:            json['wallet'] != null
                               ? WalletModel.fromJson(json['wallet'])
                               : null,
        nickname:          json['nickname'],
        gender:            json['gender'],
        dateOfBirth:       json['date_of_birth'],
        mobile:            json['mobile'],
        address:           json['address'],
      );

  UserModel copyWith({
    WalletModel? wallet,
    bool? hasTransactionPin,
    String? nickname,
    String? gender,
    String? dateOfBirth,
    String? mobile,
    String? address,
  }) => UserModel(
        id:                id,
        name:              name,
        email:             email,
        role:              role,
        referralCode:      referralCode,
        hasTransactionPin: hasTransactionPin ?? this.hasTransactionPin,
        kycLevel:          kycLevel,
        kycStatus:         kycStatus,
        wallet:            wallet ?? this.wallet,
        nickname:          nickname ?? this.nickname,
        gender:            gender ?? this.gender,
        dateOfBirth:       dateOfBirth ?? this.dateOfBirth,
        mobile:            mobile ?? this.mobile,
        address:           address ?? this.address,
      );
}
