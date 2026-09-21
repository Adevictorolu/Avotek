import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avotek_flutter/widgets/avotek_logo.dart';

void main() {
  testWidgets('AvotekLogo renders circuit painter and rich text brand mark', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AvotekLogo(size: 32, isDark: false),
        ),
      ),
    );

    expect(find.byType(AvotekLogo), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(RichText), findsOneWidget);
  });
}
