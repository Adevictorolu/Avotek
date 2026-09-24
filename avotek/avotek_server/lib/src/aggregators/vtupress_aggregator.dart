import 'dart:convert';
import 'package:http/http.dart' as http;
import 'aggregator_interface.dart';
import 'models/aggregator_result.dart';

/// Aggregator adapter for VTUPress-powered WordPress platforms and REST endpoints.
class VtupressAggregator implements VtuAggregatorInterface {
  @override
  String get name => 'VTUPress';

  final String apiUrl;
  final String apiKey;

  VtupressAggregator({
    required this.apiUrl,
    required this.apiKey,
  });

  String get _baseUrl {
    var url = apiUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'X-API-KEY': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  Future<AggregatorResult> purchaseAirtime({
    required String network,
    required String phone,
    required double amount,
    required String requestId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/wp-json/vtupress/v1/airtime');
      final body = jsonEncode({
        'request_id': requestId,
        'network': network.toLowerCase(),
        'phone': phone,
        'amount': amount,
      });

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 25));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final status = data['status']?.toString().toLowerCase();
        final isSuccess = status == 'success' ||
            status == 'successful' ||
            data['code'] == '000' ||
            data['code'] == 200 ||
            data['success'] == true;

        if (isSuccess) {
          final ref = data['data']?['reference']?.toString() ??
              data['reference']?.toString() ??
              data['transid']?.toString() ??
              requestId;
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: ref,
            rawResponse: response.body,
          );
        } else {
          return AggregatorResult(
            status: AggregatorStatus.failed,
            errorMessage: data['message']?.toString() ?? 'VTUPress Airtime failed',
            rawResponse: response.body,
          );
        }
      }

      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTUPress HTTP ${response.statusCode}: ${response.body}',
        rawResponse: response.body,
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTUPress Airtime Exception: $e',
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
      final url = Uri.parse('$_baseUrl/wp-json/vtupress/v1/data');
      final body = jsonEncode({
        'request_id': requestId,
        'network': network.toLowerCase(),
        'phone': phone,
        'variation_code': variationCode,
        'amount': amount,
      });

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 25));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final status = data['status']?.toString().toLowerCase();
        final isSuccess = status == 'success' ||
            status == 'successful' ||
            data['code'] == '000' ||
            data['code'] == 200 ||
            data['success'] == true;

        if (isSuccess) {
          final ref = data['data']?['reference']?.toString() ??
              data['reference']?.toString() ??
              data['transid']?.toString() ??
              requestId;
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: ref,
            rawResponse: response.body,
          );
        } else {
          return AggregatorResult(
            status: AggregatorStatus.failed,
            errorMessage: data['message']?.toString() ?? 'VTUPress Data failed',
            rawResponse: response.body,
          );
        }
      }

      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTUPress HTTP ${response.statusCode}: ${response.body}',
        rawResponse: response.body,
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTUPress Data Exception: $e',
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
      final url = Uri.parse('$_baseUrl/wp-json/vtupress/v1/electricity');
      final body = jsonEncode({
        'request_id': requestId,
        'disco': disco.toLowerCase(),
        'meter_type': meterType.toLowerCase(),
        'meter_number': meterNumber,
        'amount': amount,
      });

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final status = data['status']?.toString().toLowerCase();
        final isSuccess = status == 'success' ||
            status == 'successful' ||
            data['code'] == '000' ||
            data['code'] == 200 ||
            data['success'] == true;

        if (isSuccess) {
          final token = data['token']?.toString() ??
              data['data']?['token']?.toString() ??
              data['purchased_token']?.toString();
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['reference']?.toString() ?? requestId,
            token: token,
            units: data['units']?.toString(),
            rawResponse: response.body,
          );
        }
      }

      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTUPress Electricity failed: ${response.body}',
        rawResponse: response.body,
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTUPress Electricity Exception: $e',
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
      final url = Uri.parse('$_baseUrl/wp-json/vtupress/v1/cable');
      final body = jsonEncode({
        'request_id': requestId,
        'provider': provider.toLowerCase(),
        'smartcard_number': smartcardNumber,
        'variation_code': variationCode,
        'amount': amount,
      });

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 25));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final isSuccess = data['status'] == 'success' || data['code'] == '000';
        if (isSuccess) {
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['reference']?.toString() ?? requestId,
            rawResponse: response.body,
          );
        }
      }

      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTUPress Cable TV failed: ${response.body}',
        rawResponse: response.body,
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTUPress Cable Exception: $e',
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
      final url = Uri.parse('$_baseUrl/wp-json/vtupress/v1/exampin');
      final body = jsonEncode({
        'request_id': requestId,
        'exam_type': examType.toLowerCase(),
        'quantity': quantity,
      });

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 25));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final pins = (data['pins'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        return AggregatorResult(
          status: AggregatorStatus.success,
          providerReference: data['reference']?.toString() ?? requestId,
          token: pins.join(','),
          rawResponse: response.body,
        );
      }

      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTUPress Exam PIN failed: ${response.body}',
        rawResponse: response.body,
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'VTUPress Exam PIN Exception: $e',
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
    return AggregatorResult(
      status: AggregatorStatus.failed,
      errorMessage: 'Betting is not supported via VTUPress',
    );
  }

  @override
  Future<ValidationResult> verifyMeterNumber({
    required String disco,
    required String meterNumber,
    required String meterType,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/wp-json/vtupress/v1/verify-meter');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'disco': disco.toLowerCase(),
          'meter_number': meterNumber,
          'meter_type': meterType.toLowerCase(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ValidationResult(
          isValid: true,
          customerName: data['customer_name']?.toString() ?? data['name']?.toString() ?? 'Verified Customer',
          rawDetails: data['address']?.toString(),
        );
      }
      return ValidationResult(isValid: false, errorMessage: 'Could not verify meter number');
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
      final url = Uri.parse('$_baseUrl/wp-json/vtupress/v1/verify-smartcard');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'provider': provider.toLowerCase(),
          'smartcard_number': smartcardNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ValidationResult(
          isValid: true,
          customerName: data['customer_name']?.toString() ?? data['name']?.toString() ?? 'Subscriber Verified',
        );
      }
      return ValidationResult(isValid: false, errorMessage: 'Could not verify smartcard');
    } catch (e) {
      return ValidationResult(isValid: false, errorMessage: 'Verification failed: $e');
    }
  }
}
