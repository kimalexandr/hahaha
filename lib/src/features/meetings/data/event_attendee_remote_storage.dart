import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventa/src/features/chat/domain/entities/chat_message.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';

class EventAttendee {
  const EventAttendee({
    required this.uid,
    required this.status,
    required this.markedAt,
    required this.interestsSnapshot,
  });

  final String uid;
  final String status;
  final DateTime markedAt;
  final List<String> interestsSnapshot;
}

class EventAttendeeRemoteStorage {
  EventAttendeeRemoteStorage({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _attendees(String eventId) =>
      _firestore.collection('events').doc(eventId).collection('attendees');

  CollectionReference<Map<String, dynamic>> _eventChat(String eventId) =>
      _firestore.collection('events').doc(eventId).collection('eventChat');

  Future<void> setGoing({
    required String eventId,
    required String uid,
    required List<String> interestsSnapshot,
    required bool going,
  }) async {
    final ref = _attendees(eventId).doc(uid);
    if (!going) {
      await ref.delete();
      return;
    }
    await ref.set({
      'status': 'going',
      'markedAt': FieldValue.serverTimestamp(),
      'interestsSnapshot': interestsSnapshot,
    }, SetOptions(merge: true));
  }

  Future<List<EventAttendee>> readGoing({
    required String eventId,
    int limit = 50,
  }) async {
    final snap =
        await _attendees(
          eventId,
        ).where('status', isEqualTo: 'going').limit(limit).get();
    return snap.docs.map((doc) {
      final data = doc.data();
      final raw = data['interestsSnapshot'];
      return EventAttendee(
        uid: doc.id,
        status: data['status'] as String? ?? 'going',
        markedAt:
            (data['markedAt'] is Timestamp)
                ? (data['markedAt'] as Timestamp).toDate()
                : DateTime.now(),
        interestsSnapshot:
            raw is List ? raw.map((e) => e.toString()).toList() : const [],
      );
    }).toList();
  }

  /// Кандидаты как UserProfile из денормализованного interestsSnapshot.
  Future<List<UserProfile>> candidatesAsProfiles({
    required String eventId,
    required Set<String> excludeUids,
    int limit = 50,
  }) async {
    final attendees = await readGoing(eventId: eventId, limit: limit);
    final result = <UserProfile>[];
    for (final a in attendees) {
      if (excludeUids.contains(a.uid)) continue;
      // Подтягиваем имя/город из profiles, интересы — из snapshot.
      final profileDoc =
          await _firestore.collection('profiles').doc(a.uid).get();
      final data = profileDoc.data();
      result.add(
        UserProfile(
          id: a.uid,
          createdAt: a.markedAt,
          ownerId: a.uid,
          name: data?['name'] as String? ?? 'Участник',
          bio: data?['bio'] as String? ?? '',
          role: data?['role'] as String? ?? 'user',
          city: data?['city'] as String? ?? '',
          interests:
              a.interestsSnapshot.isNotEmpty
                  ? a.interestsSnapshot
                  : ((data?['interests'] as List?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      const []),
          readyForMeeting: true,
          phoneVerified: data?['phoneVerified'] == true,
        ),
      );
    }
    return result;
  }

  Stream<List<ChatMessage>> watchEventChat(String eventId) {
    return _eventChat(eventId)
        .orderBy('sentAt')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) {
                final data = doc.data();
                return ChatMessage(
                  id: doc.id,
                  chatId: eventId,
                  senderId: data['senderId'] as String? ?? '',
                  text: data['text'] as String? ?? '',
                  createdAt:
                      data['sentAt'] is Timestamp
                          ? (data['sentAt'] as Timestamp).toDate()
                          : DateTime.now(),
                );
              }).toList(),
        );
  }

  Future<void> sendEventChatMessage({
    required String eventId,
    required String senderId,
    required String text,
  }) async {
    await _eventChat(eventId).add({
      'senderId': senderId,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }
}
