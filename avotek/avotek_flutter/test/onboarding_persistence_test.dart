import 'package:avotek_flutter/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('onboarding completion is persisted on mobile preferences', () async {
    SharedPreferences.setMockInitialValues({});
    await AppDatabaseService.instance.init();

    expect(AppDatabaseService.instance.hasSeenOnboarding(), isFalse);

    await AppDatabaseService.instance.markOnboardingSeen();

    final preferences = await SharedPreferences.getInstance();
    expect(AppDatabaseService.instance.hasSeenOnboarding(), isTrue);
    expect(preferences.getBool('avotek_onboarding_seen_v3'), isTrue);
  });
}
