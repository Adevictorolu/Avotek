class WalletModel {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final String? virtualAccountNumber;
  final String? virtualAccountBank;
  final String? virtualAccountName;
  final double totalFunded;
  final double totalSpent;
  final DateTime updatedAt;

  const WalletModel({
    required this.id,
    required this.userId,
    this.balance = 0.0,
    this.currency = 'NGN',
    this.virtualAccountNumber,
    this.virtualAccountBank,
    this.virtualAccountName,
    this.totalFunded = 0.0,
    this.totalSpent = 0.0,
    required this.updatedAt,
  });

  WalletModel copyWith({
    String? id,
    String? userId,
    double? balance,
    String? currency,
    String? virtualAccountNumber,
    String? virtualAccountBank,
    String? virtualAccountName,
    double? totalFunded,
    double? totalSpent,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      virtualAccountNumber: virtualAccountNumber ?? this.virtualAccountNumber,
      virtualAccountBank: virtualAccountBank ?? this.virtualAccountBank,
      virtualAccountName: virtualAccountName ?? this.virtualAccountName,
      totalFunded: totalFunded ?? this.totalFunded,
      totalSpent: totalSpent ?? this.totalSpent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'balance': balance,
        'currency': currency,
        'virtual_account_number': virtualAccountNumber,
        'virtual_account_bank': virtualAccountBank,
        'virtual_account_name': virtualAccountName,
        'total_funded': totalFunded,
        'total_spent': totalSpent,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'NGN',
        virtualAccountNumber: json['virtual_account_number'] as String?,
        virtualAccountBank: json['virtual_account_bank'] as String?,
        virtualAccountName: json['virtual_account_name'] as String?,
        totalFunded: (json['total_funded'] as num?)?.toDouble() ?? 0.0,
        totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      );
}

/// WalletSummary wrapper for compatibility across widgets
class WalletSummary {
  final double balance;
  final String currency;
  final String? virtualAccountNumber;
  final String? virtualAccountBank;
  final String? virtualAccountName;
  final double totalFunded;
  final double totalSpent;

  const WalletSummary({
    required this.balance,
    this.currency = 'NGN',
    this.virtualAccountNumber,
    this.virtualAccountBank,
    this.virtualAccountName,
    this.totalFunded = 0.0,
    this.totalSpent = 0.0,
  });

  factory WalletSummary.fromWallet(WalletModel wallet) => WalletSummary(
        balance: wallet.balance,
        currency: wallet.currency,
        virtualAccountNumber: wallet.virtualAccountNumber,
        virtualAccountBank: wallet.virtualAccountBank,
        virtualAccountName: wallet.virtualAccountName,
        totalFunded: wallet.totalFunded,
        totalSpent: wallet.totalSpent,
      );
}
