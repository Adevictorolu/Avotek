import 'package:flutter_test/flutter_test.dart';
import 'package:avotek_flutter/models/notification_preferences.dart';

void main() {
  group('NotificationPreferences', () {
    test('defaults every channel to disabled', () {
      final preferences = NotificationPreferences.fromUserMetadata(null);

      expect(preferences.emailReceipts, isFalse);
      expect(preferences.pushNotifications, isFalse);
      expect(preferences.whatsappReceipts, isFalse);
    });

    test('loads and serializes opt-in choices', () {
      final preferences = NotificationPreferences.fromUserMetadata({
        'notification_preferences': {
          'email_receipts': true,
          'push_notifications': false,
          'whatsapp_receipts': true,
        },
      });

      expect(preferences.emailReceipts, isTrue);
      expect(preferences.pushNotifications, isFalse);
      expect(preferences.whatsappReceipts, isTrue);
      expect(preferences.toJson(), {
        'email_receipts': true,
        'push_notifications': false,
        'whatsapp_receipts': true,
      });
    });

    test('ignores malformed preference metadata safely', () {
      final preferences = NotificationPreferences.fromUserMetadata({
        'notification_preferences': 'enabled',
      });

      expect(preferences.toJson(), const NotificationPreferences().toJson());
    });
  });
}
