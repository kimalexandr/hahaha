import 'package:hive_flutter/hive_flutter.dart';

/// Локальные «интересы» к людям на встрече. Ключ: meetingId|fromUserId|toUserId.
class MeetingInterestStorage {
  static const String _boxName = 'eventa_meeting_interests';
  static const String _key = 'interests';

  Future<Box<dynamic>> _openBox() async {
    return Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : Hive.openBox(_boxName);
  }

  String _id(String meetingId, String fromUserId, String toUserId) =>
      '$meetingId|$fromUserId|$toUserId';

  Future<Set<String>> _readAll() async {
    final box = await _openBox();
    final raw = box.get(_key);
    if (raw is! List) return {};
    return raw.map((e) => e.toString()).toSet();
  }

  Future<void> _writeAll(Set<String> values) async {
    final box = await _openBox();
    await box.put(_key, values.toList());
  }

  Future<void> expressInterest({
    required String meetingId,
    required String fromUserId,
    required String toUserId,
  }) async {
    final all = await _readAll();
    all.add(_id(meetingId, fromUserId, toUserId));
    await _writeAll(all);
  }

  Future<bool> hasInterest({
    required String meetingId,
    required String fromUserId,
    required String toUserId,
  }) async {
    final all = await _readAll();
    return all.contains(_id(meetingId, fromUserId, toUserId));
  }

  Future<bool> isMutual({
    required String meetingId,
    required String userA,
    required String userB,
  }) async {
    final all = await _readAll();
    return all.contains(_id(meetingId, userA, userB)) &&
        all.contains(_id(meetingId, userB, userA));
  }
}
