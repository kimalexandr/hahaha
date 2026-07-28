import 'dart:io';

import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:eventa/src/core/meetings_backend_config.dart';
import 'package:eventa/src/features/meetings/data/meeting_repository.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('eventa_meeting_repo');
    Hive.init(dir.path);
    appUsesFirebaseBackend = false;
    useFirestoreForMeetings = false;
  });

  tearDown(() async {
    await Hive.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('Hive join increments count and throws when full', () async {
    final repo = MeetingRepository();
    final meeting = Meeting(
      id: 'm-join',
      venueId: 'v1',
      venueName: 'Cafe',
      city: 'Almaty',
      hostUserId: 'host',
      hostName: 'Host',
      format: MeetingFormat.coffee,
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
      purpose: MeetingPurpose.talk,
      topic: 'Тест join',
      maxParticipants: 2,
      currentParticipantCount: 1,
      participants: const ['host'],
      participantStatus: const {'host': 'joined'},
      createdAt: DateTime.now(),
    );
    await repo.create(meeting);

    final joined = await repo.join(
      meetingId: 'm-join',
      uid: 'guest',
      compatibilityScore: 40,
    );
    expect(joined.joinedCount, 2);
    expect(joined.status, MeetingStatus.full);

    await expectLater(
      repo.join(meetingId: 'm-join', uid: 'other', compatibilityScore: 10),
      throwsA(isA<MeetingFullException>()),
    );
  });

  test('MeetingStatus maps legacy matched to full', () {
    expect(MeetingStatus.fromString('matched'), MeetingStatus.full);
    expect(MeetingStatus.fromString('full'), MeetingStatus.full);
  });
}
