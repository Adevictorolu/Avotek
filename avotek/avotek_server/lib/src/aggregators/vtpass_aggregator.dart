import 'dart:convert';
import 'package:http/http.dart' as http;
import 'aggregator_interface.dart';
import 'models/aggregator_result.dart';

class VtpassAggregator implements VtuAggregatorInterface {
  @override
  String get name => 'VTpass';

  final String apiKey;
  final String secretKey;
  final String publicKey;
  final bool isLive;

  VtpassAggregator({
    required this.apiKey,
    required this.secretKey,
    required this.publicKey,
    this.isLive = false,
  });

  String get _baseUrl =>
      isLive ? 'https://api-service.vtpass.com/api' : 'https://sandbox.vtpass.com/api';

  Map<String, String> get _headers => {
        'api-key': apiKey,
        'secret-key': secretKey,
        'Content-Type': 'application/json',
      };

  @override
  Future<AggregatorResult> purchaseAirtime({
    required String network,
    required String phone,
    required double amount,
    required String requestId,
  }) async {
    try {
      final serviceId = _mapNetworkToServiceId(network);
      final url = Uri.parse('$_baseUrl/pay');
      final body = jsonEncode({
        'request_id': requestId,
        'serviceID': serviceId,
        'amount': amount,
        'phone': phone,
      });

      final response = await http.post(url, headers: _headers, body: body).timeout(
            const Duration(seconds: 25),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '000') {
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['content']?['transactions']?['transactionId']?.toString() ?? requestId,
            rawResponse: response.body,
          );
        } else {
          return AggregatorResult(
            status: AggregatorStatus.failed,
            errorMessage: data['response_description'] ?? 'VTpass error code: ${data['code']}',
            rawResponse: response.body,
          );
        }
      } else {
        return AggregatorResult(
          status: AggregatorStatus.failed,
          errorMessage: 'VTpass HTTP error ${response.statusCode}',
          rawResponse: response.body,
        );
      }
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.timeout,
        errorMessage: 'VTpass connection failure: $e',
      );
    }
  }

  @override
  Future<AggregatorResult> purchaseData({
    required String network,
    required String phone,
    required String variationCode,
    required double amount,
    required String requestId,
  }) async {
    try {
      final serviceId = '${_mapNetworkToServiceId(network)}-data';
      final url = Uri.parse('$_baseUrl/pay');
      final body = jsonEncode({
        'request_id': requestId,
        'serviceID': serviceId,
        'billersCode': phone,
        'variation_code': variationCode,
        'amount': amount,
        'phone': phone,
      });

      final response = await http.post(url, headers: _headers, body: body).timeout(
            const Duration(seconds: 25),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '000') {
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['content']?['transactions']?['transactionId']?.toString() ?? requestId,
            rawResponse: response.body,
          );
        } else {
          return AggregatorResult(
            status: AggregatorStatus.failed,
            errorMessage: data['response_description'] ?? 'VTpass error code: ${data['code']}',
            rawResponse: response.body,
          );
        }
      } else {
        return AggregatorResult(
          status: AggregatorStatus.failed,
          errorMessage: 'VTpass HTTP error ${response.statusCode}',
        );
      }
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.timeout,
        errorMessage: 'VTpass data error: $e',
      );
    }
  }

  @override
  Future<AggregatorResult> payElectricity({
    required String disco,
    required String meterType,
    required String meterNumber,
    required double amount,
    required String requestId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/pay');
      final body = jsonEncode({
        'request_id': requestId,
        'serviceID': disco.toLowerCase(),
        'billersCode': meterNumber,
        'variation_code': meterType.toLowerCase(),
        'amount': amount,
        'phone': '08000000000',
      });

      final response = await http.post(url, headers: _headers, body: body).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '000') {
          final token = data['token']?.toString() ?? data['purchased_code']?.toString();
          final units = data['units']?.toString();
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['content']?['transactions']?['transactionId']?.toString() ?? requestId,
            token: token,
            units: units,
            rawResponse: response.body,
          );
        }
        return AggregatorResult(
          status: AggregatorStatus.failed,
          errorMessage: data['response_description'] ?? 'VTpass electricity error',
          rawResponse: response.body,
        );
      }
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTpass HTTP error ${response.statusCode}',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.timeout,
        errorMessage: 'VTpass electricity timeout: $e',
      );
    }
  }

  @override
  Future<AggregatorResult> payCableTV({
    required String provider,
    required String smartcardNumber,
    required String variationCode,
    required double amount,
    required String requestId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/pay');
      final body = jsonEncode({
        'request_id': requestId,
        'serviceID': provider.toLowerCase(),
        'billersCode': smartcardNumber,
        'variation_code': variationCode,
        'amount': amount,
        'phone': '08000000000',
      });

      final response = await http.post(url, headers: _headers, body: body).timeout(
            const Duration(seconds: 25),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '000') {
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['content']?['transactions']?['transactionId']?.toString() ?? requestId,
            rawResponse: response.body,
          );
        }
        return AggregatorResult(
          status: AggregatorStatus.failed,
          errorMessage: data['response_description'] ?? 'VTpass cable error',
        );
      }
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTpass HTTP error ${response.statusCode}',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.timeout,
        errorMessage: 'VTpass cable error: $e',
      );
    }
  }

  @override
  Future<AggregatorResult> buyExamPin({
    required String examType,
    required int quantity,
    required String requestId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/pay');
      final body = jsonEncode({
        'request_id': requestId,
        'serviceID': examType.toLowerCase(),
        'variation_code': examType.toLowerCase(),
        'quantity': quantity,
      });

      final response = await http.post(url, headers: _headers, body: body).timeout(
            const Duration(seconds: 25),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '000') {
          final pins = data['cards'] != null ? jsonEncode(data['cards']) : data['purchased_code']?.toString();
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['content']?['transactions']?['transactionId']?.toString() ?? requestId,
            token: pins,
            rawResponse: response.body,
          );
        }
        return AggregatorResult(
          status: AggregatorStatus.failed,
          errorMessage: data['response_description'] ?? 'VTpass exam pin error',
        );
      }
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTpass HTTP error ${response.statusCode}',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.timeout,
        errorMessage: 'VTpass exam pin error: $e',
      );
    }
  }

  @override
  Future<AggregatorResult> fundBetting({
    required String provider,
    required String customerId,
    required double amount,
    required String requestId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/pay');
      final body = jsonEncode({
        'request_id': requestId,
        'serviceID': provider.toLowerCase(),
        'billersCode': customerId,
        'amount': amount,
      });

      final response = await http.post(url, headers: _headers, body: body).timeout(
            const Duration(seconds: 25),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '000') {
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['content']?['transactions']?['transactionId']?.toString() ?? requestId,
            rawResponse: response.body,
          );
        }
        return AggregatorResult(
          status: AggregatorStatus.failed,
          errorMessage: data['response_description'] ?? 'VTpass betting error',
        );
      }
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTpass HTTP error ${response.statusCode}',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.timeout,
        errorMessage: 'VTpass betting error: $e',
      );
    }
  }

  @override
  Future<ValidationResult> verifyMeterNumber({
    required String disco,
    required String meterNumber,
    required String meterType,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/merchant-verify');
      final body = jsonEncode({
        'serviceID': disco.toLowerCase(),
        'billersCode': meterNumber,
        'type': meterType.toLowerCase(),
      });

      final response = await http.post(url, headers: _headers, body: body).timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '000') {
          return ValidationResult(
            isValid: true,
            customerName: data['content']?['Customer_Name'] ?? data['content']?['name'],
            rawDetails: response.body,
          );
        }
      }
      return const ValidationResult(isValid: false, errorMessage: 'Invalid meter number');
    } catch (e) {
      return ValidationResult(isValid: false, errorMessage: 'Verification failed: $e');
    }
  }

  @override
  Future<ValidationResult> verifySmartcard({
    required String provider,
    required String smartcardNumber,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/merchant-verify');
      final body = jsonEncode({
        'serviceID': provider.toLowerCase(),
        'billersCode': smartcardNumber,
      });

      final response = await http.post(url, headers: _headers, body: body).timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '000') {
          return ValidationResult(
            isValid: true,
            customerName: data['content']?['Customer_Name'] ?? data['content']?['name'],
            rawDetails: response.body,
          );
        }
      }
      return const ValidationResult(isValid: false, errorMessage: 'Invalid smartcard number');
    } catch (e) {
      return ValidationResult(isValid: false, errorMessage: 'Verification failed: $e');
    }
  }

  String _mapNetworkToServiceId(String network) {
    switch (network.toUpperCase()) {
      case 'MTN':
        return 'mtn';
      case 'AIRTEL':
        return 'airtel';
      case 'GLO':
        return 'glo';
      case '9MOBILE':
      case 'ETISALAT':
        return 'etisalat';
      default:
        return network.toLowerCase();
    }
  }
}
