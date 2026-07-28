import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/chat/data/chat_local_storage.dart';
import 'package:eventa/src/features/chat/presentation/pages/meeting_chat_page.dart';
import 'package:eventa/src/features/meetings/data/demo_candidate_catalog.dart';
import 'package:eventa/src/features/meetings/data/meeting_interest_storage.dart';
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
                          widget.meeting.city.toLowerCase()),
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
    await _interestStorage.expressInterest(
      meetingId: widget.meeting.id,
      fromUserId: uid,
      toUserId: candidate.profile.ownerId,
    );
    await _load();
    if (!mounted) return;
    final updated = _candidates.where(
      (c) => c.profile.ownerId == candidate.profile.ownerId,
    );
    final mutual = updated.isNotEmpty && updated.first.mutual;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mutual
              ? 'Взаимный интерес с ${candidate.profile.name}!'
              : 'Интерес отправлен',
        ),
      ),
    );
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
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${widget.meeting.venueName} · ${widget.meeting.format.labelRu}\n'
                      'Ваши интересы: ${(_me?.interests ?? const []).join(', ')}',
                    ),
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
                                    title: Text(
                                      '${item.profile.name} · ${item.score}%',
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
