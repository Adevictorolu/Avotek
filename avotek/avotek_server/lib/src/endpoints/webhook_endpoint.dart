import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../aggregators/aggregator_router.dart';
import '../engine/order_engine.dart';
import '../payments/paystack_service.dart';
import '../whatsapp/whatsapp_service.dart';

class WebhookEndpoint extends Endpoint {
  PaystackService _getPaystackService(Session session) {
    final secretKey = session.passwords['paystackSecretKey'] ??
        Platform.environment['PAYSTACK_SECRET_KEY'] ??
        '';
    final publicKey = session.passwords['paystackPublicKey'] ??
        Platform.environment['PAYSTACK_PUBLIC_KEY'] ??
        '';
    return PaystackService(
      secretKey: secretKey,
      publicKey: publicKey,
    );
  }

  Future<bool> handlePaystackWebhook(
    Session session,
    String payload,
    String signature,
  ) async {
    final service = _getPaystackService(session);
    return await service.processWebhookEvent(
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
