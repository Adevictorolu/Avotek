import 'package:avotek_flutter/core/services/vtu_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
  });
}
