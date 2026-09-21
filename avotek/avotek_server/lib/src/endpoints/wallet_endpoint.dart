import 'package:serverpod/serverpod.dart' hide Order, Transaction;
import '../engine/wallet_engine.dart';
import '../generated/protocol.dart';

class WalletEndpoint extends Endpoint {
  Future<WalletSummary> getWallet(Session session, int userId) async {
    var wallet = await Wallet.db.findFirstRow(
      session,
      where: (w) => w.userId.equals(userId),
    );

    if (wallet == null) {
      final now = DateTime.now();
      wallet = await Wallet.db.insertRow(
        session,
        Wallet(
          userId: userId,
          balance: 0.0,
          currency: 'NGN',
          virtualAccountNumber: '90${10000000 + userId}',
          virtualAccountBank: 'Wema Bank / Moniepoint',
          virtualAccountName: 'AVOTEK User $userId',
          updatedAt: now,
        ),
      );
    }

    // Calculate totals from ledger
    final transactions = await Transaction.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    double totalFunded = 0.0;
    double totalSpent = 0.0;

    for (final tx in transactions) {
      if (tx.status == 'success') {
        if (tx.type == 'fund' || tx.type == 'refund') {
          totalFunded += tx.amount;
        } else if (tx.type == 'debit') {
          totalSpent += tx.amount;
        }
      }
    }

    return WalletSummary(
      balance: wallet.balance,
      currency: wallet.currency,
      virtualAccountNumber: wallet.virtualAccountNumber,
      virtualAccountBank: wallet.virtualAccountBank,
      virtualAccountName: wallet.virtualAccountName,
      totalFunded: totalFunded,
      totalSpent: totalSpent,
    );
  }

  Future<List<Transaction>> getTransactions(
    Session session,
    int userId, {
    int limit = 50,
    int offset = 0,
    String? filterType,
  }) async {
    return await Transaction.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          (filterType != null && filterType.isNotEmpty ? t.type.equals(filterType) : Constant.bool(true)),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );
  }

  Future<Transaction> fundWalletSimulate(
    Session session,
    int userId,
    double amount,
    String reference,
    String idempotencyKey,
  ) async {
    return await WalletEngine.creditWallet(
      session: session,
      userId: userId,
      amount: amount,
      reference: reference,
      idempotencyKey: idempotencyKey,
      narration: 'Instant Wallet Funding (Direct Transfer)',
      type: 'fund',
    );
  }
}
