import 'dart:math';
import 'aggregator_interface.dart';
import 'models/aggregator_result.dart';

class MockAggregator implements VtuAggregatorInterface {
  @override
  String get name => 'MockSandboxAggregator';

  final bool shouldSimulateFailures;

  MockAggregator({this.shouldSimulateFailures = false});

  @override
  Future<AggregatorResult> purchaseAirtime({
    required String network,
    required String phone,
    required double amount,
    required String requestId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (shouldSimulateFailures && amount == 999) {
      return AggregatorResult(
        status: AggregatorStatus.failed,
        errorMessage: 'Mock provider network timeout simulation',
      );
    }
    return AggregatorResult(
      status: AggregatorStatus.success,
      providerReference: 'MOCK-AIR-${DateTime.now().millisecondsSinceEpoch}',
      rawResponse: '{"status":"delivered","network":"$network","phone":"$phone","amount":$amount}',
    );
  }

  @override
  Future<AggregatorResult> purchaseData({
    required String network,
    required String phone,
    required String variationCode,
    required double amount,
    required String requestId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return AggregatorResult(
      status: AggregatorStatus.success,
      providerReference: 'MOCK-DATA-${DateTime.now().millisecondsSinceEpoch}',
      rawResponse: '{"status":"delivered","network":"$network","phone":"$phone","plan":"$variationCode"}',
    );
  }

  @override
  Future<AggregatorResult> payElectricity({
    required String disco,
    required String meterType,
    required String meterNumber,
    required double amount,
    required String requestId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final random = Random();
    final token = List.generate(4, (_) => (1000 + random.nextInt(9000)).toString()).join('-');
    final units = '${(amount / 68.0).toStringAsFixed(1)} kWh';

    return AggregatorResult(
      status: AggregatorStatus.success,
      providerReference: 'MOCK-ELEC-${DateTime.now().millisecondsSinceEpoch}',
      token: token,
      units: units,
      rawResponse: '{"status":"delivered","token":"$token","units":"$units","meter":"$meterNumber"}',
    );
  }

  @override
  Future<AggregatorResult> payCableTV({
    required String provider,
    required String smartcardNumber,
    required String variationCode,
    required double amount,
    required String requestId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return AggregatorResult(
      status: AggregatorStatus.success,
      providerReference: 'MOCK-CABLE-${DateTime.now().millisecondsSinceEpoch}',
      customerName: 'CHUKWUEMEKA OBI',
      rawResponse: '{"status":"delivered","provider":"$provider","smartcard":"$smartcardNumber"}',
    );
  }

  @override
  Future<AggregatorResult> buyExamPin({
    required String examType,
    required int quantity,
    required String requestId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final random = Random();
    final pins = List.generate(quantity, (i) => 'PIN-${examType.toUpperCase()}-${1000000000 + random.nextInt(900000000)}').join(', ');
    return AggregatorResult(
      status: AggregatorStatus.success,
      providerReference: 'MOCK-PIN-${DateTime.now().millisecondsSinceEpoch}',
      token: pins,
      rawResponse: '{"status":"delivered","pins":"$pins"}',
    );
  }

  @override
  Future<AggregatorResult> fundBetting({
    required String provider,
    required String customerId,
    required double amount,
    required String requestId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return AggregatorResult(
      status: AggregatorStatus.success,
      providerReference: 'MOCK-BET-${DateTime.now().millisecondsSinceEpoch}',
      customerName: 'KABIRU IBRAHIM',
      rawResponse: '{"status":"delivered","provider":"$provider","customerId":"$customerId"}',
    );
  }

  @override
  Future<ValidationResult> verifyMeterNumber({
    required String disco,
    required String meterNumber,
    required String meterType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ValidationResult(
      isValid: true,
      customerName: 'ALHAJI MUSA BELLO',
      rawDetails: 'Address: 14 Ikeja Way, Lagos. Meter: $meterNumber ($meterType - $disco)',
    );
  }

  @override
  Future<ValidationResult> verifySmartcard({
    required String provider,
    required String smartcardNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ValidationResult(
      isValid: true,
      customerName: 'CHUKWUEMEKA OBI',
      rawDetails: 'Current Bouquet: Premium. Status: Active. IUC: $smartcardNumber',
    );
  }
}
