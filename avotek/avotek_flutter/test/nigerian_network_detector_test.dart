import 'package:avotek_flutter/core/utils/nigerian_network_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NigerianNetworkDetector', () {
    test('detects supported network prefixes', () {
      expect(NigerianNetworkDetector.detect('08031234567'), 'MTN');
      expect(NigerianNetworkDetector.detect('08021234567'), 'AIRTEL');
      expect(NigerianNetworkDetector.detect('08051234567'), 'GLO');
      expect(NigerianNetworkDetector.detect('08091234567'), '9MOBILE');
      expect(NigerianNetworkDetector.detect('+2348031234567'), 'MTN');
    });

    test('does not guess from incomplete or unknown numbers', () {
      expect(NigerianNetworkDetector.detect('0803'), isNull);
      expect(NigerianNetworkDetector.detect('08001234567'), isNull);
    });
  });
}
