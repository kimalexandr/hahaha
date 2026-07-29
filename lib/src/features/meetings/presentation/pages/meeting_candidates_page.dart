import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/core/meetings_backend_config.dart';
import 'package:eventa/src/core/widgets/app_user_avatar.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/chat/presentation/pages/meeting_chat_page.dart';
import 'package:eventa/src/features/meetings/data/demo_candidate_catalog.dart';
import 'package:eventa/src/features/meetings/data/meeting_interest_storage.dart';
import 'package:eventa/src/features/meetings/data/meeting_repository.dart';
import 'package:eventa/src/features/meetings/domain/compatibility_score.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:eventa/src/features/profile/domain/premium_limits.dart';
import 'package:eventa/src/features/profile/presentation/pages/premium_paywall_page.dart';
import 'package:eventa/src/features/profile/presentation/pages/public_profile_page.dart';
import 'package:flutter/material.dart';

class MeetingCandidatesPage extends StatefulWidget {
  const MeetingCandidatesPage({super.key, required this.meeting});

  final Meeting meeting;

  @override
  State<MeetingCandidatesPage> createState() => _MeetingCandidatesPageState();
}

class _MeetingCandidatesPageState extends State<MeetingCandidatesPage> {
  final _interestStorage = MeetingInterestStorage();
  final _repo = MeetingRepository();
  UserProfile? _me;
  Meeting? _meeting;
  List<_CandidateView> _candidates = [];
  bool _loading = true;
  bool _verifiedOnly = false;
  bool _joining = false;
  String? _uid;

  Meeting get meeting => _meeting ?? widget.meeting;

  @override
  void initState() {
    super.initState();
    _meeting = widget.meeting;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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

    final fresh = await _repo.readById(widget.meeting.id) ?? widget.meeting;
    final participantIds = await _repo.participantIds(fresh.id);

    List<UserProfile> people = [];
    final eventId = fresh.linkedEventId;
    if (useFirestoreForMeetings && eventId != null && eventId.isNotEmpty) {
      people = await _repo.liveEventCandidates(
        eventId: eventId,
        excludeUids: {...participantIds, uid},
      );
    }
    if (people.isEmpty) {
      people =
          DemoCandidateCatalog.all(excludeOwnerId: uid)
              .where(
                (p) =>
                    p.readyForMeeting &&
                    !participantIds.contains(p.ownerId) &&
                    (p.city.isEmpty ||
                        p.city.toLowerCase() == fresh.city.toLowerCase()) &&
                    (!_verifiedOnly || p.phoneVerified),
              )
              .toList();
    } else if (_verifiedOnly) {
      people = people.where((p) => p.phoneVerified).toList();
    }

    final views = <_CandidateView>[];
    for (final person in people) {
      final interested = await _interestStorage.hasInterest(
        meetingId: fresh.id,
        fromUserId: uid,
        toUserId: person.ownerId,
      );
      final score = CompatibilityScore.byInterests(
        me.interests,
        person.interests,
      );
      views.add(
        _CandidateView(
          profile: person,
          score: score,
          shared: CompatibilityScore.sharedInterests(me, person),
          interested: interested,
        ),
      );
    }
    views.sort((a, b) => b.score.compareTo(a.score));

    if (!mounted) return;
    setState(() {
      _uid = uid;
      _me = me;
      _meeting = fresh;
      _candidates = views;
      _loading = false;
    });
  }

  Future<void> _joinMyself() async {
    final uid = _uid;
    final me = _me;
    if (uid == null || me == null || _joining) return;
    setState(() => _joining = true);
    try {
      final updated = await _repo.join(
        meetingId: meeting.id,
        uid: uid,
        compatibilityScore: 100,
      );
      if (!mounted) return;
      setState(() => _meeting = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Вы в компании (${updated.joinedCount}/${updated.maxParticipants})',
          ),
        ),
      );
      await _openChat();
    } on MeetingFullException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Место уже заняли')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось вступить')));
    } finally {
      if (mounted) setState(() => _joining = false);
      await _load();
    }
  }

  Future<void> _inviteOrJoinDemo(_CandidateView candidate) async {
    final uid = _uid;
    if (uid == null) return;

    if (meeting.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Набор на встречу уже закрыт')),
      );
      return;
    }

    final me = _me;
    final isPremium = me?.hasActivePremium == true;
    final quota = PremiumQuotaService();
    final allowed = await quota.canInvite(uid: uid, isPremium: isPremium);
    if (!allowed) {
      if (!mounted) return;
      await openPremiumPaywall(
        context,
        reason:
            'Лимит бесплатного аккаунта: не больше ${PremiumLimits.freeInvitesPerWeek} приглашений в неделю. Оформите Premium для безлимита.',
      );
      return;
    }

    try {
      if (useFirestoreForMeetings) {
        // Создатель приглашает; кандидат потом join'ится сам.
        await _repo.invite(
          meetingId: meeting.id,
          uid: candidate.profile.ownerId,
          compatibilityScore: candidate.score,
        );
        await _interestStorage.expressInterest(
          meetingId: meeting.id,
          fromUserId: uid,
          toUserId: candidate.profile.ownerId,
        );
        await quota.recordInvite(uid);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Приглашение отправлено: ${candidate.profile.name}'),
          ),
        );
      } else {
        // Hive-демо: добавляем кандидата сразу.
        await _repo.join(
          meetingId: meeting.id,
          uid: candidate.profile.ownerId,
          compatibilityScore: candidate.score,
        );
        await _interestStorage.expressInterest(
          meetingId: meeting.id,
          fromUserId: uid,
          toUserId: candidate.profile.ownerId,
        );
        await quota.recordInvite(uid);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${candidate.profile.name} добавлен(а) в компанию'),
          ),
        );
        await _openChat(peerName: candidate.profile.name);
      }
    } on MeetingFullException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Место уже заняли')));
    }
    await _load();
  }

  Future<void> _openChat({String? peerName}) async {
    final uid = _uid;
    if (uid == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => MeetingChatPage(
              meetingId: meeting.id,
              myUserId: uid,
              title:
                  peerName ??
                  (meeting.topic.isEmpty ? meeting.venueName : meeting.topic),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iAmJoined =
        meeting.participantStatus[_uid] == 'joined' ||
        meeting.participants.contains(_uid);

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
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          '${meeting.topic.isEmpty ? meeting.venueName : meeting.topic}\n'
                          '${meeting.purpose.labelRu} · ${meeting.format.labelRu} · '
                          '${meeting.joinedCount}/${meeting.maxParticipants} чел. · '
                          '${meeting.venueName}\n'
                          'Ваши интересы: ${(_me?.interests ?? const []).join(', ')}',
                        ),
                      ),
                    ),
                  ),
                  if (!iAmJoined)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: FilledButton(
                        onPressed: _joining ? null : _joinMyself,
                        child: Text(
                          _joining ? 'Вступаем…' : 'Вступить в встречу',
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: OutlinedButton.icon(
                        onPressed: () => _openChat(),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Чат встречи'),
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
                                    onTap: () {
                                      openPublicProfile(
                                        context,
                                        profile: item.profile,
                                      );
                                    },
                                    leading: AppUserAvatar(
                                      photoUrl: item.profile.mainPhotoUrl,
                                      name: item.profile.name,
                                      onTap: () {
                                        openPublicProfile(
                                          context,
                                          profile: item.profile,
                                        );
                                      },
                                    ),
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
                                      'Общее: ${item.shared.isEmpty ? '—' : item.shared.join(', ')}',
                                    ),
                                    isThreeLine: true,
                                    trailing:
                                        item.interested
                                            ? const Icon(
                                              Icons.favorite,
                                              color: Colors.red,
                                            )
                                            : IconButton(
                                              tooltip:
                                                  useFirestoreForMeetings
                                                      ? 'Пригласить'
                                                      : 'В компанию',
                                              onPressed:
                                                  () => _inviteOrJoinDemo(item),
                                              icon: const Icon(
                                                Icons.favorite_border,
                                              ),
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
  });

  final UserProfile profile;
  final int score;
  final List<String> shared;
  final bool interested;
}
