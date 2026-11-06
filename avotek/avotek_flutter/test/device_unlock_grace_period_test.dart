import 'package:avotek_flutter/core/security/device_security_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app lock waits until the 5-minute background grace period ends', () {
    expect(
      DeviceSecurityService.shouldLockAfterBackground(
        const Duration(minutes: 4, seconds: 59),
      ),
      isFalse,
    );
    expect(
      DeviceSecurityService.shouldLockAfterBackground(
        const Duration(minutes: 5),
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
