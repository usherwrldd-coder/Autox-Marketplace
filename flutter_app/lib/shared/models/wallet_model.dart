import 'package:json_annotation/json_annotation.dart';
part 'wallet_model.g.dart';

@JsonSerializable()
class WalletModel {
  final String   id;
  final String   userId;
  final int      balance;
  final int      escrowBalance;
  final int      pendingPayout;
  final int      lifetimeTopup;
  final int      lifetimeSpent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.escrowBalance,
    required this.pendingPayout,
    required this.lifetimeTopup,
    required this.lifetimeSpent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => _$WalletModelFromJson(json);
  Map<String, dynamic> toJson() => _$WalletModelToJson(this);

  int get totalBalance => balance + escrowBalance;
  bool canAfford(int coins) => balance >= coins;
}

@JsonSerializable()
class TransactionModel {
  final String   id;
  final String   userId;
  final String   type;
  final int      amount;
  final int      balanceBefore;
  final int      balanceAfter;
  final String?  referenceId;
  final String?  referenceType;
  final String   description;
  final String?  paypalOrderId;
  final String?  paypalCaptureId;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceId,
    this.referenceType,
    required this.description,
    this.paypalOrderId,
    this.paypalCaptureId,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => _$TransactionModelFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  bool get isCredit => ['topup', 'escrow_release', 'refund'].contains(type);
  bool get isDebit  => ['purchase', 'escrow_hold', 'withdrawal', 'fee'].contains(type);
}
