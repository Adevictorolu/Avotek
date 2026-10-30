import 'dart:convert';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class VtuProviderRequestException implements Exception {
  final int statusCode;
  final String? message;
  final String? reference;

  const VtuProviderRequestException(
    this.statusCode, [
    this.message,
    this.reference,
  ]);

  @override
  String toString() => message ?? 'VTU provider request failed ($statusCode).';
}

/// Client for the authenticated VTU provider Edge Function proxy.
///
/// Provider credentials stay on the server and are never shipped with the app.
class VtuApiService {
  static final VtuApiService instance = VtuApiService._internal();
  VtuApiService._internal();
  static final Random _random = Random.secure();

  /// Generates a web-safe purchase reference without 32-bit JS bitshift overflow.
  static String generatePurchaseReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = 100000000 + _random.nextInt(900000000);
    return 'AVO-$timestamp-$suffix';
  }

  Future<Map<String, dynamic>> _invoke(
    String action, {
    Map<String, dynamic> payload = const {},
    String? userPin,
  }) async {
    final body = <String, dynamic>{
      'action': action,
      'payload': payload,
    };
    String? reference;
    if (userPin != null) {
      body['user_pin'] = userPin;
      reference = generatePurchaseReference();
      body['reference'] = reference;
    }
    late final FunctionResponse response;
    try {
      response = await Supabase.instance.client.functions
          .invoke('vtu-provider', body: body)
          .timeout(const Duration(seconds: 35));
    } on AssertionError {
      throw StateError(
        'Supabase must be initialized before calling the VTU service.',
      );
    } on FunctionException catch (error) {
      final details = error.details;
      String? message;
      if (details is Map) {
        message = details['message']?.toString();
      } else if (details is String && details.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(details);
          if (decoded is Map) {
            message = decoded['message']?.toString();
          }
        } catch (_) {}
      }
      throw VtuProviderRequestException(error.status, message, reference);
    }

    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      final message = data is Map ? data['message']?.toString() : null;
      throw VtuProviderRequestException(
        response.status,
        message,
        reference,
      );
    }
    final rawData = response.data;
    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }
    if (rawData is String && rawData.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    throw Exception('The VTU provider returned an invalid response.');
  }

  Future<Map<String, dynamic>> getWalletBalance() => _invoke('wallet.balance');

  Future<Map<String, dynamic>> purchaseAirtime({
    required dynamic network,
    required String phone,
    required double amount,
    String? pin,
    String airtimeType = 'vtu',
    bool portedNumber = true,
  }) => _invoke(
    'airtime.purchase',
    userPin: pin,
    payload: {
      'network': network is int
          ? network
          : mapNetworkNameToId(network.toString()),
      'phone_number': _cleanPhoneNumber(phone),
      'amount': amount.round(),
      'ported_number': portedNumber,
      'airtime_type': airtimeType,
    },
  );

  Future<List<Map<String, dynamic>>> getDataPlans({
    required dynamic network,
    String? planType,
  }) async {
    final response = await _invoke(
      'data.plans',
      payload: {
        'network': network is int
            ? network
            : mapNetworkNameToId(network.toString()),
        if (planType != null && planType.isNotEmpty) 'plantype': planType,
      },
    );
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is Map && data['plans'] is List) {
      return (data['plans'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> purchaseData({
    required dynamic network,
    required int planId,
    required String phone,
    required double sellPrice,
    String? pin,
    bool portedNumber = true,
  }) => _invoke(
    'data.purchase',
    userPin: pin,
    payload: {
      'network': network is int
          ? network
          : mapNetworkNameToId(network.toString()),
      'plan': planId,
      'phone_number': _cleanPhoneNumber(phone),
      'ported_number': portedNumber,
      'sell_price': sellPrice,
    },
  );

  Future<List<Map<String, dynamic>>> getCablePlans({
    required String cableName,
  }) async {
    final response = await _invoke(
      'cable.plans',
      payload: {
        'cable_name': mapCableProviderToCode(cableName),
      },
    );
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is Map && data['plans'] is List) {
      return (data['plans'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> verifySmartcard({
    required String cableName,
    required String smartcardNumber,
  }) => _invoke(
    'cable.verify',
    payload: {
      'cable_name': mapCableProviderToCode(cableName),
      'card_no': smartcardNumber.trim(),
    },
  );

  Future<Map<String, dynamic>> purchaseCableTv({
    required String cableType,
    required String smartcardNumber,
    required String variationCode,
    required String phone,
    required double amount,
    required String customerName,
    String? pin,
  }) => _invoke(
    'cable.purchase',
    userPin: pin,
    payload: {
      'cable_type': mapCableProviderToCode(cableType),
      'variation_code': variationCode,
      'card_no': smartcardNumber.trim(),
      'phone_number': _cleanPhoneNumber(phone),
      'amount': amount.toInt(),
      'Customer': customerName.trim(),
    },
  );

  Future<List<Map<String, dynamic>>> getElectricityProviders() async {
    final response = await _invoke('electricity.providers');
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is Map<String, dynamic> && data['providers'] is List) {
      return (data['providers'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> verifyMeter({
    required String company,
    required String meterNumber,
    required String meterType,
  }) => _invoke(
    'electricity.verify',
    payload: {
      'company': mapDiscoNameToCode(company),
      'disco_name': mapDiscoNameToCode(company),
      'meter_no': meterNumber.trim(),
      'meter_type': meterType.toLowerCase(),
    },
  );

  Future<Map<String, dynamic>> purchaseElectricity({
    required String company,
    required String meterNumber,
    required String meterType,
    required String phone,
    required double amount,
    required String customerName,
    String? customerAddress,
    String? pin,
  }) => _invoke(
    'electricity.purchase',
    userPin: pin,
    payload: {
      'company': mapDiscoNameToCode(company),
      'disco_name': mapDiscoNameToCode(company),
      'meter_no': meterNumber.trim(),
      'meter_type': meterType.toLowerCase(),
      'phone_number': _cleanPhoneNumber(phone),
      'amount': amount.toInt(),
      'Customer_name': customerName.trim(),
      if (customerAddress != null && customerAddress.isNotEmpty)
        'Customer_address': customerAddress.trim(),
    },
  );

  Future<List<Map<String, dynamic>>> getExamPinPrices() async {
    final response = await _invoke('education.prices');
    final data = response['data'];
    if (data is Map) {
      final prices = data['prices'];
      if (prices is List) {
        return prices
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> purchaseExamPins({
    required String examCode,
    required int quantity,
    String? pin,
  }) => _invoke(
    'education.purchase',
    userPin: pin,
    payload: {'exam': examCode, 'quantity': quantity},
  );

  Future<Map<String, dynamic>> getSmsPricing() => _invoke('sms.pricing');

  Future<Map<String, dynamic>> sendBulkSms({
    required List<String> recipients,
    required String message,
    required String senderName,
    String? pin,
  }) => _invoke(
    'sms.send',
    userPin: pin,
    payload: {
      'recipients': recipients.map(_cleanPhoneNumber).toList(),
      'message': message.trim(),
      'sender_name': senderName.trim(),
      'recipient_consent': true,
    },
  );

  Future<Map<String, dynamic>> requeryTransaction(String tranxId) =>
      _invoke('transaction.requery', payload: {'transaction_id': tranxId});

  static int estimateSmsPages(String message) {
    final runes = message.runes;
    final count = runes.length;
    if (count == 0) return 0;
    final isUnicode = runes.any((character) => character > 0x7f);
    return (count / (isUnicode ? 70 : 160)).ceil();
  }

  static int mapNetworkNameToId(String network) {
    switch (network.trim().toLowerCase()) {
      case 'mtn':
        return 1;
      case 'airtel':
      case 'air':
        return 2;
      case 'glo':
        return 3;
      case '9mobile':
      case 'etisalat':
      case 't2':
      case 'vitel':
        return 4;
      default:
        throw ArgumentError.value(network, 'network', 'Unknown network');
    }
  }

  static String mapNetworkIdToName(int id) {
    switch (id) {
      case 1:
        return 'MTN';
      case 2:
        return 'AIRTEL';
      case 3:
        return 'GLO';
      case 4:
        return '9MOBILE';
      default:
        throw ArgumentError.value(id, 'id', 'Unknown network ID');
    }
  }

  static String mapCableProviderToCode(String provider) {
    final clean = provider.trim().toLowerCase();
    if (clean.contains('dstv')) {
      return 'dstv';
    }
    if (clean.contains('gotv')) {
      return 'gotv';
    }
    if (clean.contains('star')) {
      return 'startimes';
    }
    if (clean.contains('show')) {
      return 'showmax';
    }
    throw ArgumentError.value(provider, 'provider', 'Unknown cable provider');
  }

  static String mapDiscoNameToCode(String disco) {
    final clean = disco.trim().toLowerCase();
    if (clean.contains('ikeja') || clean.contains('ikedc')) {
      return 'ikeja-electric';
    }
    if (clean.contains('eko') || clean.contains('ekedc')) {
      return 'eko-electric';
    }
    if (clean.contains('abuja') || clean.contains('aedc')) {
      return 'abuja-electric';
    }
    if (clean.contains('ibadan') || clean.contains('ibedc')) {
      return 'ibadan-electric';
    }
    if (clean.contains('kano') || clean.contains('kedco')) {
      return 'kano-electric';
    }
    if (clean.contains('enugu') || clean.contains('eedc')) {
      return 'enugu-electric';
    }
    if (clean.contains('port') || clean.contains('phed')) {
      return 'portharcourt-electric';
    }
    if (clean.contains('benin') || clean.contains('bedc')) {
      return 'benin-electric';
    }
    if (clean.contains('aba') || clean.contains('abedc')) {
      return 'aba-electric';
    }
    if (clean.contains('jos') || clean.contains('jedc')) {
      return 'jos-electric';
    }
    if (clean.contains('kaduna') || clean.contains('kaedco')) {
      return 'kaduna-electric';
    }
    if (clean.contains('yola') || clean.contains('yedc')) {
      return 'yola-electric';
    }
    throw ArgumentError.value(disco, 'disco', 'Unknown electricity provider');
  }

  static String _cleanPhoneNumber(String phone) {
    var clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('234') && clean.length == 13) {
      clean = '0${clean.substring(3)}';
    }
    return clean;
  }
}
