import 'package:avotek_flutter/core/utils/user_facing_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('userFacingError', () {
    test('replaces database and SQL details with the fallback', () {
      expect(
        userFacingError(
          'PostgrestException: SQLSTATE 42501 permission denied for table users',
        ),
        'We could not complete that request. Please try again.',
      );
    });

    test('turns network exceptions into a connectivity message', () {
      expect(
        userFacingError(Exception('SocketException: failed host lookup')),
        'Connection problem. Check your internet and try again.',
      );
    });

    test('preserves ordinary user-facing errors', () {
      expect(
        userFacingError('Your transaction could not be completed.'),
        'Your transaction could not be completed.',
      );
    });
  });
}
