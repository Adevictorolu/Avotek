import 'package:serverpod/serverpod.dart' hide Order, Transaction;
import '../engine/wallet_engine.dart';
import '../generated/protocol.dart';

class AdminEndpoint extends Endpoint {
  Future<List<Order>> getAllOrders(
    Session session, {
    int limit = 100,
    int offset = 0,
    String? status,
  }) async {
    return await Order.db.find(
      session,
      where: (o) => status != null && status.isNotEmpty ? o.status.equals(status) : Constant.bool(true),
      orderBy: (o) => o.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Transaction>> getAllTransactions(
    Session session, {
    int limit = 100,
    int offset = 0,
  }) async {
    return await Transaction.db.find(
      session,
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<User>> getAllUsers(
    Session session, {
    int limit = 100,
    int offset = 0,
  }) async {
    return await User.db.find(
      session,
      orderBy: (u) => u.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );
  }

  Future<bool> updateCatalogItem(
    Session session,
    int id,
    double costPrice,
    double defaultMarkup,
    bool active,
  ) async {
    final item = await ServiceCatalog.db.findById(session, id);
    if (item == null) return false;

    item.costPrice = costPrice;
    item.defaultMarkup = defaultMarkup;
    item.active = active;
    await ServiceCatalog.db.updateRow(session, item);
    return true;
  }

  Future<bool> manualRefundOrder(
    Session session,
    int orderId,
    int adminId,
    String reason,
  ) async {
    final order = await Order.db.findById(session, orderId);
    if (order == null || order.status == 'reversed') return false;

    await WalletEngine.reverseDebit(
      session: session,
      userId: order.userId,
      amount: order.sellPrice,
      originalReference: order.providerReference ?? 'ORD-$orderId',
      idempotencyKey: 'MANUAL-REFUND-$orderId',
      reason: 'Admin refund: $reason',
    );

    order.status = 'reversed';
    await Order.db.updateRow(session, order);

    await AuditLog.db.insertRow(
      session,
      AuditLog(
        adminId: adminId,
        action: 'MANUAL_REFUND',
        entityType: 'ORDER',
        entityId: orderId.toString(),
        details: reason,
        createdAt: DateTime.now(),
      ),
    );

    return true;
  }

  Future<bool> updateKycStatus(
    Session session,
    int userId,
    String kycStatus,
    int adminId,
  ) async {
    final user = await User.db.findById(session, userId);
    if (user == null) return false;

    user.kycStatus = kycStatus;
    await User.db.updateRow(session, user);

    await AuditLog.db.insertRow(
      session,
      AuditLog(
        adminId: adminId,
        action: 'KYC_UPDATE',
        entityType: 'USER',
        entityId: userId.toString(),
        details: 'KYC status changed to $kycStatus',
        createdAt: DateTime.now(),
      ),
    );

    return true;
  }

  Future<List<AuditLog>> getAuditLogs(Session session, {int limit = 50}) async {
    return await AuditLog.db.find(
      session,
      orderBy: (a) => a.createdAt,
      orderDescending: true,
      limit: limit,
    );
  }
}
