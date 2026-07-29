import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/chat/presentation/pages/meeting_chat_page.dart';
import 'package:eventa/src/features/home/data/remote/home_remote_storage.dart';
import 'package:eventa/src/features/meetings/data/demo_candidate_catalog.dart';
import 'package:eventa/src/features/meetings/data/meeting_interest_storage.dart';
import 'package:eventa/src/features/meetings/data/meeting_repository.dart';
import 'package:eventa/src/features/meetings/domain/dating_rules.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';

class DatingCandidateListPage extends StatefulWidget {
  const DatingCandidateListPage({super.key, required this.meeting});

  final Meeting meeting;

  @override
  State<DatingCandidateListPage> createState() => _DatingCandidateListPageState();
}

class _DatingCandidateListPageState extends State<DatingCandidateListPage> {
  final _repo = MeetingRepository();
  final _interestStorage = MeetingInterestStorage();
  String _genderFilter = 'any';
  RangeValues _ageFilter = const RangeValues(18, 60);
  bool _loading = true;
  String? _uid;
  List<_DatingCandidateView> _candidates = [];

  @override
  void initState() {
    super.initState();
    _genderFilter = widget.meeting.desiredGender ?? 'any';
    _ageFilter = RangeValues(
      (widget.meeting.desiredMinAge ?? 18).toDouble(),
      (widget.meeting.desiredMaxAge ?? 60).toDouble(),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
    final me = await ProfilePersistence().read(uid);
    if (me == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _candidates = [];
      });
      return;
    }
    final excluded = await _repo.participantIds(widget.meeting.id);
    excluded.add(uid);
    List<UserProfile> people = [];
    if (appUsesFirebaseBackend) {
      try {
        people = await HomeRemoteStorage().readProfiles();
      } catch (_) {}
    }
    if (people.isEmpty) {
      people = DemoCandidateCatalog.all(excludeOwnerId: uid);
    }
    final views = <_DatingCandidateView>[];
    for (final person in people) {
      if (excluded.contains(person.ownerId)) continue;
      if (person.birthDate == null || calculateAge(person.birthDate!) < 18) continue;
      if (_genderFilter != 'any' && person.gender != _genderFilter) continue;
      final age = calculateAge(person.birthDate!);
      if (age < _ageFilter.start.round() || age > _ageFilter.end.round()) continue;
      final interested = await _interestStorage.hasInterest(
        meetingId: widget.meeting.id,
        fromUserId: uid,
        toUserId: person.ownerId,
      );
      final score = datingCompatibilityScore(me, person);
      views.add(
        _DatingCandidateView(
          profile: person,
          scorePercent: (score * 100).round(),
          age: age,
          interested: interested,
          hooks: _quizHooks(me, person),
        ),
      );
    }
    views.sort((a, b) => b.scorePercent.compareTo(a.scorePercent));
    if (!mounted) return;
    setState(() {
      _uid = uid;
      _candidates = views;
      _loading = false;
    });
  }

  List<String> _quizHooks(UserProfile a, UserProfile b) {
    final hooks = <String>[];
    for (final entry in a.placesQuizAnswers.entries) {
      final other = b.placesQuizAnswers[entry.key];
      if (other != null && other == entry.value) {
        hooks.add('Вы оба выбрали: ${entry.value}');
      }
      if (hooks.length == 2) break;
    }
    return hooks;
  }

  Future<void> _invite(_DatingCandidateView candidate) async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.invite(
      meetingId: widget.meeting.id,
      uid: candidate.profile.ownerId,
      compatibilityScore: candidate.scorePercent,
    );
    await _interestStorage.expressInterest(
      meetingId: widget.meeting.id,
      fromUserId: uid,
      toUserId: candidate.profile.ownerId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Приглашение отправлено: ${candidate.profile.name}')),
    );
    await _load();
  }

  Future<void> _openChat() async {
    final uid = _uid;
    if (uid == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => MeetingChatPage(
              meetingId: widget.meeting.id,
              myUserId: uid,
              title: widget.meeting.topic,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дейтинг-подбор')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _genderFilter,
                                    decoration: const InputDecoration(
                                      labelText: 'Пол кандидата',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'male',
                                        child: Text('Мужчины'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'female',
                                        child: Text('Женщины'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'any',
                                        child: Text('Любой'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => _genderFilter = value);
                                      _load();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Возраст: ${_ageFilter.start.round()} - ${_ageFilter.end.round()}',
                            ),
                            RangeSlider(
                              min: 18,
                              max: 60,
                              divisions: 42,
                              values: _ageFilter,
                              onChanged: (value) => setState(() => _ageFilter = value),
                              onChangeEnd: (_) => _load(),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: _openChat,
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('Чат встречи'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        _candidates.isEmpty
                            ? const Center(child: Text('Подходящие кандидаты пока не найдены'))
                            : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _candidates.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, index) {
                                final item = _candidates[index];
                                final mainPhoto =
                                    item.profile.profilePhotoUrls.isNotEmpty
                                        ? item.profile.profilePhotoUrls[item.profile
                                            .mainPhotoIndex
                                            .clamp(
                                              0,
                                              item.profile.profilePhotoUrls.length - 1,
                                            )]
                                        : null;
                                return Card(
                                  child: ListTile(
                                    leading:
                                        mainPhoto == null
                                            ? CircleAvatar(
                                              child: Text(
                                                item.profile.name.isEmpty
                                                    ? '?'
                                                    : item.profile.name[0].toUpperCase(),
                                              ),
                                            )
                                            : CircleAvatar(
                                              backgroundImage: NetworkImage(mainPhoto),
                                            ),
                                    title: Text(
                                      '${item.profile.name} · ${item.scorePercent}%',
                                    ),
                                    subtitle: Text(
                                      '${item.age} лет · ${zodiacRuLabel(item.profile.zodiacSign)}\n'
                                      '${item.hooks.isEmpty ? 'Квиз-зацепки появятся после заполнения ответов' : item.hooks.join(' · ')}',
                                    ),
                                    isThreeLine: true,
                                    trailing:
                                        item.interested
                                            ? const Icon(Icons.favorite, color: Colors.red)
                                            : IconButton(
                                              onPressed: () => _invite(item),
                                              icon: const Icon(Icons.favorite_border),
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

class _DatingCandidateView {
  _DatingCandidateView({
    required this.profile,
    required this.scorePercent,
    required this.age,
    required this.interested,
    required this.hooks,
  });

  final UserProfile profile;
  final int scorePercent;
  final int age;
  final bool interested;
  final List<String> hooks;
}
