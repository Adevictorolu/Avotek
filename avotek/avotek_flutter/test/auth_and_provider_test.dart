import 'package:avotek_flutter/core/router/app_router.dart';
import 'package:avotek_flutter/core/services/vtu_api_service.dart';
import 'package:avotek_flutter/core/supabase/supabase_service.dart';
import 'package:avotek_flutter/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication account IDs', () {
    test('generates a stable Avotek ID from the Supabase user ID', () {
      const userId = '550e8400-e29b-41d4-a716-446655440000';

      expect(UserModel.avoIdFor(userId), 'AVO-550E8400E29B41D4');
      expect(
        UserModel.fromJson({'id': userId, 'email': 'person@example.com'}).avoId,
        'AVO-550E8400E29B41D4',
      );
    });

    test(
      'recognizes the configured administrator email case-insensitively',
      () {
        final admin = UserModel.fromJson({
          'id': 'admin-user-id',
          'email': '  AdemolaVictor869@Gmail.com ',
        });
        final regularUser = UserModel.fromJson({
          'id': 'regular-user-id',
          'email': 'person@example.com',
          'role': 'admin',
        });

        expect(admin.isAdmin, isTrue);
        expect(admin.role, 'admin');
        expect(regularUser.isAdmin, isFalse);
        expect(regularUser.role, 'user');
      },
    );

    test('routes the designated administrator directly to the admin panel', () {
      expect(
        authenticatedHomeForEmail('ademolavictor869@gmail.com'),
        '/admin',
      );
      expect(
        authenticatedHomeForEmail('person@example.com'),
        '/dashboard',
      );
    });
  });

  test('keeps the GitHub Pages project path in auth callback URLs', () {
    final redirect = buildWebAuthRedirectUrl(
      Uri.parse('https://adevictorolu.github.io/Avotek/?code=oauth#/login'),
      '/login-callback',
    );

    expect(
      redirect,
      'https://adevictorolu.github.io/Avotek/#/login-callback',
    );
  });

  test(
    'VTU requests fail clearly when Supabase is not initialized',
    () async {
      await expectLater(
        VtuApiService.instance.getWalletBalance(),
        throwsA(isA<StateError>()),
      );
    },
  );
}
