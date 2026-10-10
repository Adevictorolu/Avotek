import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ==============================================================================
/// AVOTEK VTU API GATEWAY SERVICE (BIGISUB V2 INTEGRATION)
/// ==============================================================================
/// Live integration with Bigisub API Gateway (https://api.bigisub.ng)
/// Official documentation: https://rif.africa/technotronics/api/bigisub
class VtuApiService {
  static final VtuApiService instance = VtuApiService._internal();
  VtuApiService._internal();

  // ----------------------------------------------------------------------------
  // LIVE API CONFIGURATION & CREDENTIALS
  // ----------------------------------------------------------------------------
  static String apiBaseUrl = 'https://api.bigisub.ng';
  static String secretToken = 'c71a68151b57aaf3c8535d95d6ae0230a834fb43';
  static String defaultAggregatorPin = '1234';

  /// Configure API credentials dynamically if needed
  static void configure({
    String? baseUrl,
    String? token,
    String? aggregatorPin,
  }) {
    if (baseUrl != null) apiBaseUrl = baseUrl;
    if (token != null) secretToken = token;
    if (aggregatorPin != null) defaultAggregatorPin = aggregatorPin;
    debugPrint('VtuApiService configured with Base URL: $apiBaseUrl');
  }

  /// Request headers required by Bigisub API
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Token $secretToken',
      };

  // ============================================================================
  // 1. WALLET & ACCOUNT STATUS
  // ============================================================================

  /// Check Bigisub Merchant Wallet Balance
  /// Endpoint: GET /api/v2/financial/wallet/balance/
  Future<Map<String, dynamic>> getWalletBalance() async {
    final endpoint = '$apiBaseUrl/api/v2/financial/wallet/balance/';
    try {
      final res = await http.get(Uri.parse(endpoint), headers: _headers);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      debugPrint('VtuApiService.getWalletBalance response: $body');
      return body;
    } catch (e) {
      debugPrint('VtuApiService.getWalletBalance error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 2. AIRTIME PURCHASE
  // ============================================================================

  /// Buy Airtime (MTN: 1, Airtel: 2, Glo: 3, 9Mobile: 4)
  /// Endpoint: POST /api/v2/vtu/airtime/purchase/
  Future<Map<String, dynamic>> purchaseAirtime({
    required dynamic network, // int (1-4) or string ('mtn', 'glo', etc.)
    required String phone,
    required double amount,
    String? pin,
    String airtimeType = 'vtu',
  }) async {
    final endpoint = '$apiBaseUrl/api/v2/vtu/airtime/purchase/';
    final networkId = network is int ? network : mapNetworkNameToId(network.toString());
    final cleanPhone = _cleanPhoneNumber(phone);
    final amtString = amount.toStringAsFixed(0);

    final payload = {
      'network': networkId,
      'phone_number': cleanPhone,
      'amount': amtString,
      'airtime_type': airtimeType,
      'pin': pin ?? defaultAggregatorPin,
    };

    debugPrint('VtuApiService.purchaseAirtime payload: $payload');

    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: jsonEncode(payload),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      debugPrint('VtuApiService.purchaseAirtime [${res.statusCode}]: $body');

      if (res.statusCode == 200 || res.statusCode == 201) {
        return body;
      } else {
        final msg = body['message'] ?? body['detail'] ?? 'Airtime purchase failed';
        throw Exception(msg.toString());
      }
    } catch (e) {
      debugPrint('VtuApiService.purchaseAirtime error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 3. DATA PLANS & DATA PURCHASE
  // ============================================================================

  /// Fetch Live Data Plans from Bigisub
  /// Endpoint: GET /api/v2/vtu/data/plans/?network={network}&plantype={plantype}
  Future<List<Map<String, dynamic>>> getDataPlans({
    required dynamic network,
    String? planType,
  }) async {
    final networkId = network is int ? network : mapNetworkNameToId(network.toString());
    String endpoint = '$apiBaseUrl/api/v2/vtu/data/plans/?network=$networkId';
    if (planType != null && planType.isNotEmpty && planType != 'ALL') {
      endpoint += '&plantype=${planType.toUpperCase()}';
    }

    try {
      final res = await http.get(Uri.parse(endpoint), headers: _headers);
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['data'] is List) {
        final list = (body['data'] as List).cast<Map<String, dynamic>>();
        return list;
      }
      return [];
    } catch (e) {
      debugPrint('VtuApiService.getDataPlans error: $e');
      return [];
    }
  }

  /// Buy Data Bundle
  /// Endpoint: POST /api/v2/vtu/data/purchase/
  Future<Map<String, dynamic>> purchaseData({
    required dynamic network,
    required int planId,
    required String phone,
    String? pin,
    bool portedNumber = true,
  }) async {
    final endpoint = '$apiBaseUrl/api/v2/vtu/data/purchase/';
    final networkId = network is int ? network : mapNetworkNameToId(network.toString());
    final cleanPhone = _cleanPhoneNumber(phone);

    final payload = {
      'network': networkId,
      'plan': planId,
      'phone_number': cleanPhone,
      'pin': pin ?? defaultAggregatorPin,
      'ported_number': portedNumber,
    };

    debugPrint('VtuApiService.purchaseData payload: $payload');

    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: jsonEncode(payload),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      debugPrint('VtuApiService.purchaseData [${res.statusCode}]: $body');

      if (res.statusCode == 200 || res.statusCode == 201) {
        return body;
      } else {
        final msg = body['message'] ?? body['detail'] ?? 'Data purchase failed';
        throw Exception(msg.toString());
      }
    } catch (e) {
      debugPrint('VtuApiService.purchaseData error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 4. CABLE TV (DSTV, GOTV, STARTIMES, SHOWMAX)
  // ============================================================================

  /// Fetch Cable Packages
  /// Endpoint: GET /api/v2/vtu/cable/plans/?cable_name={cable_name}
  Future<List<Map<String, dynamic>>> getCablePlans({required String cableName}) async {
    final cleanCable = mapCableProviderToCode(cableName);
    final endpoint = '$apiBaseUrl/api/v2/vtu/cable/plans/?cable_name=$cleanCable';

    try {
      final res = await http.get(Uri.parse(endpoint), headers: _headers);
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['data'] is List) {
        return (body['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('VtuApiService.getCablePlans error: $e');
      return [];
    }
  }

  /// Verify Cable TV Smartcard / IUC Number
  /// Endpoint: POST /api/v2/vtu/cable/verify/
  Future<Map<String, dynamic>> verifySmartcard({
    required String cableName,
    required String smartcardNumber,
  }) async {
    final endpoint = '$apiBaseUrl/api/v2/vtu/cable/verify/';
    final cleanCable = mapCableProviderToCode(cableName);

    final payload = {
      'cable_name': cleanCable,
      'card_no': smartcardNumber.trim(),
    };

    debugPrint('VtuApiService.verifySmartcard payload: $payload');

    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: jsonEncode(payload),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      debugPrint('VtuApiService.verifySmartcard [${res.statusCode}]: $body');

      if (res.statusCode == 200 && (body['success'] == true || body['data'] != null)) {
        return body;
      } else {
        final msg = body['message'] ?? 'Smartcard verification failed';
        throw Exception(msg.toString());
      }
    } catch (e) {
      debugPrint('VtuApiService.verifySmartcard error: $e');
      rethrow;
    }
  }

  /// Purchase / Renew Cable TV Subscription
  /// Endpoint: POST /api/v2/vtu/cable/purchase/
  Future<Map<String, dynamic>> purchaseCableTv({
    required String cableType,
    required String smartcardNumber,
    required String phone,
    required double amount,
    required String customerName,
    String? pin,
  }) async {
    final endpoint = '$apiBaseUrl/api/v2/vtu/cable/purchase/';
    final cleanCable = mapCableProviderToCode(cableType);

    final payload = {
      'cable_type': cleanCable,
      'card_no': smartcardNumber.trim(),
      'phone_number': _cleanPhoneNumber(phone),
      'amount': amount.toInt(),
      'Customer': customerName.trim(),
      'pin': pin ?? defaultAggregatorPin,
    };

    debugPrint('VtuApiService.purchaseCableTv payload: $payload');

    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: jsonEncode(payload),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      debugPrint('VtuApiService.purchaseCableTv [${res.statusCode}]: $body');

      if (res.statusCode == 200 || res.statusCode == 201) {
        return body;
      } else {
        final msg = body['message'] ?? body['detail'] ?? 'Cable TV subscription failed';
        throw Exception(msg.toString());
      }
    } catch (e) {
      debugPrint('VtuApiService.purchaseCableTv error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 5. BILLS & UTILITIES (ELECTRICITY)
  // ============================================================================

  /// Fetch All Electricity Providers (DisCos)
  /// Endpoint: GET /api/v2/bills/electricity/providers/
  Future<List<Map<String, dynamic>>> getElectricityProviders() async {
    final endpoint = '$apiBaseUrl/api/v2/bills/electricity/providers/';

    try {
      final res = await http.get(Uri.parse(endpoint), headers: _headers);
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['data'] != null && body['data']['providers'] is List) {
        return (body['data']['providers'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('VtuApiService.getElectricityProviders error: $e');
      return [];
    }
  }

  /// Verify Electricity Meter Number
  /// Endpoint: POST /api/v2/bills/electricity/verify/
  Future<Map<String, dynamic>> verifyMeter({
    required String company,
    required String meterNumber,
    required String meterType, // 'prepaid' or 'postpaid'
  }) async {
    final endpoint = '$apiBaseUrl/api/v2/bills/electricity/verify/';
    final discoCode = mapDiscoNameToCode(company);

    final payload = {
      'company': discoCode,
      'meter_no': meterNumber.trim(),
      'meter_type': meterType.toLowerCase(),
    };

    debugPrint('VtuApiService.verifyMeter payload: $payload');

    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: jsonEncode(payload),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      debugPrint('VtuApiService.verifyMeter [${res.statusCode}]: $body');

      if (res.statusCode == 200 && (body['success'] == true || body['data'] != null)) {
        return body;
      } else {
        final msg = body['message'] ?? 'Meter verification failed';
        throw Exception(msg.toString());
      }
    } catch (e) {
      debugPrint('VtuApiService.verifyMeter error: $e');
      rethrow;
    }
  }

  /// Pay Electricity Bill / Purchase Prepaid Token
  /// Endpoint: POST /api/v2/bills/electricity/pay/
  Future<Map<String, dynamic>> purchaseElectricity({
    required String company,
    required String meterNumber,
    required String meterType,
    required String phone,
    required double amount,
    required String customerName,
    String? customerAddress,
    String? pin,
  }) async {
    final endpoint = '$apiBaseUrl/api/v2/bills/electricity/pay/';
    final discoCode = mapDiscoNameToCode(company);

    final payload = <String, dynamic>{
      'company': discoCode,
      'meter_no': meterNumber.trim(),
      'meter_type': meterType.toLowerCase(),
      'phone_number': _cleanPhoneNumber(phone),
      'amount': amount.toInt(),
      'Customer_name': customerName.trim(),
      'pin': pin ?? defaultAggregatorPin,
    };
    if (customerAddress != null && customerAddress.isNotEmpty) {
      payload['Customer_address'] = customerAddress.trim();
    }

    debugPrint('VtuApiService.purchaseElectricity payload: $payload');

    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: jsonEncode(payload),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      debugPrint('VtuApiService.purchaseElectricity [${res.statusCode}]: $body');

      if (res.statusCode == 200 || res.statusCode == 201) {
        return body;
      } else {
        final msg = body['message'] ?? body['detail'] ?? 'Electricity purchase failed';
        throw Exception(msg.toString());
      }
    } catch (e) {
      debugPrint('VtuApiService.purchaseElectricity error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 6. EDUCATION (RESULT CHECKER PINS)
  // ============================================================================

  /// Get Result Checker Pricing
  /// Endpoint: GET /api/v2/bills/result-checker/prices/
  Future<List<Map<String, dynamic>>> getResultCheckerPrices() async {
    final endpoint = '$apiBaseUrl/api/v2/bills/result-checker/prices/';
    try {
      final res = await http.get(Uri.parse(endpoint), headers: _headers);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['data'] != null && body['data']['prices'] is List) {
        return (body['data']['prices'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('VtuApiService.getResultCheckerPrices error: $e');
      return [];
    }
  }

  /// Purchase Result Checker PIN (WAEC, NECO, NABTEB)
  /// Endpoint: POST /api/v2/bills/result-checker/purchase/
  Future<Map<String, dynamic>> purchaseResultCheckerPin({
    required String exam, // 'WAEC', 'NECO', 'NABTEB'
    required int quantity, // 1, 2, 5
    String? pin,
  }) async {
    final endpoint = '$apiBaseUrl/api/v2/bills/result-checker/purchase/';
    final payload = {
      'exam': exam.toUpperCase(),
      'quantity': quantity,
      'pin_code': pin ?? defaultAggregatorPin,
    };

    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        return body;
      } else {
        final msg = body['message'] ?? 'Exam PIN purchase failed';
        throw Exception(msg.toString());
      }
    } catch (e) {
      debugPrint('VtuApiService.purchaseResultCheckerPin error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 7. TRANSACTION REQUERY & STATUS
  // ============================================================================

  /// Requery Transaction Status
  /// Endpoint: POST /api/v2/anubis/transactions/{tranx_id}/requery/
  Future<Map<String, dynamic>> requeryTransaction(String tranxId) async {
    final endpoint = '$apiBaseUrl/api/v2/anubis/transactions/$tranxId/requery/';
    try {
      final res = await http.post(Uri.parse(endpoint), headers: _headers);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('VtuApiService.requeryTransaction error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // HELPER MAPPINGS & VALIDATORS
  // ============================================================================

  /// Map network name string to Bigisub Network ID (1=MTN, 2=Airtel, 3=Glo, 4=9Mobile)
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
        return 1;
    }
  }

  /// Map network ID back to standardized uppercase name
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
        return 'MTN';
    }
  }

  /// Map cable provider name to Bigisub cable code
  static String mapCableProviderToCode(String provider) {
    final clean = provider.trim().toLowerCase();
    if (clean.contains('dstv')) return 'dstv';
    if (clean.contains('gotv')) return 'gotv';
    if (clean.contains('star')) return 'startimes';
    if (clean.contains('show')) return 'showmax';
    return 'dstv';
  }

  /// Map DisCo name to Bigisub company code
  static String mapDiscoNameToCode(String disco) {
    final clean = disco.trim().toLowerCase();
    if (clean.contains('ikeja') || clean.contains('ikedc')) return 'ikeja-electric';
    if (clean.contains('eko') || clean.contains('ekedc')) return 'eko-electric';
    if (clean.contains('abuja') || clean.contains('aedc')) return 'abuja-electric';
    if (clean.contains('ibadan') || clean.contains('ibedc')) return 'ibadan-electric';
    if (clean.contains('kano') || clean.contains('kedco')) return 'kano-electric';
    if (clean.contains('enugu') || clean.contains('eedc')) return 'enugu-electric';
    if (clean.contains('port') || clean.contains('phed')) return 'portharcourt-electric';
    if (clean.contains('benin') || clean.contains('bedc')) return 'benin-electric';
    if (clean.contains('aba') || clean.contains('abedc')) return 'aba-electric';
    if (clean.contains('jos') || clean.contains('jedc')) return 'jos-electric';
    if (clean.contains('kaduna') || clean.contains('kaedco')) return 'kaduna-electric';
    if (clean.contains('yola') || clean.contains('yedc')) return 'yola-electric';
    return disco.toLowerCase();
  }

  /// Clean Nigerian phone number to 11 digits format (e.g. 08012345678)
  static String _cleanPhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('234') && clean.length == 13) {
      clean = '0${clean.substring(3)}';
    }
    return clean;
  }
}
