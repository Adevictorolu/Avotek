import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../aggregators/aggregator_router.dart';
import '../engine/order_engine.dart';
import '../payments/paystack_service.dart';
import '../whatsapp/whatsapp_service.dart';

class WebhookEndpoint extends Endpoint {
  late final PaystackService _paystackService;

  WebhookEndpoint() {
    _paystackService = PaystackService(
      secretKey: '', // Pulled from env in production
      publicKey: '',
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
      final token = session.passwords['whatsappAccessToken'] ??
          Platform.environment['WHATSAPP_ACCESS_TOKEN'] ??
          '';
      final phoneId = session.passwords['whatsappPhoneNumberId'] ??
          Platform.environment['WHATSAPP_PHONE_NUMBER_ID'] ??
          '';

      final service = WhatsAppService(
        accessToken: token,
        phoneNumberId: phoneId,
        orderEngine: OrderEngine(aggregator: AggregatorRouter.createDefault()),
      );

      final data = jsonDecode(payload);
      await service.handleIncomingMessage(session, data);
      return true;
    } catch (e) {
      session.log('WhatsApp webhook error: $e');
      return false;
    }
  }
}
