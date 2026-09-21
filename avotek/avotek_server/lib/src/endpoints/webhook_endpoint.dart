import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../aggregators/aggregator_router.dart';
import '../engine/order_engine.dart';
import '../payments/paystack_service.dart';
import '../whatsapp/whatsapp_service.dart';

class WebhookEndpoint extends Endpoint {
  late final PaystackService _paystackService;
  late final WhatsAppService _whatsAppService;

  WebhookEndpoint() {
    _paystackService = PaystackService(
      secretKey: '', // Pulled from env in production
      publicKey: '',
    );
    final router = AggregatorRouter.createDefault();
    final engine = OrderEngine(aggregator: router);
    _whatsAppService = WhatsAppService(
      accessToken: '',
      phoneNumberId: '',
      orderEngine: engine,
    );
  }

  Future<bool> handlePaystackWebhook(
    Session session,
    String payload,
    String signature,
  ) async {
    return await _paystackService.processWebhookEvent(
      session: session,
      payload: payload,
      signature: signature,
    );
  }

  Future<bool> handleWhatsAppWebhook(
    Session session,
    String payload,
  ) async {
    try {
      final data = jsonDecode(payload);
      await _whatsAppService.handleIncomingMessage(session, data);
      return true;
    } catch (e) {
      session.log('WhatsApp webhook error: $e');
      return false;
    }
  }
}
