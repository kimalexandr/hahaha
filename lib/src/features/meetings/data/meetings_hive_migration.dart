import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventa/src/features/meetings/data/meeting_local_storage.dart';
import 'package:eventa/src/features/meetings/data/meeting_remote_storage.dart';

/// Разовая миграция тестовых Hive-встреч → Firestore (batch ≤500).
/// Вызывать вручную из debug/админ-действия при необходимости.
class MeetingsHiveMigration {
  MeetingsHiveMigration({
    MeetingLocalStorage? local,
    MeetingRemoteStorage? remote,
  }) : _local = local ?? MeetingLocalStorage(),
       _remote = remote ?? MeetingRemoteStorage();

  final MeetingLocalStorage _local;
  final MeetingRemoteStorage _remote;

  Future<int> migrateAll() async {
    final meetings = await _local.readAll();
    var migrated = 0;
    for (final meeting in meetings) {
      try {
        final existing = await FirebaseFirestore.instance
            .collection('meetings')
            .doc(meeting.id)
            .get();
        if (existing.exists) continue;
        await _remote.create(meeting);
        migrated++;
      } catch (_) {}
    }
    return migrated;
  }
}
