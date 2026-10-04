import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avotek_flutter/models/education_models.dart';
import 'package:avotek_flutter/providers/education_provider.dart';
import 'package:avotek_flutter/widgets/status_badge.dart';
import 'package:avotek_flutter/widgets/daily_challenge_card.dart';
import 'package:provider/provider.dart';

void main() {
  group('Avotek V2 Education & Exam Center Suite', () {
    late EducationProvider eduProvider;

    setUp(() {
      eduProvider = EducationProvider();
    });

    test('Subject catalog loads core Nigerian curriculum subjects', () {
      expect(eduProvider.subjects.isNotEmpty, isTrue);
      final subjectNames = eduProvider.subjects.map((s) => s.name).toList();
      expect(subjectNames, contains('Mathematics'));
      expect(subjectNames, contains('English Language'));
      expect(subjectNames, contains('Physics'));
      expect(subjectNames, contains('Chemistry'));
      expect(subjectNames, contains('Biology'));
      expect(subjectNames, contains('Economics'));
      expect(subjectNames, contains('Government'));
      expect(subjectNames, contains('Literature in English'));
      expect(subjectNames, contains('Computer Studies'));
    });

    test('Topic and question hierarchy is backend-model driven', () {
      final mathsTopics = eduProvider.getTopicsForSubject('maths');
      expect(mathsTopics.isNotEmpty, isTrue);
      expect(mathsTopics.first.title, contains('Algebraic'));

      final practiceQuestions = eduProvider.getQuestionsForPractice(
        subjectId: 'maths',
        count: 5,
      );
      expect(practiceQuestions.isNotEmpty, isTrue);
      expect(practiceQuestions.length, lessThanOrEqualTo(5));
      expect(practiceQuestions.first.options.length, equals(4));
    });

    test("Today's Challenge handles option selection and streak calculation", () {
      expect(eduProvider.todayChallenge, isNotNull);
      final challenge = eduProvider.todayChallenge!;
      final initialStreak = eduProvider.challengeStreak;

      // Select correct option
      eduProvider.selectChallengeOption(challenge.correctOptionIndex);
      expect(eduProvider.selectedChallengeOption, equals(challenge.correctOptionIndex));

      final isCorrect = eduProvider.submitChallenge();
      expect(isCorrect, isTrue);
      expect(eduProvider.challengeSubmitted, isTrue);
      expect(eduProvider.challengeStreak, equals(initialStreak + 1));
    });

    test('Practice quiz attempts accurately update student progress', () {
      final initialAttempts = eduProvider.attempts.length;
      eduProvider.recordPracticeAttempt(
        subjectId: 'physics',
        subjectName: 'Physics',
        totalQuestions: 10,
        correctCount: 9,
      );

      expect(eduProvider.attempts.length, equals(initialAttempts + 1));
      expect(eduProvider.attempts.first.scorePercentage, equals(90.0));
      expect(eduProvider.totalQuestionsAttempted, greaterThan(0));
      expect(eduProvider.averageScore, greaterThan(0));
    });

    test('Exam Centre PIN Vault stores and retrieves purchased tokens', () {
      final initialPinsCount = eduProvider.purchasedPins.length;
      final newPin = ExamPinItem(
        id: 'test-pin-101',
        examType: 'NECO',
        title: 'NECO Result Token',
        pinCode: 'NECO-9988-1122-3344',
        serialNumber: 'NC26194821',
        amount: 1200.0,
        purchaseDate: DateTime.now(),
        reference: 'TX-TEST-NECO-01',
      );

      eduProvider.addPurchasedPin(newPin);
      expect(eduProvider.purchasedPins.length, equals(initialPinsCount + 1));
      expect(eduProvider.purchasedPins.first.examType, equals('NECO'));
    });

    test('Student Profile manages status badge and mode toggling', () {
      expect(eduProvider.studentStatusBadge, equals('SS2 • Science'));
      expect(eduProvider.profile.isStudentMode, isTrue);

      eduProvider.toggleStudentMode();
      expect(eduProvider.profile.isStudentMode, isFalse);

      eduProvider.updateProfile(classLevel: 'SS3', department: 'Commercial');
      expect(eduProvider.studentStatusBadge, equals('SS3 • Commercial'));
    });

    testWidgets('StatusBadge renders appropriate colors and labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge.success('Delivered'),
                StatusBadge.academic('SS2 • Science'),
                StatusBadge.pending('Processing'),
                StatusBadge.failed('Refunded'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('SS2 • Science'), findsOneWidget);
      expect(find.text('Processing'), findsOneWidget);
      expect(find.text('Refunded'), findsOneWidget);
    });

    testWidgets("DailyChallengeCard renders interactive options", (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<EducationProvider>.value(
          value: eduProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: DailyChallengeCard(),
            ),
          ),
        ),
      );

      expect(find.text("Today's Challenge"), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
