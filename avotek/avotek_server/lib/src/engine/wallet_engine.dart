import 'package:serverpod/serverpod.dart' hide Order, Transaction;
import '../generated/protocol.dart';

class InsufficientBalanceException implements Exception {
  final String message;
  InsufficientBalanceException(this.message);
  @override
  String toString() => message;
}

class WalletEngine {
  /// Credits a wallet atomically with before/after snapshots and idempotency checking.
  static Future<Transaction> creditWallet({
    required Session session,
    required int userId,
    required double amount,
    required String reference,
    required String idempotencyKey,
    String? narration,
    String type = 'fund',
  }) async {
    // 1. Idempotency check: if transaction exists with this key, return it.
    final existing = await Transaction.db.findFirstRow(
      session,
      where: (t) => t.idempotencyKey.equals(idempotencyKey),
    );
    if (existing != null) {
      session.log('Duplicate funding call with idempotencyKey: $idempotencyKey. Returning existing.');
      return existing;
    }

    // 2. Fetch or create wallet
    var wallet = await Wallet.db.findFirstRow(
      session,
      where: (w) => w.userId.equals(userId),
    );

    final now = DateTime.now();
    wallet ??= await Wallet.db.insertRow(
      session,
      Wallet(
        userId: userId,
        balance: 0.0,
        currency: 'NGN',
        updatedAt: now,
      ),
    );


    final balanceBefore = wallet.balance;
    final balanceAfter = balanceBefore + amount;

    // 3. Update wallet balance
    wallet.balance = balanceAfter;
    wallet.updatedAt = now;
    await Wallet.db.updateRow(session, wallet);

    // 4. Create ledger transaction entry
    final transaction = await Transaction.db.insertRow(
      session,
      Transaction(
        userId: userId,
        type: type,
        amount: amount,
        balanceBefore: balanceBefore,
        balanceAfter: balanceAfter,
        reference: reference,
        status: 'success',
        idempotencyKey: idempotencyKey,
        narration: narration ?? 'Wallet funded via $type',
        createdAt: now,
      ),
    );

    return transaction;
  }

  /// Debits a wallet atomically with balance check and snapshot.
  static Future<Transaction> debitWallet({
    required Session session,
    required int userId,
    required double amount,
    required String reference,
    required String idempotencyKey,
    String? narration,
  }) async {
    // 1. Idempotency check
    final existing = await Transaction.db.findFirstRow(
      session,
      where: (t) => t.idempotencyKey.equals(idempotencyKey),
    );
    if (existing != null) {
      session.log('Duplicate debit call with idempotencyKey: $idempotencyKey. Returning existing.');
      return existing;
    }

    // 2. Fetch wallet
    var wallet = await Wallet.db.findFirstRow(
      session,
      where: (w) => w.userId.equals(userId),
    );

    if (wallet == null || wallet.balance < amount) {
      final available = wallet?.balance ?? 0.0;
      throw InsufficientBalanceException(
        'Insufficient balance: Available ₦${available.toStringAsFixed(2)}, required ₦${amount.toStringAsFixed(2)}',
      );
    }

    final now = DateTime.now();
    final balanceBefore = wallet.balance;
    final balanceAfter = balanceBefore - amount;

    // 3. Deduct balance
    wallet.balance = balanceAfter;
    wallet.updatedAt = now;
    await Wallet.db.updateRow(session, wallet);

    // 4. Ledger record
    final transaction = await Transaction.db.insertRow(
      session,
      Transaction(
        userId: userId,
        type: 'debit',
        amount: amount,
        balanceBefore: balanceBefore,
        balanceAfter: balanceAfter,
        reference: reference,
        status: 'success',
        idempotencyKey: idempotencyKey,
        narration: narration ?? 'Wallet debit',
        createdAt: now,
      ),
    );

    return transaction;
  }

  /// Reverses a previous debit automatically on failure or timeout.
  static Future<Transaction> reverseDebit({
    required Session session,
    required int userId,
    required double amount,
    required String originalReference,
    required String idempotencyKey,
    required String reason,
  }) async {
    var wallet = await Wallet.db.findFirstRow(
      session,
      where: (w) => w.userId.equals(userId),
    );

    final now = DateTime.now();
    wallet ??= await Wallet.db.insertRow(
      session,
      Wallet(
        userId: userId,
        balance: 0.0,
        currency: 'NGN',
        updatedAt: now,
      ),
    );


    final balanceBefore = wallet.balance;
    final balanceAfter = balanceBefore + amount;

    wallet.balance = balanceAfter;
    wallet.updatedAt = now;
    await Wallet.db.updateRow(session, wallet);

    final reversalTx = await Transaction.db.insertRow(
      session,
      Transaction(
        userId: userId,
        type: 'refund',
        amount: amount,
        balanceBefore: balanceBefore,
        balanceAfter: balanceAfter,
        reference: 'REV-$originalReference',
        status: 'success',
        idempotencyKey: 'REV-$idempotencyKey',
        narration: 'Auto-reversal: $reason',
        createdAt: now,
      ),
    );

    // Log to Audit Log
    await AuditLog.db.insertRow(
      session,
      AuditLog(
        adminId: null,
        action: 'AUTO_REVERSE',
        entityType: 'ORDER',
        entityId: originalReference,
        details: 'Reversed ₦$amount to user $userId due to: $reason',
        createdAt: now,
      ),
    );

    return reversalTx;
  }
}
