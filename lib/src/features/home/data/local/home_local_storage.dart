import 'package:eventa/src/features/home/domain/entities/event.dart';
import 'package:eventa/src/features/home/domain/entities/event_comment.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeLocalStorage {
  static const String _boxName = 'eventa_app';
  static const String _eventsKey = 'events';
  static const String _profileKey = 'profile';
  static const String _commentsKey = 'comments';
  static const String _notificationsKey = 'notifications';

  Future<Box<dynamic>> _openBox() async {
    return Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : Hive.openBox(_boxName);
  }

  Future<void> saveEvents(List<Event> events) async {
    final box = await _openBox();
    await box.put(_eventsKey, events.map((e) => e.toMap()).toList());
  }

  Future<List<Event>> readEvents() async {
    final box = await _openBox();
    final raw = box.get(_eventsKey);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Event.fromMap(Map<dynamic, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveProfile(UserProfile profile) async {
    final box = await _openBox();
    await box.put(_profileKey, profile.toMap());
  }

  Future<UserProfile?> readProfile() async {
    final box = await _openBox();
    final raw = box.get(_profileKey);
    if (raw is! Map) return null;
    return UserProfile.fromMap(Map<dynamic, dynamic>.from(raw));
  }

  Future<void> saveComments(Map<String, List<EventComment>> comments) async {
    final box = await _openBox();
    final serializable = comments.map(
      (key, value) => MapEntry(key, value.map((e) => e.toMap()).toList()),
    );
    await box.put(_commentsKey, serializable);
  }

  Future<Map<String, List<EventComment>>> readComments() async {
    final box = await _openBox();
    final raw = box.get(_commentsKey);
    if (raw is! Map) return {};
    final result = <String, List<EventComment>>{};
    raw.forEach((key, value) {
      if (value is! List) return;
      final list = <EventComment>[];
      for (var i = 0; i < value.length; i++) {
        final item = value[i];
        if (item is Map) {
          list.add(EventComment.fromMap(Map<dynamic, dynamic>.from(item)));
        } else {
          list.add(EventComment.fromLegacy(item.toString(), index: i));
        }
      }
      result[key.toString()] = list;
    });
    return result;
  }

  Future<void> saveNotifications(List<String> notifications) async {
    final box = await _openBox();
    await box.put(_notificationsKey, notifications);
  }

  Future<List<String>> readNotifications() async {
    final box = await _openBox();
    final raw = box.get(_notificationsKey);
    if (raw is! List) return [];
    return List<String>.from(raw.map((e) => e.toString()));
  }
}
