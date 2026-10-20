import 'package:avotek_flutter/widgets/pin_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('transaction PIN modal accepts hardware keyboard input', (
    tester,
  ) async {
    String? submittedPin;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => PinModal.show(
                context,
                title: 'Confirm Purchase',
                amount: 100,
                description: 'Test purchase',
                onPinSubmit: (pin) async {
                  submittedPin = pin;
                  return true;
                },
              ),
              child: const Text('Open PIN'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open PIN'));
    await tester.pumpAndSettle();
    for (final key in [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
    ]) {
      await tester.sendKeyEvent(key);
    }
    await tester.pumpAndSettle();

    expect(submittedPin, '1234');
    expect(find.text('Confirm Purchase'), findsNothing);
  });
}
