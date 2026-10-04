import 'dart:convert';
import 'package:http/http.dart' as http;
import 'aggregator_interface.dart';
import 'models/aggregator_result.dart';

/// Live VTU Gateway adapter for BigiSub (https://bigisub.ng)
class BigisubAggregator implements VtuAggregatorInterface {
  @override
  String get name => 'BigiSub';

  final String apiUrl;
  final String apiKey;

  BigisubAggregator({
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
        'Authorization': 'Token $apiKey',
        'X-API-KEY': apiKey,
        'api-token': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Avotek-VTU-Gateway/2.0',
      };

  String _mapNetwork(String network) {
    final net = network.trim().toUpperCase();
    if (net.contains('MTN')) return 'MTN';
    if (net.contains('AIRTEL')) return 'AIRTEL';
    if (net.contains('GLO')) return 'GLO';
    if (net.contains('9MOBILE') || net.contains('ETISALAT')) return '9MOBILE';
    return net;
  }

  @override
  Future<AggregatorResult> purchaseAirtime({
    required String network,
    required String phone,
    required double amount,
    required String requestId,
  }) async {
    try {
      final canonicalNetwork = _mapNetwork(network);
      final endpoints = [
        '$_baseUrl/api/v2/vtu/airtime/purchase/',
        '$_baseUrl/api/v2/airtime/purchase',
        '$_baseUrl/api/topup/',
      ];

      for (final endpoint in endpoints) {
        try {
          final url = Uri.parse(endpoint);
          final body = jsonEncode({
            'request_id': requestId,
            'network': canonicalNetwork,
            'phone': phone,
            'mobile_number': phone,
            'amount': amount,
            'airtime_type': 'VTU',
            'api_key': apiKey,
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
                errorMessage: data['message']?.toString() ??
                    data['detail']?.toString() ??
                    'Airtime failed',
                rawResponse: response.body,
              );
            }
          } else if (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 409) {
            final data = jsonDecode(response.body);
            return AggregatorResult(
              status: AggregatorStatus.failed,
              errorMessage: data['message']?.toString() ??
                  data['detail']?.toString() ??
                  'BigiSub HTTP ${response.statusCode}',
              rawResponse: response.body,
            );
          }
        } catch (_) {
          continue; // Try next fallback endpoint
        }
      }

      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'Unable to connect to BigiSub Airtime gateway',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'BigiSub Airtime Exception: $e',
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
      final canonicalNetwork = _mapNetwork(network);
      final endpoints = [
        '$_baseUrl/api/v2/vtu/data/purchase/',
        '$_baseUrl/api/v2/data/purchase',
        '$_baseUrl/api/data/',
      ];

      for (final endpoint in endpoints) {
        try {
          final url = Uri.parse(endpoint);
          final body = jsonEncode({
            'request_id': requestId,
            'network': canonicalNetwork,
            'phone': phone,
            'mobile_number': phone,
            'plan': variationCode,
            'variation_code': variationCode,
            'amount': amount,
            'Ported_number': true,
            'api_key': apiKey,
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
                errorMessage: data['message']?.toString() ??
                    data['detail']?.toString() ??
                    'Data top-up failed',
                rawResponse: response.body,
              );
            }
          } else if (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 409) {
            final data = jsonDecode(response.body);
            return AggregatorResult(
              status: AggregatorStatus.failed,
              errorMessage: data['message']?.toString() ??
                  data['detail']?.toString() ??
                  'BigiSub HTTP ${response.statusCode}',
              rawResponse: response.body,
            );
          }
        } catch (_) {
          continue;
        }
      }

      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'Unable to connect to BigiSub Data gateway',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'BigiSub Data Exception: $e',
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
      final endpoints = [
        '$_baseUrl/api/v2/bills/electricity/pay/',
        '$_baseUrl/api/v2/electricity/purchase',
        '$_baseUrl/api/billpayment/',
      ];

      for (final endpoint in endpoints) {
        try {
          final url = Uri.parse(endpoint);
          final body = jsonEncode({
            'request_id': requestId,
            'disco': disco.toUpperCase(),
            'meter_type': meterType.toLowerCase(),
            'meter_number': meterNumber,
            'amount': amount,
            'api_key': apiKey,
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
              final units = data['units']?.toString() ??
                  data['data']?['units']?.toString();
              return AggregatorResult(
                status: AggregatorStatus.success,
                providerReference: data['reference']?.toString() ??
                    data['data']?['reference']?.toString() ??
                    requestId,
                token: token,
                units: units,
                rawResponse: response.body,
              );
            }
          } else if (response.statusCode == 400 || response.statusCode == 401) {
            final data = jsonDecode(response.body);
            return AggregatorResult(
              status: AggregatorStatus.failed,
              errorMessage: data['message']?.toString() ??
                  data['detail']?.toString() ??
                  'BigiSub Electricity HTTP ${response.statusCode}',
              rawResponse: response.body,
            );
          }
        } catch (_) {
          continue;
        }
      }

      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'Unable to connect to BigiSub Electricity gateway',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'BigiSub Electricity Exception: $e',
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
      final endpoints = [
        '$_baseUrl/api/v2/vtu/cable/purchase/',
        '$_baseUrl/api/v2/cable/subscribe',
        '$_baseUrl/api/cablesub/',
      ];

      for (final endpoint in endpoints) {
        try {
          final url = Uri.parse(endpoint);
          final body = jsonEncode({
            'request_id': requestId,
            'provider': provider.toUpperCase(),
            'smartcard_number': smartcardNumber,
            'smart_card_number': smartcardNumber,
            'variation_code': variationCode,
            'plan': variationCode,
            'amount': amount,
            'api_key': apiKey,
          });

          final response = await http
              .post(url, headers: _headers, body: body)
              .timeout(const Duration(seconds: 25));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            final data = jsonDecode(response.body);
            final isSuccess = data['status'] == 'success' ||
                data['success'] == true ||
                data['code'] == '000';
            if (isSuccess) {
              return AggregatorResult(
                status: AggregatorStatus.success,
                providerReference: data['reference']?.toString() ??
                    data['data']?['reference']?.toString() ??
                    requestId,
                rawResponse: response.body,
              );
            }
          }
        } catch (_) {
          continue;
        }
      }

      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'Unable to connect to BigiSub Cable gateway',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'BigiSub Cable Exception: $e',
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
      final url = Uri.parse('$_baseUrl/api/v2/bills/result-checker/purchase/');
      final body = jsonEncode({
        'request_id': requestId,
        'service': examType.toUpperCase(),
        'quantity': quantity,
        'api_key': apiKey,
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
        errorMessage: 'BigiSub Exam PIN failed: ${response.body}',
        rawResponse: response.body,
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'BigiSub Exam PIN Exception: $e',
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
      final url = Uri.parse('$_baseUrl/api/v2/betting/fund/');
      final body = jsonEncode({
        'request_id': requestId,
        'provider': provider,
        'customer_id': customerId,
        'amount': amount,
        'api_key': apiKey,
      });

      final response = await http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 25));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final isSuccess = data['status'] == 'success' || data['success'] == true;
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
        errorMessage: 'BigiSub Betting Funding failed: ${response.body}',
        rawResponse: response.body,
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'BigiSub Betting Exception: $e',
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
      final url = Uri.parse('$_baseUrl/api/v2/bills/electricity/verify/');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'disco': disco.toUpperCase(),
          'meter_number': meterNumber,
          'meter_type': meterType.toLowerCase(),
          'api_key': apiKey,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ValidationResult(
          isValid: true,
          customerName: data['customer_name']?.toString() ??
              data['name']?.toString() ??
              'Verified Customer',
          rawDetails: data['address']?.toString(),
        );
      }
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Could not verify meter number',
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Verification failed: $e',
      );
    }
  }

  @override
  Future<ValidationResult> verifySmartcard({
    required String provider,
    required String smartcardNumber,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/v2/vtu/cable/verify/');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'provider': provider.toUpperCase(),
          'smartcard_number': smartcardNumber,
          'api_key': apiKey,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ValidationResult(
          isValid: true,
          customerName: data['customer_name']?.toString() ??
              data['name']?.toString() ??
              'Subscriber Verified',
        );
      }
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Could not verify smartcard',
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Verification failed: $e',
      );
    }
  }
}
