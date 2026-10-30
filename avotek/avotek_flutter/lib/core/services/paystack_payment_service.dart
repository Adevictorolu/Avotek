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

class PaystackDedicatedAccountResult {
  final String status;
  final String? accountNumber;
  final String? bankName;
  final String? accountName;
  final String? reference;
  final double? amountNaira;
  final double? transferAmountNaira;
  final String? expiresAt;
  final String? message;

  const PaystackDedicatedAccountResult({
    required this.status,
    this.accountNumber,
    this.bankName,
    this.accountName,
    this.reference,
    this.amountNaira,
    this.transferAmountNaira,
    this.expiresAt,
    this.message,
  });

  bool get isAssigned =>
      status == 'assigned' &&
      accountNumber != null &&
      accountNumber!.isNotEmpty &&
      bankName != null &&
      bankName!.isNotEmpty &&
      accountName != null &&
      accountName!.isNotEmpty;
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

  Future<PaystackDedicatedAccountResult> requestDedicatedAccount({
    String? fullName,
    String? phone,
  }) async {
    final response = await _invoke({
      'action': 'dedicated_account',
      if (fullName != null && fullName.trim().isNotEmpty)
        'full_name': fullName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    });
    final status = response['status'];
    if (status is! String ||
        (status != 'assigned' && status != 'pending' && status != 'unavailable')) {
      throw const FormatException(
        'Payment service returned an invalid dedicated account response.',
      );
    }
    final accountNumber = response['account_number'];
    final bankName = response['bank_name'];
    final accountName = response['account_name'];
    final reference = response['reference'];
    final amount = response['amount_naira'];
    final transferAmount = response['transfer_amount_naira'];
    final message = response['message'];

    if (status == 'assigned' &&
        (accountNumber is! String ||
            accountNumber.trim().isEmpty ||
            bankName is! String ||
            bankName.trim().isEmpty ||
            accountName is! String ||
            accountName.trim().isEmpty)) {
      throw const FormatException(
        'Payment service returned incomplete dedicated account details.',
      );
    }

    return PaystackDedicatedAccountResult(
      status: status,
      accountNumber: accountNumber is String ? accountNumber.trim() : null,
      bankName: bankName is String ? bankName.trim() : null,
      accountName: accountName is String ? accountName.trim() : null,
      reference: reference is String ? reference.trim() : null,
      amountNaira: amount is num ? amount.toDouble() : null,
      transferAmountNaira:
          transferAmount is num ? transferAmount.toDouble() : null,
      message: message is String ? message.trim() : null,
    );
  }

  /// Temporary, amount-specific bank transfer account. It expires and is not
  /// the user's permanent dedicated account.
  Future<PaystackDedicatedAccountResult> requestTransferAccount({
    required int amountNaira,
  }) async {
    final response = await _invoke({
      'action': 'transfer_account',
      'amount': amountNaira,
    });
    final accountNumber = response['account_number'];
    final bankName = response['bank_name'];
    final accountName = response['account_name'];
    if (accountNumber is! String ||
        bankName is! String ||
        accountName is! String ||
        accountNumber.isEmpty) {
      throw const FormatException(
        'Payment service returned incomplete transfer account details.',
      );
    }
    final amount = response['amount_naira'];
    final transferAmount = response['transfer_amount_naira'];
    return PaystackDedicatedAccountResult(
      status: 'assigned',
      accountNumber: accountNumber.trim(),
      bankName: bankName.trim(),
      accountName: accountName.trim(),
      reference: response['reference']?.toString(),
      amountNaira: amount is num ? amount.toDouble() : null,
      transferAmountNaira:
          transferAmount is num ? transferAmount.toDouble() : null,
      expiresAt: response['expires_at']?.toString(),
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

  Future<PaystackPaymentVerification> verifyLatest() async {
    final response = await _invoke({
      'action': 'verify_latest',
    });
    final status = response['status']?.toString() ?? 'none';
    final verifiedReference = response['reference']?.toString() ?? '';
    final amount = response['amount'];
    final currency = response['currency']?.toString();
    return PaystackPaymentVerification(
      status: status,
      reference: verifiedReference,
      amountNaira: amount is num ? amount.toDouble() : null,
      currency: currency,
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
      if (error.status == 0) {
        throw const PaystackPaymentException(
          "Could not connect to Avotek's payment service. Check your connection. "
          'If you already tried to pay, check Transactions before retrying.',
        );
      }
      final details = error.details;
      final message = details is Map ? details['message']?.toString() : null;
      throw PaystackPaymentException(
        message ?? 'Payment service request failed (${error.status}).',
        reference: details is Map ? details['reference']?.toString() : null,
        needsProfileDetails:
            details is Map && details['needs_profile_details'] == true,
      );
    }

    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      final message = data is Map ? data['message']?.toString() : null;
      throw PaystackPaymentException(
        message ?? 'Payment service request failed (${response.status}).',
        reference: data is Map ? data['reference']?.toString() : null,
        needsProfileDetails:
            data is Map && data['needs_profile_details'] == true,
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
  final bool needsProfileDetails;
  const PaystackPaymentException(
    this.message, {
    this.reference,
    this.needsProfileDetails = false,
  });

  @override
  String toString() => message;
}
