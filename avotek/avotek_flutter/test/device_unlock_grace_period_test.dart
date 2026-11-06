import 'package:avotek_flutter/core/security/device_security_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app lock waits until the 30-second background grace period ends', () {
    expect(
      DeviceSecurityService.shouldLockAfterBackground(
        const Duration(seconds: 29, milliseconds: 999),
      ),
      isFalse,
    );
    expect(
      DeviceSecurityService.shouldLockAfterBackground(
        const Duration(seconds: 30),
      ),
      isTrue,
    );
    expect(
      DeviceSecurityService.shouldLockAfterBackground(
        const Duration(hours: 1),
      ),
      isTrue,
    );
  });
}
