import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MeetingLocalStorage {
  static const String _boxName = 'eventa_meetings';
  static const String _key = 'meetings';

  Future<Box<dynamic>> _openBox() async {
    return Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : Hive.openBox(_boxName);
  }

  Future<List<Meeting>> readAll() async {
    final box = await _openBox();
    final raw = box.get(_key);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Meeting.fromMap(Map<dynamic, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Future<void> upsert(Meeting meeting) async {
    final all = await readAll();
    final index = all.indexWhere((m) => m.id == meeting.id);
    if (index >= 0) {
      all[index] = meeting;
    } else {
      all.add(meeting);
    }
    final box = await _openBox();
    await box.put(_key, all.map((e) => e.toMap()).toList());
  }

  Future<List<Meeting>> readByVenue(String venueId) async {
    final all = await readAll();
    return all.where((m) => m.venueId == venueId).toList();
  }
}
