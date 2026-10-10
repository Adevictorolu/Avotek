class TransactionModel {
  final dynamic id;
  final String userId;
  final String type; // 'credit' | 'debit'
  final String category; // 'airtime', 'data', 'electricity', 'cable', 'wallet_fund'
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String reference;
  final String? narration;
  final String status; // 'completed' | 'pending' | 'failed'
  final String? idempotencyKey;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    this.category = 'vtu',
    required this.amount,
    this.balanceBefore = 0.0,
    this.balanceAfter = 0.0,
    required this.reference,
    this.narration,
    this.status = 'completed',
    this.idempotencyKey,
    required this.createdAt,
  });

  bool get isCredit => type.toLowerCase() == 'credit';
  bool get isDebit => type.toLowerCase() == 'debit';

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'category': category,
        'amount': amount,
        'balance_before': balanceBefore,
        'balance_after': balanceAfter,
        'reference': reference,
        'narration': narration,
        'status': status,
        'idempotency_key': idempotencyKey,
        'created_at': createdAt.toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'],
        userId: json['user_id']?.toString() ?? '',
        type: json['type'] as String? ?? 'debit',
        category: json['category'] as String? ?? 'vtu',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        balanceBefore: (json['balance_before'] as num?)?.toDouble() ?? 0.0,
        balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
        reference: json['reference'] as String? ?? '',
        narration: json['narration'] as String?,
        status: json['status'] as String? ?? 'completed',
        idempotencyKey: json['idempotency_key'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

// Alias for Transaction to ensure drop-in replacement across the codebase
typedef Transaction = TransactionModel;
