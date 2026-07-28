import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:eventa/src/core/meetings_backend_config.dart';
import 'package:eventa/src/features/chat/data/chat_local_storage.dart';
import 'package:eventa/src/features/chat/data/event_chat_local_storage.dart';
import 'package:eventa/src/features/chat/domain/entities/chat_message.dart';
import 'package:eventa/src/features/meetings/data/event_attendee_remote_storage.dart';
import 'package:eventa/src/features/meetings/data/meeting_local_storage.dart';
import 'package:eventa/src/features/meetings/data/meeting_remote_storage.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';

/// Фасад: Firestore при [useFirestoreForMeetings], иначе Hive.
class MeetingRepository {
  MeetingRepository({
    MeetingLocalStorage? local,
    MeetingRemoteStorage? remote,
    EventAttendeeRemoteStorage? attendees,
    ChatLocalStorage? chatLocal,
    EventChatLocalStorage? eventChatLocal,
  }) : _local = local ?? MeetingLocalStorage(),
       _remoteOrNull = remote,
       _attendeesOrNull = attendees,
       _chatLocal = chatLocal ?? ChatLocalStorage(),
       _eventChatLocal = eventChatLocal ?? EventChatLocalStorage();

  final MeetingLocalStorage _local;
  MeetingRemoteStorage? _remoteOrNull;
  EventAttendeeRemoteStorage? _attendeesOrNull;
  final ChatLocalStorage _chatLocal;
  final EventChatLocalStorage _eventChatLocal;

  bool get _remoteEnabled => useFirestoreForMeetings && appUsesFirebaseBackend;

  MeetingRemoteStorage get _remote => _remoteOrNull ??= MeetingRemoteStorage();

  EventAttendeeRemoteStorage get _attendees =>
      _attendeesOrNull ??= EventAttendeeRemoteStorage();

  Future<Meeting> create(Meeting meeting) async {
    if (_remoteEnabled) {
      return _remote.create(meeting);
    }
    await _local.upsert(meeting);
    return meeting;
  }

  Future<void> upsertLocalMirror(Meeting meeting) => _local.upsert(meeting);

  Future<List<Meeting>> readAll() async {
    if (_remoteEnabled) {
      try {
        return await _remote.readAll();
      } catch (_) {
        return _local.readAll();
      }
    }
    return _local.readAll();
  }

  Future<Meeting?> readById(String id) async {
    if (_remoteEnabled) {
      try {
        return await _remote.readById(id);
      } catch (_) {}
    }
    final all = await _local.readAll();
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<int> countByLinkedEvent(String eventId) async {
    if (_remoteEnabled) {
      try {
        return await _remote.countByLinkedEvent(eventId);
      } catch (_) {}
    }
    return _local.countByLinkedEvent(eventId);
  }

  Future<Meeting> join({
    required String meetingId,
    required String uid,
    required int compatibilityScore,
  }) async {
    if (_remoteEnabled) {
      final updated = await _remote.join(
        meetingId: meetingId,
        uid: uid,
        compatibilityScore: compatibilityScore,
      );
      await _local.upsert(updated);
      return updated;
    }

    final all = await _local.readAll();
    final index = all.indexWhere((m) => m.id == meetingId);
    if (index < 0) throw StateError('meeting_not_found');
    var meeting = all[index];
    if (meeting.isFull) throw const MeetingFullException();
    if (meeting.participantStatus[uid] == 'joined') return meeting;

    final participants = {...meeting.participants, uid}.toList();
    final statuses = Map<String, String>.from(meeting.participantStatus);
    statuses[uid] = 'joined';
    final count = statuses.values.where((s) => s == 'joined').length;
    meeting = meeting.copyWith(
      participants: participants,
      participantStatus: statuses,
      currentParticipantCount: count,
      status:
          count >= meeting.maxParticipants
              ? MeetingStatus.full
              : MeetingStatus.open,
    );
    await _local.upsert(meeting);
    return meeting;
  }

  Future<void> invite({
    required String meetingId,
    required String uid,
    required int compatibilityScore,
  }) async {
    if (_remoteEnabled) {
      await _remote.invite(
        meetingId: meetingId,
        uid: uid,
        compatibilityScore: compatibilityScore,
      );
      return;
    }
    final meeting = await readById(meetingId);
    if (meeting == null) return;
    final statuses = Map<String, String>.from(meeting.participantStatus);
    statuses.putIfAbsent(uid, () => 'invited');
    final participants = {...meeting.participants, uid}.toList();
    await _local.upsert(
      meeting.copyWith(participants: participants, participantStatus: statuses),
    );
  }

  Future<Set<String>> participantIds(String meetingId) async {
    if (_remoteEnabled) {
      try {
        return await _remote.participantIds(meetingId);
      } catch (_) {}
    }
    final meeting = await readById(meetingId);
    return meeting?.participants.toSet() ?? {};
  }

  Future<void> setEventGoing({
    required String eventId,
    required String uid,
    required List<String> interestsSnapshot,
    required bool going,
  }) async {
    if (!_remoteEnabled) return;
    await _attendees.setGoing(
      eventId: eventId,
      uid: uid,
      interestsSnapshot: interestsSnapshot,
      going: going,
    );
  }

  Future<List<UserProfile>> liveEventCandidates({
    required String eventId,
    required Set<String> excludeUids,
  }) async {
    if (!_remoteEnabled) return [];
    return _attendees.candidatesAsProfiles(
      eventId: eventId,
      excludeUids: excludeUids,
    );
  }

  Stream<List<ChatMessage>> watchMeetingChat(String meetingId) {
    if (_remoteEnabled) {
      return _remote.watchChat(meetingId);
    }
    return Stream.fromFuture(_chatLocal.readMessages(meetingId));
  }

  Future<void> sendMeetingChatMessage({
    required String meetingId,
    required String senderId,
    required String text,
  }) async {
    if (_remoteEnabled) {
      await _remote.sendChatMessage(
        meetingId: meetingId,
        senderId: senderId,
        text: text,
      );
      return;
    }
    await _chatLocal.addMessage(
      ChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        chatId: meetingId,
        senderId: senderId,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
  }

  Stream<List<ChatMessage>> watchEventChat(String eventId) {
    if (_remoteEnabled) {
      return _attendees.watchEventChat(eventId);
    }
    return Stream.fromFuture(_eventChatLocal.readMessages(eventId));
  }

  Future<void> sendEventChatMessage({
    required String eventId,
    required String senderId,
    required String text,
  }) async {
    if (_remoteEnabled) {
      await _attendees.sendEventChatMessage(
        eventId: eventId,
        senderId: senderId,
        text: text,
      );
      return;
    }
    await _eventChatLocal.addMessage(
      ChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        chatId: eventId,
        senderId: senderId,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
  }
}
