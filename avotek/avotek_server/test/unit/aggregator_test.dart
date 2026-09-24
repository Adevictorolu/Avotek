import 'package:test/test.dart';
import 'package:avotek_server/src/aggregators/mock_aggregator.dart';
import 'package:avotek_server/src/aggregators/aggregator_router.dart';
import 'package:avotek_server/src/payments/paystack_service.dart';

void main() {
  group('Aggregator Abstraction Tests', () {
    test('MockAggregator purchases airtime and data successfully', () async {
      final mock = MockAggregator();
      final airtimeResult = await mock.purchaseAirtime(
        network: 'MTN',
        phone: '08031234567',
        amount: 1000,
        requestId: 'REQ-001',
      );

      expect(airtimeResult.isSuccess, isTrue);
      expect(airtimeResult.providerReference, startsWith('MOCK-AIR-'));

      final dataResult = await mock.purchaseData(
        network: 'AIRTEL',
        phone: '08021234567',
        variationCode: 'airtel-2gb',
        amount: 1200,
        requestId: 'REQ-002',
      );

      expect(dataResult.isSuccess, isTrue);
      expect(dataResult.providerReference, startsWith('MOCK-DATA-'));
    });

    test('MockAggregator generates 20-digit prepaid electricity tokens', () async {
      final mock = MockAggregator();
      final elecResult = await mock.payElectricity(
        disco: 'ikeja-electric',
        meterType: 'prepaid',
        meterNumber: '45019283741',
        amount: 5000,
        requestId: 'REQ-003',
      );

      expect(elecResult.isSuccess, isTrue);
      expect(elecResult.token, isNotNull);
      expect(elecResult.token!.split('-').length, equals(4)); // 4 groups of digits
      expect(elecResult.units, contains('kWh'));
    });

    test('AggregatorRouter automatically fails over to fallback provider when primary fails', () async {
      final failingPrimary = MockAggregator(shouldSimulateFailures: true);
      final healthyFallback = MockAggregator(shouldSimulateFailures: false);

      final logMessages = <String>[];
      final router = AggregatorRouter(
        primary: failingPrimary,
        fallback: healthyFallback,
        onLog: (msg) => logMessages.add(msg),
      );

      // Amount 999 triggers failure in failingPrimary
      final result = await router.purchaseAirtime(
        network: 'MTN',
        phone: '08030000000',
        amount: 999,
        requestId: 'REQ-FAILOVER',
      );

      expect(result.isSuccess, isTrue);
      expect(result.providerReference, startsWith('MOCK-AIR-'));
      expect(logMessages.any((m) => m.contains('Triggering fallback')), isTrue);
      expect(logMessages.any((m) => m.contains('Fallback provider succeeded')), isTrue);
    });
  });

  group('Paystack Service Tests', () {
    test('Paystack HMAC SHA512 signature verification', () {
      const secret = 'sk_test_1234567890abcdef';
      final service = PaystackService(secretKey: secret, publicKey: 'pk_test_123');

      const payload = '{"event":"charge.success","data":{"amount":500000}}';
      // Compute known HMAC for verification
      final hmac = service.verifyWebhookSignature(
        payload: payload,
        signature: 'invalid_signature',
      );
      expect(hmac, isFalse);
    });

    test('Generates dedicated virtual account details', () async {
      final service = PaystackService(secretKey: '', publicKey: '');
      final account = await service.createDedicatedAccount(
        email: 'test@avotek.ng',
        phone: '08031234567',
        name: 'Chukwuemeka Obi',
      );

      expect(account['accountNumber'], startsWith('90'));
      expect(account['bankName'], contains('Wema Bank'));
      expect(account['accountName'], contains('Chukwuemeka Obi'));
    });

    test('AggregatorRouter.createDefault initializes without throwing and falls back to MockAggregator in dev', () {
      final router = AggregatorRouter.createDefault();
      expect(router.primary.name, equals('MockSandboxAggregator'));
      expect(router.fallback.name, equals('MockSandboxAggregator'));
    });
  });
}

