import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventa/src/features/home/domain/entities/event.dart';
import 'package:eventa/src/features/home/domain/entities/event_comment.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';

class HomeRemoteStorage {
  final FirebaseFirestore _firestore;

  HomeRemoteStorage({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('events');
  CollectionReference<Map<String, dynamic>> get _profilesRef =>
      _firestore.collection('profiles');
  CollectionReference<Map<String, dynamic>> get _commentsRef =>
      _firestore.collection('event_comments');

  Future<List<Event>> readEvents() async {
    final snapshot = await _eventsRef.get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = data['id'] ?? doc.id;
      return Event.fromMap(data);
    }).toList();
  }

  Future<void> upsertEvent(Event event) async {
    await _eventsRef.doc(event.id).set(event.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteEvent(String eventId) async {
    await _eventsRef.doc(eventId).delete();
    await _commentsRef.doc(eventId).delete();
  }

  Future<UserProfile?> readProfile(String ownerId) async {
    final doc = await _profilesRef.doc(ownerId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  Future<List<UserProfile>> readProfiles({int limit = 200}) async {
    final snapshot = await _profilesRef.limit(limit).get();
    return snapshot.docs.map((doc) => UserProfile.fromMap(doc.data())).toList();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _profilesRef
        .doc(profile.ownerId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<Map<String, List<EventComment>>> readCommentsMap() async {
    final snapshot = await _commentsRef.get();
    final result = <String, List<EventComment>>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rawComments = data['comments'];
      if (rawComments is! List) continue;
      final list = <EventComment>[];
      for (var i = 0; i < rawComments.length; i++) {
        final item = rawComments[i];
        if (item is Map) {
          list.add(EventComment.fromMap(Map<dynamic, dynamic>.from(item)));
        } else {
          list.add(EventComment.fromLegacy(item.toString(), index: i));
        }
      }
      result[doc.id] = list;
    }
    return result;
  }

  Future<void> saveCommentsMap(
    Map<String, List<EventComment>> commentsMap,
  ) async {
    final batch = _firestore.batch();
    for (final entry in commentsMap.entries) {
      batch.set(_commentsRef.doc(entry.key), {
        'comments': entry.value.map((e) => e.toMap()).toList(),
      });
    }
    await batch.commit();
  }
}
