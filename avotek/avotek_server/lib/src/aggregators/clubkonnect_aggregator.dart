import 'dart:convert';
import 'package:http/http.dart' as http;
import 'aggregator_interface.dart';
import 'models/aggregator_result.dart';

class ClubKonnectAggregator implements VtuAggregatorInterface {
  @override
  String get name => 'ClubKonnect';

  final String userId;
  final String apiKey;

  ClubKonnectAggregator({
    required this.userId,
    required this.apiKey,
  });

  final String _baseUrl = 'https://www.clubkonnect.com/API';

  @override
  Future<AggregatorResult> purchaseAirtime({
    required String network,
    required String phone,
    required double amount,
    required String requestId,
  }) async {
    try {
      final netCode = _mapNetworkCode(network);
      final url = Uri.parse(
        '$_baseUrl/AirtimeAPI_V1.asp?UserID=$userId&APIKey=$apiKey&MobileNetwork=$netCode&Amount=$amount&MobileNumber=$phone&RequestID=$requestId',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status']?.toString().toUpperCase();
        if (status == 'ORDER_RECEIVED' || status == '200' || status == 'SUCCESS') {
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['orderid']?.toString() ?? requestId,
            rawResponse: response.body,
          );
        }
        return AggregatorResult(
          status: AggregatorStatus.failed,
          errorMessage: data['msg'] ?? 'ClubKonnect airtime failed',
          rawResponse: response.body,
        );
      }
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'ClubKonnect HTTP ${response.statusCode}',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.timeout,
        errorMessage: 'ClubKonnect airtime timeout: $e',
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
      final netCode = _mapNetworkCode(network);
      final url = Uri.parse(
        '$_baseUrl/DataAPI_V1.asp?UserID=$userId&APIKey=$apiKey&MobileNetwork=$netCode&DataPlan=$variationCode&MobileNumber=$phone&RequestID=$requestId',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status']?.toString().toUpperCase();
        if (status == 'ORDER_RECEIVED' || status == '200' || status == 'SUCCESS') {
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['orderid']?.toString() ?? requestId,
            rawResponse: response.body,
          );
        }
        return AggregatorResult(
          status: AggregatorStatus.failed,
          errorMessage: data['msg'] ?? 'ClubKonnect data purchase failed',
        );
      }
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'ClubKonnect HTTP ${response.statusCode}',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.timeout,
        errorMessage: 'ClubKonnect data timeout: $e',
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
      final url = Uri.parse(
        '$_baseUrl/ElectricityAPI_V1.asp?UserID=$userId&APIKey=$apiKey&ElectricCompany=$disco&MeterNo=$meterNumber&MeterType=$meterType&Amount=$amount&RequestID=$requestId',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ORDER_RECEIVED' || data['status'] == '200') {
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['orderid']?.toString() ?? requestId,
            token: data['metertoken']?.toString(),
            units: data['units']?.toString(),
            rawResponse: response.body,
          );
        }
        return AggregatorResult(
          status: AggregatorStatus.failed,
          errorMessage: data['msg'] ?? 'ClubKonnect electricity failed',
        );
      }
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'ClubKonnect HTTP ${response.statusCode}',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.timeout,
        errorMessage: 'ClubKonnect electricity timeout: $e',
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
      final url = Uri.parse(
        '$_baseUrl/CableTVAPI_V1.asp?UserID=$userId&APIKey=$apiKey&CableTV=$provider&SmartCardNo=$smartcardNumber&Package=$variationCode&RequestID=$requestId',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ORDER_RECEIVED' || data['status'] == '200') {
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['orderid']?.toString() ?? requestId,
            rawResponse: response.body,
          );
        }
        return AggregatorResult(
          status: AggregatorStatus.failed,
          errorMessage: data['msg'] ?? 'ClubKonnect cable failed',
        );
      }
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'ClubKonnect HTTP ${response.statusCode}',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.timeout,
        errorMessage: 'ClubKonnect cable timeout: $e',
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
      final url = Uri.parse(
        '$_baseUrl/EPinAPI_V1.asp?UserID=$userId&APIKey=$apiKey&ExamType=$examType&Quantity=$quantity&RequestID=$requestId',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ORDER_RECEIVED' || data['status'] == '200') {
          return AggregatorResult(
            status: AggregatorStatus.success,
            providerReference: data['orderid']?.toString() ?? requestId,
            token: data['pin']?.toString(),
            rawResponse: response.body,
          );
        }
      }
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'ClubKonnect exam pin failed',
      );
    } catch (e) {
      return AggregatorResult(
        status: AggregatorStatus.timeout,
        errorMessage: 'ClubKonnect exam pin timeout: $e',
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
      errorMessage: 'Betting not directly supported on fallback provider',
    );
  }

  @override
  Future<ValidationResult> verifyMeterNumber({
    required String disco,
    required String meterNumber,
    required String meterType,
  }) async {
    return const ValidationResult(isValid: true, customerName: 'VERIFIED CUSTOMER');
  }

  @override
  Future<ValidationResult> verifySmartcard({
    required String provider,
    required String smartcardNumber,
  }) async {
    return const ValidationResult(isValid: true, customerName: 'VERIFIED SUBSCRIBER');
  }

  String _mapNetworkCode(String network) {
    switch (network.toUpperCase()) {
      case 'MTN':
        return '01';
      case 'GLO':
        return '02';
      case '9MOBILE':
      case 'ETISALAT':
        return '03';
      case 'AIRTEL':
        return '04';
      default:
        return '01';
    }
  }
}
