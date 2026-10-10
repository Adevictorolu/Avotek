import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avotek_flutter/core/theme/app_theme.dart';
import 'package:avotek_flutter/widgets/avotek_logo.dart';

void main() {
  group('AVOTEK Brand & Theme Tests', () {
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

    test('Brand color palette enforces Electric Cyan and Royal Blue identity', () {
      // Primary Cyan & Electric Cyan
      expect(AppColors.primaryCyan, const Color(0xFF00A3FF));
      expect(AppColors.electricCyan, const Color(0xFF00D2FF));

      // Royal Blue & Deep Electric Blue
      expect(AppColors.primaryBlue, const Color(0xFF0052FF));
      expect(AppColors.deepElectricBlue, const Color(0xFF0084D6));

      // Backgrounds: Deep Obsidian & Slate Pearl
      expect(AppColors.darkBg, const Color(0xFF0A0E17));
      expect(AppColors.lightBg, const Color(0xFFF8FAFC));
    });

    testWidgets('AvotekLogo renders custom circuit painter', (WidgetTester tester) async {
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
