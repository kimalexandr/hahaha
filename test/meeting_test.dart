import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Meeting serializes format and schedule', () {
    final meeting = Meeting(
      id: 'm1',
      venueId: 'v1',
      venueName: 'Coffee Lab',
      city: 'Almaty',
      hostUserId: 'u1',
      hostName: 'Аня',
      format: MeetingFormat.coffee,
      scheduledAt: DateTime.utc(2026, 8, 1, 15),
      createdAt: DateTime.utc(2026, 7, 28),
    );
    final restored = Meeting.fromMap(meeting.toMap());
    expect(restored.format, MeetingFormat.coffee);
    expect(restored.venueName, 'Coffee Lab');
    expect(restored.scheduledAt.toUtc(), DateTime.utc(2026, 8, 1, 15));
  });
}
