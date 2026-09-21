import 'models/aggregator_result.dart';

abstract class VtuAggregatorInterface {
  String get name;

  Future<AggregatorResult> purchaseAirtime({
    required String network,
    required String phone,
    required double amount,
    required String requestId,
  });

  Future<AggregatorResult> purchaseData({
    required String network,
    required String phone,
    required String variationCode,
    required double amount,
    required String requestId,
  });

  Future<AggregatorResult> payElectricity({
    required String disco,
    required String meterType,
    required String meterNumber,
    required double amount,
    required String requestId,
  });

  Future<AggregatorResult> payCableTV({
    required String provider,
    required String smartcardNumber,
    required String variationCode,
    required double amount,
    required String requestId,
  });

  Future<AggregatorResult> buyExamPin({
    required String examType,
    required int quantity,
    required String requestId,
  });

  Future<AggregatorResult> fundBetting({
    required String provider,
    required String customerId,
    required double amount,
    required String requestId,
  });

  Future<ValidationResult> verifyMeterNumber({
    required String disco,
    required String meterNumber,
    required String meterType,
  });

  Future<ValidationResult> verifySmartcard({
    required String provider,
    required String smartcardNumber,
  });
}
