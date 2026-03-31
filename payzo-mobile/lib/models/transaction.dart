class TransactionModel {
  final int id;
  final int senderId;
  final int? receiverId;
  final double amount;
  final String status;
  final String type; // transfer | airtime | bill | payment_link | card
  final Map<String, dynamic>? meta;
  final DateTime createdAt;
  final TransactionUser? sender;
  final TransactionUser? receiver;

  const TransactionModel({
    required this.id,
    required this.senderId,
    this.receiverId,
    required this.amount,
    required this.status,
    required this.type,
    this.meta,
    required this.createdAt,
    this.sender,
    this.receiver,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id:         json['id'],
        senderId:   json['sender_id'],
        receiverId: json['receiver_id'],
        amount:     double.parse(json['amount'].toString()),
        status:     json['status'] ?? 'pending',
        type:       json['type'] ?? 'transfer',
        meta:       json['meta'] != null
                        ? Map<String, dynamic>.from(json['meta'])
                        : null,
        createdAt:  DateTime.parse(json['created_at']),
        sender:     json['sender'] != null
                        ? TransactionUser.fromJson(json['sender'])
                        : null,
        receiver:   json['receiver'] != null
                        ? TransactionUser.fromJson(json['receiver'])
                        : null,
      );
}

class TransactionUser {
  final int id;
  final String name;
  final String email;

  const TransactionUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory TransactionUser.fromJson(Map<String, dynamic> json) =>
      TransactionUser(
        id:    json['id'],
        name:  json['name'],
        email: json['email'],
      );
}
