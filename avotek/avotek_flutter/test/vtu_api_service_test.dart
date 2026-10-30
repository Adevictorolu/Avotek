import 'package:avotek_flutter/core/services/vtu_api_service.dart';
import 'package:avotek_flutter/providers/vtu_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not advertise fabricated education PIN catalog products', () {
    final provider = VtuProvider();

    expect(
      provider.catalog.where((plan) => plan.serviceType == 'exam_pin'),
      isEmpty,
    );
  });

  group('Bigisub request mappings', () {
    test('maps the supported Nigerian mobile networks', () {
      expect(VtuApiService.mapNetworkNameToId('MTN'), 1);
      expect(VtuApiService.mapNetworkNameToId('Airtel'), 2);
      expect(VtuApiService.mapNetworkNameToId('Glo'), 3);
      expect(VtuApiService.mapNetworkNameToId('9mobile'), 4);
    });

    test('maps supported cable providers and DisCos', () {
      expect(VtuApiService.mapCableProviderToCode('DStv'), 'dstv');
      expect(VtuApiService.mapCableProviderToCode('GOtv'), 'gotv');
      expect(
        VtuApiService.mapDiscoNameToCode('Ikeja Electric'),
        'ikeja-electric',
      );
      expect(VtuApiService.mapDiscoNameToCode('Eko Electric'), 'eko-electric');
    });

    test('estimates normal and Unicode SMS page counts', () {
      expect(VtuApiService.estimateSmsPages('a' * 160), 1);
      expect(VtuApiService.estimateSmsPages('a' * 161), 2);
      expect(VtuApiService.estimateSmsPages('é' * 70), 1);
      expect(VtuApiService.estimateSmsPages('é' * 71), 2);
      expect(VtuApiService.estimateSmsPages(''), 0);
    });

    test('rejects unknown providers instead of silently selecting another', () {
      expect(
        () => VtuApiService.mapNetworkNameToId('unknown network'),
        throwsArgumentError,
      );
      expect(
        () => VtuApiService.mapCableProviderToCode('unknown provider'),
        throwsArgumentError,
      );
    });

    test(
      'generates web-safe purchase references without 32-bit shift overflow',
      () {
        final ref = VtuApiService.generatePurchaseReference();
        expect(ref, matches(RegExp(r'^AVO-\d{13}-\d{9}$')));
      },
    );
  });
}
