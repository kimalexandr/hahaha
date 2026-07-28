import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Meeting serializes purpose and topic', () {
    final meeting = Meeting(
      id: 'm1',
      venueId: 'v1',
      venueName: 'Coffee Lab',
      city: 'Almaty',
      hostUserId: 'u1',
      hostName: 'Аня',
      format: MeetingFormat.coffee,
      scheduledAt: DateTime.utc(2026, 8, 1, 15),
      purpose: MeetingPurpose.hobby,
      topic: 'Обсудить новую книгу',
      createdAt: DateTime.utc(2026, 7, 28),
    );
    final restored = Meeting.fromMap(meeting.toMap());
    expect(restored.format, MeetingFormat.coffee);
    expect(restored.purpose, MeetingPurpose.hobby);
    expect(restored.topic, 'Обсудить новую книгу');
    expect(restored.meetingKind, MeetingKind.venue);
  });

  test('Meeting can link to event', () {
    final meeting = Meeting(
      id: 'm3',
      venueId: 'event-1',
      venueName: 'Central Park',
      city: 'Almaty',
      hostUserId: 'u1',
      hostName: 'Аня',
      format: MeetingFormat.walk,
      scheduledAt: DateTime.utc(2026, 8, 2),
      purpose: MeetingPurpose.activity,
      topic: 'Идём вместе на open-air',
      meetingKind: MeetingKind.event,
      linkedEventId: 'event-1',
      linkedEventTitle: 'Open Air Party',
      createdAt: DateTime.utc(2026, 7, 28),
    );
    final restored = Meeting.fromMap(meeting.toMap());
    expect(restored.meetingKind, MeetingKind.event);
    expect(restored.linkedEventId, 'event-1');
    expect(restored.linkedEventTitle, 'Open Air Party');
  });

  test('Meeting.fromMap falls back topic from legacy note', () {
    final restored = Meeting.fromMap({
      'id': 'm2',
      'venueId': 'v1',
      'venueName': 'Bar',
      'city': 'Astana',
      'hostUserId': 'u1',
      'hostName': 'Bob',
      'format': 'bar',
      'scheduledAt': '2026-08-01T18:00:00.000Z',
      'note': 'Просто поболтать',
      'createdAt': '2026-07-28T10:00:00.000Z',
    });
    expect(restored.topic, 'Просто поболтать');
    expect(restored.purpose, MeetingPurpose.talk);
  });
}
