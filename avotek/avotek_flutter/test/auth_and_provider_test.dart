import 'package:avotek_flutter/core/router/app_router.dart';
import 'package:avotek_flutter/core/services/vtu_api_service.dart';
import 'package:avotek_flutter/core/supabase/supabase_service.dart';
import 'package:avotek_flutter/models/user_model.dart';
import 'package:avotek_flutter/models/wallet_model.dart';
import 'package:avotek_flutter/providers/auth_provider.dart';
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

    test('builds referral links for the deployed GitHub Pages subpath', () {
      expect(
        avotekReferralLinkFor(
          Uri.parse('https://adevictorolu.github.io/Avotek/#/affiliate'),
          'AVO-ABC123',
        ),
        'https://adevictorolu.github.io/Avotek/#/register?ref=AVO-ABC123',
      );
    });

    test('maps common Supabase authentication errors to clear messages', () {
      expect(
        friendlyAuthError(Exception('Invalid login credentials')),
        'The email, username, Avotek ID, or password is incorrect.',
      );
      expect(
        friendlyAuthError(Exception('User already registered')),
        'An account with this email already exists. Sign in or reset your password.',
      );
      expect(
        friendlyAuthError(Exception('Email not confirmed')),
        'Verify your email address using the link we sent before signing in.',
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
    'treats virtual account numbers as active only when Paystack status is assigned',
    () {
      final assignedWallet = WalletModel.fromJson({
        'id': 'w1',
        'user_id': 'u1',
        'balance': 2500,
        'currency': 'NGN',
        'virtual_account_number': '9012345678',
        'virtual_account_bank': 'Wema Bank',
        'virtual_account_name': 'AVOTEK / ADEWALE OKAFOR',
        'paystack_dva_status': 'assigned',
      });
      final unassignedWallet = WalletModel.fromJson({
        'id': 'w2',
        'user_id': 'u2',
        'balance': 0,
        'currency': 'NGN',
        'virtual_account_number': '9012345678',
        'virtual_account_bank': 'Wema Bank',
        'paystack_dva_status': 'unassigned',
      });

      expect(assignedWallet.hasDedicatedAccount, isTrue);
      expect(WalletSummary.fromWallet(assignedWallet).hasDedicatedAccount, isTrue);
      expect(unassignedWallet.hasDedicatedAccount, isFalse);
      expect(
        WalletSummary.fromWallet(unassignedWallet).hasDedicatedAccount,
        isFalse,
      );
    },
  );

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
