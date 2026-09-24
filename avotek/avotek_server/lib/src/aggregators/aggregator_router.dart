import 'dart:io';
import 'aggregator_interface.dart';
import 'mock_aggregator.dart';
import 'models/aggregator_result.dart';
import 'vtpass_aggregator.dart';
import 'clubkonnect_aggregator.dart';
import 'vtupress_aggregator.dart';

class AggregatorRouter implements VtuAggregatorInterface {
  final VtuAggregatorInterface primary;
  final VtuAggregatorInterface fallback;
  final void Function(String message)? onLog;

  AggregatorRouter({
    required this.primary,
    required this.fallback,
    this.onLog,
  });

  factory AggregatorRouter.createDefault({
    String? vtpassApiKey,
    String? vtpassSecretKey,
    String? vtpassPublicKey,
    String? clubkonnectUserId,
    String? clubkonnectApiKey,
    String? vtupressUrl,
    String? vtupressApiKey,
    bool isLive = false,
    void Function(String message)? onLog,
  }) {
    VtuAggregatorInterface primaryAggregator;
    VtuAggregatorInterface fallbackAggregator;

    // Resolve credentials from arguments or environment variables
    final envVtpassKey = vtpassApiKey ?? Platform.environment['VTPASS_API_KEY'];
    final envVtpassSecret = vtpassSecretKey ?? Platform.environment['VTPASS_SECRET_KEY'];
    final envVtpassPublic = vtpassPublicKey ?? Platform.environment['VTPASS_PUBLIC_KEY'] ?? '';

    final envVtupressUrl = vtupressUrl ?? Platform.environment['VTUPRESS_URL'] ?? Platform.environment['VTUPRESS_BASE_URL'];
    final envVtupressKey = vtupressApiKey ?? Platform.environment['VTUPRESS_API_KEY'];

    final envCkUser = clubkonnectUserId ?? Platform.environment['CK_USER_ID'];
    final envCkKey = clubkonnectApiKey ?? Platform.environment['CK_API_KEY'];

    final runMode = Platform.environment['SERVERPOD_RUNMODE'] ?? 'development';
    final effectiveIsLive = isLive || runMode == 'production';

    // 1. Determine Primary Provider
    if (envVtupressUrl != null && envVtupressUrl.isNotEmpty && envVtupressKey != null && envVtupressKey.isNotEmpty) {
      primaryAggregator = VtupressAggregator(
        apiUrl: envVtupressUrl,
        apiKey: envVtupressKey,
      );
    } else if (envVtpassKey != null && envVtpassKey.isNotEmpty && envVtpassSecret != null && envVtpassSecret.isNotEmpty) {
      primaryAggregator = VtpassAggregator(
        apiKey: envVtpassKey,
        secretKey: envVtpassSecret,
        publicKey: envVtpassPublic,
        isLive: effectiveIsLive,
      );
    } else {
      primaryAggregator = MockAggregator();
    }

    // 2. Determine Fallback Provider
    if (envCkUser != null && envCkUser.isNotEmpty && envCkKey != null && envCkKey.isNotEmpty) {
      fallbackAggregator = ClubKonnectAggregator(
        userId: envCkUser,
        apiKey: envCkKey,
      );
    } else if (primaryAggregator is! VtpassAggregator &&
        envVtpassKey != null &&
        envVtpassKey.isNotEmpty &&
        envVtpassSecret != null &&
        envVtpassSecret.isNotEmpty) {
      fallbackAggregator = VtpassAggregator(
        apiKey: envVtpassKey,
        secretKey: envVtpassSecret,
        publicKey: envVtpassPublic,
        isLive: effectiveIsLive,
      );
    } else {
      fallbackAggregator = MockAggregator();
    }

    return AggregatorRouter(
      primary: primaryAggregator,
      fallback: fallbackAggregator,
      onLog: onLog,
    );
  }

  @override
  String get name => 'AggregatorRouter(Primary: ${primary.name}, Fallback: ${fallback.name})';

  Future<AggregatorResult> _routeWithFailover({
    required String operationName,
    required Future<AggregatorResult> Function(VtuAggregatorInterface provider) executor,
  }) async {
    onLog?.call('[$operationName] Attempting with primary provider: ${primary.name}');
    final primaryResult = await executor(primary);

    if (primaryResult.isSuccess) {
      onLog?.call('[$operationName] Primary provider succeeded: ${primaryResult.providerReference}');
      return primaryResult;
    }

    onLog?.call(
      '[$operationName] Primary provider (${primary.name}) failed with: ${primaryResult.errorMessage}. Triggering fallback to ${fallback.name}...',
    );

    final fallbackResult = await executor(fallback);
    if (fallbackResult.isSuccess) {
      onLog?.call('[$operationName] Fallback provider succeeded: ${fallbackResult.providerReference}');
      return fallbackResult;
    }

    onLog?.call(
      '[$operationName] Both primary and fallback providers failed. Primary: ${primaryResult.errorMessage}, Fallback: ${fallbackResult.errorMessage}',
    );

    return AggregatorResult(
      status: AggregatorStatus.failed,
      errorMessage: 'Primary failed (${primaryResult.errorMessage}) & Fallback failed (${fallbackResult.errorMessage})',
      rawResponse: '{"primary": ${primaryResult.rawResponse}, "fallback": ${fallbackResult.rawResponse}}',
    );
  }

  @override
  Future<AggregatorResult> purchaseAirtime({
    required String network,
    required String phone,
    required double amount,
    required String requestId,
  }) {
    return _routeWithFailover(
      operationName: 'PurchaseAirtime-$network-$phone',
      executor: (p) => p.purchaseAirtime(
        network: network,
        phone: phone,
        amount: amount,
        requestId: requestId,
      ),
    );
  }

  @override
  Future<AggregatorResult> purchaseData({
    required String network,
    required String phone,
    required String variationCode,
    required double amount,
    required String requestId,
  }) {
    return _routeWithFailover(
      operationName: 'PurchaseData-$network-$variationCode',
      executor: (p) => p.purchaseData(
        network: network,
        phone: phone,
        variationCode: variationCode,
        amount: amount,
        requestId: requestId,
      ),
    );
  }

  @override
  Future<AggregatorResult> payElectricity({
    required String disco,
    required String meterType,
    required String meterNumber,
    required double amount,
    required String requestId,
  }) {
    return _routeWithFailover(
      operationName: 'Electricity-$disco-$meterNumber',
      executor: (p) => p.payElectricity(
        disco: disco,
        meterType: meterType,
        meterNumber: meterNumber,
        amount: amount,
        requestId: requestId,
      ),
    );
  }

  @override
  Future<AggregatorResult> payCableTV({
    required String provider,
    required String smartcardNumber,
    required String variationCode,
    required double amount,
    required String requestId,
  }) {
    return _routeWithFailover(
      operationName: 'CableTV-$provider-$smartcardNumber',
      executor: (p) => p.payCableTV(
        provider: provider,
        smartcardNumber: smartcardNumber,
        variationCode: variationCode,
        amount: amount,
        requestId: requestId,
      ),
    );
  }

  @override
  Future<AggregatorResult> buyExamPin({
    required String examType,
    required int quantity,
    required String requestId,
  }) {
    return _routeWithFailover(
      operationName: 'ExamPin-$examType',
      executor: (p) => p.buyExamPin(
        examType: examType,
        quantity: quantity,
        requestId: requestId,
      ),
    );
  }

  @override
  Future<AggregatorResult> fundBetting({
    required String provider,
    required String customerId,
    required double amount,
    required String requestId,
  }) {
    return _routeWithFailover(
      operationName: 'Betting-$provider-$customerId',
      executor: (p) => p.fundBetting(
        provider: provider,
        customerId: customerId,
        amount: amount,
        requestId: requestId,
      ),
    );
  }

  @override
  Future<ValidationResult> verifyMeterNumber({
    required String disco,
    required String meterNumber,
    required String meterType,
  }) async {
    final primaryRes = await primary.verifyMeterNumber(disco: disco, meterNumber: meterNumber, meterType: meterType);
    if (primaryRes.isValid) return primaryRes;
    return fallback.verifyMeterNumber(disco: disco, meterNumber: meterNumber, meterType: meterType);
  }

  @override
  Future<ValidationResult> verifySmartcard({
    required String provider,
    required String smartcardNumber,
  }) async {
    final primaryRes = await primary.verifySmartcard(provider: provider, smartcardNumber: smartcardNumber);
    if (primaryRes.isValid) return primaryRes;
    return fallback.verifySmartcard(provider: provider, smartcardNumber: smartcardNumber);
  }
}
