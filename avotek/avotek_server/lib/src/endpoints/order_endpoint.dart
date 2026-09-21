import 'package:serverpod/serverpod.dart' hide Order, Transaction;
import '../aggregators/aggregator_router.dart';
import '../engine/order_engine.dart';
import '../generated/protocol.dart';

class OrderEndpoint extends Endpoint {
  late final OrderEngine _orderEngine;
  late final AggregatorRouter _aggregatorRouter;

  OrderEndpoint() {
    _aggregatorRouter = AggregatorRouter.createDefault();
    _orderEngine = OrderEngine(aggregator: _aggregatorRouter);
  }

  Future<OrderResult> buyAirtime(
    Session session,
    int userId,
    String network,
    String phone,
    double amount,
    String idempotencyKey,
    String channel,
  ) async {
    return await _orderEngine.processOrder(
      session: session,
      userId: userId,
      serviceType: 'airtime',
      networkProvider: network,
      recipientIdentifier: phone,
      amount: amount,
      sellPrice: amount, // Airtime sells at face value or slight agent discount
      channel: channel,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<OrderResult> buyData(
    Session session,
    int userId,
    String network,
    String phone,
    String variationCode,
    double amount,
    double sellPrice,
    String idempotencyKey,
    String channel,
  ) async {
    return await _orderEngine.processOrder(
      session: session,
      userId: userId,
      serviceType: 'data',
      networkProvider: network,
      recipientIdentifier: phone,
      amount: amount,
      sellPrice: sellPrice,
      variationCode: variationCode,
      channel: channel,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<OrderResult> payElectricity(
    Session session,
    int userId,
    String disco,
    String meterNumber,
    String meterType,
    double amount,
    String idempotencyKey,
    String channel,
  ) async {
    return await _orderEngine.processOrder(
      session: session,
      userId: userId,
      serviceType: 'electricity',
      networkProvider: disco,
      recipientIdentifier: meterNumber,
      amount: amount,
      sellPrice: amount,
      channel: channel,
      idempotencyKey: idempotencyKey,
      extraDetails: {
        'meterType': meterType,
      },
    );
  }

  Future<OrderResult> payCableTV(
    Session session,
    int userId,
    String provider,
    String smartcardNumber,
    String variationCode,
    double amount,
    String idempotencyKey,
    String channel,
  ) async {
    return await _orderEngine.processOrder(
      session: session,
      userId: userId,
      serviceType: 'tv',
      networkProvider: provider,
      recipientIdentifier: smartcardNumber,
      amount: amount,
      sellPrice: amount,
      variationCode: variationCode,
      channel: channel,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<OrderResult> buyExamPin(
    Session session,
    int userId,
    String examType,
    int quantity,
    double amount,
    String idempotencyKey,
    String channel,
  ) async {
    return await _orderEngine.processOrder(
      session: session,
      userId: userId,
      serviceType: 'exam_pin',
      networkProvider: examType,
      recipientIdentifier: '$quantity unit(s)',
      amount: amount,
      sellPrice: amount,
      channel: channel,
      idempotencyKey: idempotencyKey,
      extraDetails: {
        'quantity': quantity,
      },
    );
  }

  Future<OrderResult> fundBetting(
    Session session,
    int userId,
    String provider,
    String customerId,
    double amount,
    String idempotencyKey,
    String channel,
  ) async {
    return await _orderEngine.processOrder(
      session: session,
      userId: userId,
      serviceType: 'betting',
      networkProvider: provider,
      recipientIdentifier: customerId,
      amount: amount,
      sellPrice: amount,
      channel: channel,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<VerificationResponse> verifyMeter(
    Session session,
    String disco,
    String meterNumber,
    String meterType,
  ) async {
    final result = await _aggregatorRouter.verifyMeterNumber(
      disco: disco,
      meterNumber: meterNumber,
      meterType: meterType,
    );
    return VerificationResponse(
      isValid: result.isValid,
      customerName: result.customerName,
      identifier: meterNumber,
      details: result.rawDetails,
    );
  }

  Future<VerificationResponse> verifySmartcard(
    Session session,
    String provider,
    String smartcardNumber,
  ) async {
    final result = await _aggregatorRouter.verifySmartcard(
      provider: provider,
      smartcardNumber: smartcardNumber,
    );
    return VerificationResponse(
      isValid: result.isValid,
      customerName: result.customerName,
      identifier: smartcardNumber,
      details: result.rawDetails,
    );
  }

  Future<List<Order>> getOrders(
    Session session,
    int userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return await Order.db.find(
      session,
      where: (o) => o.userId.equals(userId),
      orderBy: (o) => o.createdAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );
  }
}
