import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avotek_flutter/core/theme/app_theme.dart';
import 'package:avotek_flutter/models/user_model.dart';
import 'package:avotek_flutter/widgets/avotek_logo.dart';

void main() {
  group('AVOTEK Brand & Theme Tests', () {
    testWidgets('AvotekBrandAsset renders without distortion', (
      WidgetTester tester,
    ) async {
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

    test('Brand color palette uses a balanced blue identity', () {
      // Primary Cyan & Electric Cyan
      expect(AppColors.primaryCyan, const Color(0xFF1687D9));
      expect(AppColors.electricCyan, const Color(0xFF2A9BE8));

      // Royal Blue & Deep Electric Blue
      expect(AppColors.primaryBlue, const Color(0xFF2563EB));
      expect(AppColors.deepElectricBlue, const Color(0xFF1976C9));

      // Backgrounds: Deep Obsidian & Slate Pearl
      expect(AppColors.darkBg, const Color(0xFF0A0E17));
      expect(AppColors.lightBg, const Color(0xFFF8FAFC));
    });

    test('Avotek IDs are stable for the same account', () {
      expect(avotekIdFor('user-123'), avotekIdFor('user-123'));
      expect(avotekIdFor('user-123'), isNot(avotekIdFor('user-456')));
    });

    testWidgets('AvotekLogo renders custom circuit painter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvotekLogo(size: 40, isDark: true, useAssetImage: false),
          ),
        ),
      );

      expect(find.byType(AvotekLogo), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
