import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventa/src/features/chat/domain/entities/chat_message.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';

class MeetingRemoteStorage {
  MeetingRemoteStorage({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _meetings =>
      _firestore.collection('meetings');

  DocumentReference<Map<String, dynamic>> _doc(String id) => _meetings.doc(id);

  Future<Meeting> create(Meeting meeting) async {
    final ref = meeting.id.isEmpty ? _meetings.doc() : _doc(meeting.id);
    final id = ref.id;
    final creatorId = meeting.hostUserId;

    final batch = _firestore.batch();
    batch.set(ref, {
      'creatorId': creatorId,
      'hostUserId': creatorId,
      'hostName': meeting.hostName,
      'meetingKind': meeting.meetingKind.name,
      'linkedVenueId': meeting.linkedVenueId,
      'linkedEventId': meeting.linkedEventId,
      'linkedEventTitle': meeting.linkedEventTitle,
      'venueId': meeting.venueId,
      'venueName': meeting.venueName,
      'city': meeting.city,
      'format': meeting.format.name,
      'purpose': meeting.purpose.name,
      'topic': meeting.topic,
      'note': meeting.note,
      'dateTime': Timestamp.fromDate(meeting.scheduledAt),
      'scheduledAt': Timestamp.fromDate(meeting.scheduledAt),
      'maxParticipants': meeting.maxParticipants,
      'currentParticipantCount': 1,
      'status': MeetingStatus.open.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(ref.collection('participants').doc(creatorId), {
      'status': 'joined',
      'joinedAt': FieldValue.serverTimestamp(),
      'compatibilityScore': 100,
    });
    await batch.commit();

    return Meeting(
      id: id,
      venueId: meeting.venueId,
      venueName: meeting.venueName,
      city: meeting.city,
      hostUserId: meeting.hostUserId,
      hostName: meeting.hostName,
      format: meeting.format,
      scheduledAt: meeting.scheduledAt,
      note: meeting.note,
      purpose: meeting.purpose,
      topic: meeting.topic,
      meetingKind: meeting.meetingKind,
      linkedEventId: meeting.linkedEventId,
      linkedEventTitle: meeting.linkedEventTitle,
      maxParticipants: meeting.maxParticipants,
      currentParticipantCount: 1,
      participants: [creatorId],
      participantStatus: {creatorId: 'joined'},
      status: MeetingStatus.open,
      createdAt: meeting.createdAt,
    );
  }

  Future<List<Meeting>> readAll({int limit = 100}) async {
    final snap = await _meetings.orderBy('dateTime').limit(limit).get();
    final result = <Meeting>[];
    for (final doc in snap.docs) {
      result.add(await _hydrate(doc));
    }
    return result;
  }

  Future<Meeting?> readById(String meetingId) async {
    final doc = await _doc(meetingId).get();
    if (!doc.exists) return null;
    return _hydrate(doc);
  }

  Future<int> countByLinkedEvent(String eventId) async {
    final snap =
        await _meetings.where('linkedEventId', isEqualTo: eventId).get();
    return snap.size;
  }

  /// Self-join с транзакцией. Бросает [MeetingFullException].
  Future<Meeting> join({
    required String meetingId,
    required String uid,
    required int compatibilityScore,
  }) async {
    final meetingRef = _doc(meetingId);
    await _firestore.runTransaction((transaction) async {
      final meetingSnap = await transaction.get(meetingRef);
      if (!meetingSnap.exists || meetingSnap.data() == null) {
        throw StateError('meeting_not_found');
      }
      final data = meetingSnap.data()!;
      final current = (data['currentParticipantCount'] as num?)?.toInt() ?? 0;
      final max = (data['maxParticipants'] as num?)?.toInt() ?? 2;
      if (current >= max || data['status'] == MeetingStatus.full.name) {
        throw const MeetingFullException();
      }

      final participantRef = meetingRef.collection('participants').doc(uid);
      final existing = await transaction.get(participantRef);
      final alreadyJoined =
          existing.exists && existing.data()?['status'] == 'joined';
      if (alreadyJoined) return;

      transaction.set(participantRef, {
        'status': 'joined',
        'joinedAt': FieldValue.serverTimestamp(),
        'compatibilityScore': compatibilityScore,
      }, SetOptions(merge: true));

      final newCount = current + 1;
      transaction.update(meetingRef, {
        'currentParticipantCount': newCount,
        'status':
            newCount >= max ? MeetingStatus.full.name : MeetingStatus.open.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final updated = await readById(meetingId);
    if (updated == null) throw StateError('meeting_not_found');
    return updated;
  }

  /// Создатель приглашает кандидата (status: invited).
  Future<void> invite({
    required String meetingId,
    required String uid,
    required int compatibilityScore,
  }) async {
    await _doc(meetingId).collection('participants').doc(uid).set({
      'status': 'invited',
      'joinedAt': null,
      'compatibilityScore': compatibilityScore,
    }, SetOptions(merge: true));
  }

  Future<Set<String>> participantIds(String meetingId) async {
    final snap = await _doc(meetingId).collection('participants').get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Stream<List<ChatMessage>> watchChat(String meetingId) {
    return _doc(meetingId)
        .collection('chat')
        .orderBy('sentAt')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();
            return ChatMessage(
              id: doc.id,
              chatId: meetingId,
              senderId: data['senderId'] as String? ?? '',
              text: data['text'] as String? ?? '',
              createdAt: _asDateTime(data['sentAt']) ?? DateTime.now(),
            );
          }).toList();
        });
  }

  Future<void> sendChatMessage({
    required String meetingId,
    required String senderId,
    required String text,
  }) async {
    await _doc(meetingId).collection('chat').add({
      'senderId': senderId,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Meeting> _hydrate(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['id'] = doc.id;

    final participantsSnap =
        await doc.reference.collection('participants').get();
    final ids = <String>[];
    final statuses = <String, String>{};
    for (final p in participantsSnap.docs) {
      ids.add(p.id);
      statuses[p.id] = p.data()['status'] as String? ?? 'joined';
    }
    data['participants'] = ids;
    data['participantStatus'] = statuses;

    final scheduled = data['dateTime'] ?? data['scheduledAt'];
    data['scheduledAt'] = _asDateTime(scheduled) ?? DateTime.now();
    data['createdAt'] = _asDateTime(data['createdAt']) ?? DateTime.now();
    data['updatedAt'] = _asDateTime(data['updatedAt']);

    return Meeting.fromMap(data);
  }

  DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
