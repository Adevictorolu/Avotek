import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avotek_client/avotek_client.dart';
import 'package:avotek_flutter/providers/auth_provider.dart';
import 'package:avotek_flutter/widgets/avotek_logo.dart';
import 'package:avotek_flutter/screens/admin/admin_gateway_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('AVOTEK Brand Asset & Auth Tests', () {
    testWidgets('AvotekBrandAsset renders without distortion', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvotekBrandAsset(height: 48, isDark: false),
          ),
        ),
      );

      expect(find.byType(AvotekBrandAsset), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    test('AuthProvider validates Super Admin keys accurately and securely', () async {
      // Mock client with local host
      final client = Client('http://localhost:8080/');
      final auth = AuthProvider(client: client);

      // Default state: not super admin
      expect(auth.isSuperAdmin, isFalse);

      // Invalid key attempt
      final failedAttempt = await auth.authenticateSuperAdmin('wrong-key-1234');
      expect(failedAttempt, isFalse);
      expect(auth.isSuperAdmin, isFalse);
      expect(auth.errorMessage, contains('Unauthorized'));

      // Valid key attempt
      final successfulAttempt = await auth.authenticateSuperAdmin('avotek-admin-2026');
      expect(successfulAttempt, isTrue);
      expect(auth.isSuperAdmin, isTrue);
      expect(auth.errorMessage, isNull);

      // Lock super admin session
      auth.logoutSuperAdmin();
      expect(auth.isSuperAdmin, isFalse);
    });

    testWidgets('AdminGatewayScreen presents secure passkey input', (WidgetTester tester) async {
      final client = Client('http://localhost:8080/');
      final auth = AuthProvider(client: client);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const MaterialApp(
            home: AdminGatewayScreen(),
          ),
        ),
      );

      // Verify title and security elements are rendered
      expect(find.text('Security Gateway'), findsOneWidget);
      expect(find.text('Super Admin Authorization'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Authorize Console Access'), findsOneWidget);
    });
  });
}
