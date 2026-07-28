import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/chat/data/chat_local_storage.dart';
import 'package:eventa/src/features/chat/presentation/pages/event_chat_page.dart';
import 'package:eventa/src/features/chat/presentation/pages/meeting_chat_page.dart';
import 'package:eventa/src/features/meetings/data/demo_candidate_catalog.dart';
import 'package:eventa/src/features/meetings/data/meeting_interest_storage.dart';
import 'package:eventa/src/features/meetings/data/meeting_local_storage.dart';
import 'package:eventa/src/features/meetings/domain/compatibility_score.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';

class MeetingCandidatesPage extends StatefulWidget {
  const MeetingCandidatesPage({super.key, required this.meeting});

  final Meeting meeting;

  @override
  State<MeetingCandidatesPage> createState() => _MeetingCandidatesPageState();
}

class _MeetingCandidatesPageState extends State<MeetingCandidatesPage> {
  final _interestStorage = MeetingInterestStorage();
  UserProfile? _me;
  List<_CandidateView> _candidates = [];
  bool _loading = true;
  bool _verifiedOnly = false;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
    final me =
        await ProfilePersistence().read(uid) ??
        UserProfile(
          id: uid,
          createdAt: DateTime.now(),
          ownerId: uid,
          name: 'Пользователь',
          bio: '',
          role: 'user',
          city: widget.meeting.city,
          interests: const ['Кофе'],
          readyForMeeting: true,
        );

    final people =
        DemoCandidateCatalog.all(excludeOwnerId: uid)
            .where(
              (p) =>
                  p.readyForMeeting &&
                  (p.city.isEmpty ||
                      p.city.toLowerCase() ==
                          widget.meeting.city.toLowerCase()) &&
                  (!_verifiedOnly || p.phoneVerified),
            )
            .toList();

    final views = <_CandidateView>[];
    for (final person in people) {
      final interested = await _interestStorage.hasInterest(
        meetingId: widget.meeting.id,
        fromUserId: uid,
        toUserId: person.ownerId,
      );
      // Для демо: взаимность симулируем, если уже выразили интерес
      // и у кандидата есть пересечение интересов > 0.
      final score = CompatibilityScore.byInterests(
        me.interests,
        person.interests,
      );
      var mutual = await _interestStorage.isMutual(
        meetingId: widget.meeting.id,
        userA: uid,
        userB: person.ownerId,
      );
      if (interested && score >= 20 && !mutual) {
        // Авто-взаимность для демо, чтобы можно было проверить чат.
        await _interestStorage.expressInterest(
          meetingId: widget.meeting.id,
          fromUserId: person.ownerId,
          toUserId: uid,
        );
        mutual = true;
      }
      views.add(
        _CandidateView(
          profile: person,
          score: score,
          shared: CompatibilityScore.sharedInterests(me, person),
          interested: interested,
          mutual: mutual,
        ),
      );
    }
    views.sort((a, b) => b.score.compareTo(a.score));

    if (!mounted) return;
    setState(() {
      _uid = uid;
      _me = me;
      _candidates = views;
      _loading = false;
    });
  }

  Future<void> _expressInterest(_CandidateView candidate) async {
    final uid = _uid;
    if (uid == null) return;

    // Кандидат присоединяется к группе встречи (не парный мэтч).
    final storage = MeetingLocalStorage();
    var meeting = widget.meeting;
    if (meeting.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Набор на встречу уже закрыт')),
      );
      return;
    }

    final participants =
        {...meeting.participants, uid, candidate.profile.ownerId}.toList();
    final statuses = Map<String, String>.from(meeting.participantStatus);
    statuses[uid] = 'joined';
    statuses[candidate.profile.ownerId] = 'joined';
    meeting = meeting.copyWith(
      participants: participants,
      participantStatus: statuses,
      status:
          participants.where((id) => statuses[id] == 'joined').length >=
                  meeting.maxParticipants
              ? MeetingStatus.matched
              : MeetingStatus.open,
    );
    await storage.upsert(meeting);

    await _interestStorage.expressInterest(
      meetingId: meeting.id,
      fromUserId: uid,
      toUserId: candidate.profile.ownerId,
    );
    // Демо: кандидат тоже «принимает»
    await _interestStorage.expressInterest(
      meetingId: meeting.id,
      fromUserId: candidate.profile.ownerId,
      toUserId: uid,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${candidate.profile.name} добавлен(а) в компанию '
          '(${meeting.joinedCount}/${meeting.maxParticipants})',
        ),
      ),
    );

    if (meeting.maxParticipants > 2) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => EventChatPage(
                eventId: meeting.id,
                eventTitle:
                    meeting.topic.isEmpty ? meeting.venueName : meeting.topic,
              ),
        ),
      );
    } else {
      final chatId = ChatLocalStorage.chatIdFor(
        meetingId: meeting.id,
        userA: uid,
        userB: candidate.profile.ownerId,
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => MeetingChatPage(
                chatId: chatId,
                myUserId: uid,
                peerName: candidate.profile.name,
              ),
        ),
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Компания на встречу')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      '${widget.meeting.topic.isEmpty ? widget.meeting.venueName : widget.meeting.topic}\n'
                      '${widget.meeting.purpose.labelRu} · ${widget.meeting.format.labelRu} · '
                      '${widget.meeting.joinedCount}/${widget.meeting.maxParticipants} чел. · '
                      '${widget.meeting.venueName}\n'
                      'Ваши интересы: ${(_me?.interests ?? const []).join(', ')}',
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Только подтверждённые профили'),
                    value: _verifiedOnly,
                    onChanged: (value) {
                      setState(() => _verifiedOnly = value);
                      _load();
                    },
                  ),
                  Expanded(
                    child:
                        _candidates.isEmpty
                            ? const Center(
                              child: Text('Пока нет подходящих людей'),
                            )
                            : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _candidates.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = _candidates[index];
                                return Card(
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.profile.name} · ${item.score}%',
                                          ),
                                        ),
                                        if (item.profile.phoneVerified)
                                          const Icon(
                                            Icons.verified,
                                            size: 18,
                                            color: Colors.green,
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${item.profile.bio}\n'
                                      'Общее: ${item.shared.isEmpty ? '—' : item.shared.join(', ')}'
                                      '${item.mutual ? '\nВзаимный интерес' : ''}',
                                    ),
                                    isThreeLine: true,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (item.mutual)
                                          IconButton(
                                            tooltip: 'Чат',
                                            onPressed: () {
                                              final uid = _uid;
                                              if (uid == null) return;
                                              final chatId =
                                                  ChatLocalStorage.chatIdFor(
                                                    meetingId:
                                                        widget.meeting.id,
                                                    userA: uid,
                                                    userB: item.profile.ownerId,
                                                  );
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => MeetingChatPage(
                                                        chatId: chatId,
                                                        myUserId: uid,
                                                        peerName:
                                                            item.profile.name,
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.chat_bubble_outline,
                                            ),
                                          ),
                                        item.interested
                                            ? const Icon(
                                              Icons.favorite,
                                              color: Colors.red,
                                            )
                                            : IconButton(
                                              tooltip: 'Интерес',
                                              onPressed:
                                                  () => _expressInterest(item),
                                              icon: const Icon(
                                                Icons.favorite_border,
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}

class _CandidateView {
  _CandidateView({
    required this.profile,
    required this.score,
    required this.shared,
    required this.interested,
    required this.mutual,
  });

  final UserProfile profile;
  final int score;
  final List<String> shared;
  final bool interested;
  final bool mutual;
}
