class NotificationPreferences {
  final bool emailReceipts;
  final bool pushNotifications;
  final bool whatsappReceipts;

  const NotificationPreferences({
    this.emailReceipts = false,
    this.pushNotifications = false,
    this.whatsappReceipts = false,
  });

  factory NotificationPreferences.fromUserMetadata(
    Map<String, dynamic>? metadata,
  ) {
    final raw = metadata?['notification_preferences'];
    if (raw is! Map) return const NotificationPreferences();

    return NotificationPreferences(
      emailReceipts: raw['email_receipts'] == true,
      pushNotifications: raw['push_notifications'] == true,
      whatsappReceipts: raw['whatsapp_receipts'] == true,
    );
  }

  Map<String, bool> toJson() => {
    'email_receipts': emailReceipts,
    'push_notifications': pushNotifications,
    'whatsapp_receipts': whatsappReceipts,
  };

  NotificationPreferences copyWith({
    bool? emailReceipts,
    bool? pushNotifications,
    bool? whatsappReceipts,
  }) => NotificationPreferences(
    emailReceipts: emailReceipts ?? this.emailReceipts,
    pushNotifications: pushNotifications ?? this.pushNotifications,
    whatsappReceipts: whatsappReceipts ?? this.whatsappReceipts,
  );
}
