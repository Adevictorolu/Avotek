import 'dart:convert';
import 'package:serverpod/serverpod.dart' hide Order, Transaction;
import '../aggregators/aggregator_interface.dart';
import '../aggregators/models/aggregator_result.dart';
import '../generated/protocol.dart';
import 'wallet_engine.dart';

class OrderEngine {
  final VtuAggregatorInterface aggregator;

  OrderEngine({required this.aggregator});

  Future<OrderResult> processOrder({
    required Session session,
    required int userId,
    required String serviceType,
    required String networkProvider,
    required String recipientIdentifier,
    required double amount,
    required double sellPrice,
    required String channel,
    required String idempotencyKey,
    String? variationCode,
    Map<String, dynamic>? extraDetails,
  }) async {
    // 1. Idempotency check: prevent double charges
    final existingOrder = await Order.db.findFirstRow(
      session,
      where: (o) => o.idempotencyKey.equals(idempotencyKey),
    );
    if (existingOrder != null) {
      session.log('Order already processed for idempotencyKey $idempotencyKey. Returning existing.');
      return OrderResult(
        order: existingOrder,
        success: existingOrder.status == 'success',
        message: 'Order status: ${existingOrder.status} (Idempotent replay)',
      );
    }

    final now = DateTime.now();
    final reference = 'AVO-${now.millisecondsSinceEpoch}-$userId';

    // 2. Lookup catalog pricing to determine costPrice
    double costPrice = amount;
    final catalogItem = await ServiceCatalog.db.findFirstRow(
      session,
      where: (c) =>
          c.serviceType.equals(serviceType) &
          c.provider.equals(networkProvider) &
          (variationCode != null ? c.variationCode.equals(variationCode) : c.active.equals(true)),
    );
    if (catalogItem != null) {
      costPrice = catalogItem.costPrice;
    }

    // 3. Debit wallet atomically
    try {
      await WalletEngine.debitWallet(
        session: session,
        userId: userId,
        amount: sellPrice,
        reference: reference,
        idempotencyKey: idempotencyKey,
        narration: 'Payment for $serviceType ($networkProvider - $recipientIdentifier)',
      );
    } on InsufficientBalanceException catch (e) {
      final failedOrder = await Order.db.insertRow(
        session,
        Order(
          userId: userId,
          serviceType: serviceType,
          networkProvider: networkProvider,
          recipientIdentifier: recipientIdentifier,
          amount: amount,
          costPrice: costPrice,
          sellPrice: sellPrice,
          status: 'failed',
          channel: channel,
          idempotencyKey: idempotencyKey,
          metadata: '{"error": "${e.message}"}',
          createdAt: now,
        ),
      );
      return OrderResult(
        order: failedOrder,
        success: false,
        message: e.message,
      );
    }

    // 4. Create pending order in database
    var order = await Order.db.insertRow(
      session,
      Order(
        userId: userId,
        serviceType: serviceType,
        networkProvider: networkProvider,
        recipientIdentifier: recipientIdentifier,
        amount: amount,
        costPrice: costPrice,
        sellPrice: sellPrice,
        status: 'pending',
        channel: channel,
        idempotencyKey: idempotencyKey,
        metadata: extraDetails != null ? jsonEncode(extraDetails) : null,
        createdAt: now,
      ),
    );

    // 5. Call aggregator via abstraction layer
    AggregatorResult aggResult;
    try {
      switch (serviceType.toLowerCase()) {
        case 'airtime':
          aggResult = await aggregator.purchaseAirtime(
            network: networkProvider,
            phone: recipientIdentifier,
            amount: amount,
            requestId: reference,
          );
          break;
        case 'data':
          aggResult = await aggregator.purchaseData(
            network: networkProvider,
            phone: recipientIdentifier,
            variationCode: variationCode ?? 'data-plan',
            amount: amount,
            requestId: reference,
          );
          break;
        case 'electricity':
          aggResult = await aggregator.payElectricity(
            disco: networkProvider,
            meterType: extraDetails?['meterType'] ?? 'prepaid',
            meterNumber: recipientIdentifier,
            amount: amount,
            requestId: reference,
          );
          break;
        case 'tv':
        case 'cable':
          aggResult = await aggregator.payCableTV(
            provider: networkProvider,
            smartcardNumber: recipientIdentifier,
            variationCode: variationCode ?? 'package',
            amount: amount,
            requestId: reference,
          );
          break;
        case 'exam_pin':
          aggResult = await aggregator.buyExamPin(
            examType: networkProvider,
            quantity: extraDetails?['quantity'] ?? 1,
            requestId: reference,
          );
          break;
        case 'betting':
          aggResult = await aggregator.fundBetting(
            provider: networkProvider,
            customerId: recipientIdentifier,
            amount: amount,
            requestId: reference,
          );
          break;
        default:
          aggResult = const AggregatorResult(
            status: AggregatorStatus.failed,
            errorMessage: 'Unsupported service type',
          );
      }
    } catch (e) {
      aggResult = AggregatorResult(
        status: AggregatorStatus.timeout,
        errorMessage: 'Aggregator exception: $e',
      );
    }

    // 6. Handle aggregator outcome
    if (aggResult.isSuccess) {
      order.status = 'success';
      order.providerReference = aggResult.providerReference;
      final meta = {
        ...?extraDetails,
        if (aggResult.token != null) 'token': aggResult.token,
        if (aggResult.units != null) 'units': aggResult.units,
        if (aggResult.customerName != null) 'customerName': aggResult.customerName,
      };
      order.metadata = jsonEncode(meta);
      await Order.db.updateRow(session, order);

      return OrderResult(
        order: order,
        success: true,
        message: 'Order completed successfully',
        token: aggResult.token,
        units: aggResult.units,
      );
    } else {
      // 7. Auto-reversal: on failure or timeout, reverse debit atomically!
      await WalletEngine.reverseDebit(
        session: session,
        userId: userId,
        amount: sellPrice,
        originalReference: reference,
        idempotencyKey: idempotencyKey,
        reason: aggResult.errorMessage ?? 'Provider execution failed',
      );

      order.status = 'reversed';
      order.metadata = jsonEncode({
        ...?extraDetails,
        'error': aggResult.errorMessage,
        'reversal': true,
      });
      await Order.db.updateRow(session, order);

      return OrderResult(
        order: order,
        success: false,
        message: 'Order failed: ${aggResult.errorMessage}. Wallet balance refunded.',
      );
    }
  }
}
