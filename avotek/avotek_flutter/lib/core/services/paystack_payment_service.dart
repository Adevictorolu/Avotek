import 'package:supabase_flutter/supabase_flutter.dart';

class PaystackPaymentSession {
  final String authorizationUrl;
  final String reference;

  const PaystackPaymentSession({
    required this.authorizationUrl,
    required this.reference,
  });
}

class PaystackPaymentVerification {
  final String status;
  final String reference;
  final double? amountNaira;
  final String? currency;

  const PaystackPaymentVerification({
    required this.status,
    required this.reference,
    this.amountNaira,
    this.currency,
  });
}

class PaystackPaymentService {
  static final PaystackPaymentService instance = PaystackPaymentService._();
  PaystackPaymentService._();

  Future<PaystackPaymentSession> initialize({required int amountNaira}) async {
    final response = await _invoke({
      'action': 'initialize',
      'amount': amountNaira,
    });
    final authorizationUrl = response['authorization_url'];
    final reference = response['reference'];
    if (authorizationUrl is! String ||
        !authorizationUrl.startsWith('https://') ||
        reference is! String ||
        reference.isEmpty) {
      throw const FormatException(
        'Payment service returned an invalid checkout session.',
      );
    }
    return PaystackPaymentSession(
      authorizationUrl: authorizationUrl,
      reference: reference,
    );
  }

  Future<PaystackPaymentVerification> verify({
    required String reference,
  }) async {
    final response = await _invoke({
      'action': 'verify',
      'reference': reference,
    });
    final status = response['status'];
    if (status is! String) {
      throw const FormatException(
        'Payment service returned an invalid verification result.',
      );
    }
    final verifiedReference = response['reference'];
    final amount = response['amount'];
    final currency = response['currency'];
    if (status == 'completed' &&
        (verifiedReference != reference ||
            amount is! num ||
            !amount.isFinite ||
            amount <= 0 ||
            currency != 'NGN')) {
      throw const FormatException(
        'Payment service returned incomplete verified payment details.',
      );
    }
    return PaystackPaymentVerification(
      status: status,
      reference: verifiedReference is String ? verifiedReference : reference,
      amountNaira: amount is num ? amount.toDouble() : null,
      currency: currency is String ? currency : null,
    );
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    late final FunctionResponse response;
    try {
      response = await Supabase.instance.client.functions.invoke(
        'paystack-payments',
        body: body,
      );
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map ? details['message']?.toString() : null;
      throw PaystackPaymentException(
        message ?? 'Payment service request failed (${error.status}).',
        reference: details is Map ? details['reference']?.toString() : null,
      );
    }

    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      final message = data is Map ? data['message']?.toString() : null;
      throw PaystackPaymentException(
        message ?? 'Payment service request failed (${response.status}).',
        reference: data is Map ? data['reference']?.toString() : null,
      );
    }
    if (response.data is! Map<String, dynamic>) {
      throw const FormatException(
        'Payment service returned an invalid response.',
      );
    }
    return response.data as Map<String, dynamic>;
  }
}

class PaystackPaymentException implements Exception {
  final String message;
  final String? reference;
  const PaystackPaymentException(this.message, {this.reference});

  @override
  String toString() => message;
}
