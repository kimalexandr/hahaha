import 'package:eventa/src/features/push/domain/notification_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NotificationSettings defaults are enabled', () {
    const settings = NotificationSettings();
    expect(settings.meetingChat, isTrue);
    expect(settings.meetingJoined, isTrue);
    expect(settings.eventChatDigest, isTrue);
    expect(settings.campaignUpdates, isTrue);
  });

  test('NotificationSettings round-trip map', () {
    final restored = NotificationSettings.fromMap({
      'meetingChat': false,
      'meetingJoined': true,
      'eventChatDigest': false,
      'campaignUpdates': true,
    });
    expect(restored.meetingChat, isFalse);
    expect(restored.eventChatDigest, isFalse);
    expect(restored.toMap()['meetingJoined'], isTrue);
  });
}
