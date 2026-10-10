import 'package:avotek_flutter/core/services/vtu_api_service.dart';
import 'package:avotek_flutter/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication account IDs', () {
    test('generates a stable Avotek ID from the Supabase user ID', () {
      const userId = '550e8400-e29b-41d4-a716-446655440000';

      expect(UserModel.avoIdFor(userId), 'AVO-550E8400E29B');
      expect(
        UserModel.fromJson({'id': userId, 'email': 'person@example.com'}).avoId,
        'AVO-550E8400E29B',
      );
    });
  });

  test(
    'VTU requests fail closed until a trusted backend is configured',
    () async {
      await expectLater(
        VtuApiService.instance.getWalletBalance(),
        throwsA(isA<StateError>()),
      );
    },
  );
}
