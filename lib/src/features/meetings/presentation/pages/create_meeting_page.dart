import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/home/domain/entities/event.dart';
import 'package:eventa/src/features/meetings/domain/dating_rules.dart';
import 'package:eventa/src/features/meetings/data/meeting_repository.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/profile/domain/premium_limits.dart';
import 'package:eventa/src/features/profile/presentation/pages/places_quiz_page.dart';
import 'package:eventa/src/features/profile/presentation/pages/premium_paywall_page.dart';
import 'package:eventa/src/features/venues/domain/entities/venue.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateMeetingPage extends StatefulWidget {
  const CreateMeetingPage({
    super.key,
    this.venue,
    this.linkedEvent,
    this.initialKind,
  }) : assert(
         venue != null ||
             linkedEvent != null ||
             initialKind == null ||
             initialKind != MeetingKind.unknown,
       );

  final Venue? venue;
  final Event? linkedEvent;
  final MeetingKind? initialKind;

  @override
  State<CreateMeetingPage> createState() => _CreateMeetingPageState();
}

class _CreateMeetingPageState extends State<CreateMeetingPage> {
  final _topicController = TextEditingController();
  final _repo = MeetingRepository();
  MeetingFormat _format = MeetingFormat.coffee;
  MeetingPurpose _purpose = MeetingPurpose.talk;
  MeetingKind _meetingKind = MeetingKind.venue;
  int _maxParticipants = 2;
  RangeValues _datingAgeRange = const RangeValues(21, 35);
  String _datingLookingFor = 'any';
  late DateTime _scheduledAt;
  bool _saving = false;
  bool _profileCityEmpty = false;

  bool get _isEventMeeting => widget.linkedEvent != null;
  bool get _canCreate => _topicController.text.trim().isNotEmpty && !_saving;

  @override
  void initState() {
    super.initState();
    final event = widget.linkedEvent;
    _scheduledAt =
        event?.date.isAfter(DateTime.now()) == true
            ? event!.date
            : DateTime.now().add(const Duration(hours: 3));
    if (_isEventMeeting) {
      _meetingKind = MeetingKind.event;
      _purpose = MeetingPurpose.activity;
      _format = MeetingFormat.walk;
    } else if (widget.initialKind != null) {
      _meetingKind = widget.initialKind!;
    } else {
      _meetingKind = MeetingKind.venue;
    }
    _initDatingDefaults();
  }

  bool get _kindsLockedToEvent => widget.linkedEvent != null;

  List<MeetingKind> get _availableKinds {
    if (widget.linkedEvent != null) return const [MeetingKind.event];
    if (widget.venue != null) {
      return const [MeetingKind.venue, MeetingKind.online, MeetingKind.custom];
    }
    return MeetingKind.creatableValues;
  }

  String _resolveVenueId({required Venue? venue, required Event? event}) {
    switch (_meetingKind) {
      case MeetingKind.dating:
        return 'dating';
      case MeetingKind.online:
        return 'online';
      case MeetingKind.custom:
        return 'custom';
      case MeetingKind.event:
        return event?.id ?? venue?.id ?? '';
      case MeetingKind.venue:
      case MeetingKind.unknown:
        return venue?.id ?? event?.id ?? '';
    }
  }

  String _resolveVenueName({
    required Venue? venue,
    required Event? event,
    required String topic,
  }) {
    switch (_meetingKind) {
      case MeetingKind.dating:
        return 'Dating mode';
      case MeetingKind.online:
        return 'Онлайн';
      case MeetingKind.custom:
        return topic.isEmpty ? 'Своя встреча' : topic;
      case MeetingKind.event:
        return venue?.name ?? event?.place ?? event?.title ?? '';
      case MeetingKind.venue:
      case MeetingKind.unknown:
        return venue?.name ?? event?.place ?? event?.title ?? topic;
    }
  }

  Future<void> _initDatingDefaults() async {
    final uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
    final profile = await ProfilePersistence().read(uid);
    if (!mounted || profile == null) return;
    setState(() {
      _datingLookingFor = profile.lookingFor ?? 'any';
      _profileCityEmpty = profile.city.trim().isEmpty;
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty || topic.length > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            topic.isEmpty
                ? 'Укажите тему / цель встречи'
                : 'Тема — не больше 60 символов',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final auth = getIt<AuthRepository>();
      final uid = await auth.currentUserId() ?? 'user-1';
      final profile = await ProfilePersistence().read(uid);
      final isPremium = profile?.hasActivePremium == true;
      final quota = PremiumQuotaService();
      final canCreate = await quota.canCreateMeeting(
        uid: uid,
        isPremium: isPremium,
      );
      if (!canCreate) {
        if (!mounted) return;
        final bought = await openPremiumPaywall(
          context,
          reason:
              'Лимит бесплатного аккаунта: не больше ${PremiumLimits.freeCreatesPerWeek} групп/встреч в неделю. Оформите Premium, чтобы создавать без ограничений.',
        );
        if (!bought || !mounted) {
          setState(() => _saving = false);
          return;
        }
      }
      if (_meetingKind == MeetingKind.dating) {
        if (!isDatingProfileReady(profile)) {
          if (!mounted) return;
          final quizMissing = profile == null || !isPlacesQuizComplete(profile);
          final goQuiz = await showDialog<bool>(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: const Text('Профиль для дейтинга'),
                  content: Text(
                    quizMissing
                        ? 'Для 1:1 нужен заполненный квиз по местам '
                            '(${placesQuizProgressLabel(profile?.placesQuizAnswers ?? const {})}). '
                            'Также укажите пол, «ищу» и возраст 18+.'
                        : 'Для дейтинг-режима заполните профиль 18+: пол, кого ищете и дату рождения.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Позже'),
                    ),
                    if (quizMissing)
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Пройти квиз'),
                      ),
                  ],
                ),
          );
          if (goQuiz == true && mounted) {
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PlacesQuizPage()));
          }
          return;
        }
      }
      final hostName =
          profile?.name.isNotEmpty == true ? profile!.name : 'Пользователь';

      final event = widget.linkedEvent;
      final venue = widget.venue;

      final draft = Meeting(
        id: 'meeting-${DateTime.now().millisecondsSinceEpoch}',
        venueId: _resolveVenueId(venue: venue, event: event),
        venueName: _resolveVenueName(venue: venue, event: event, topic: topic),
        city: venue?.city ?? event?.city ?? profile?.city ?? '',
        hostUserId: uid,
        hostName: hostName,
        format: _format,
        scheduledAt: _scheduledAt,
        purpose: _purpose,
        topic: topic,
        note: topic,
        meetingKind: _meetingKind,
        linkedEventId: event?.id,
        linkedEventTitle: event?.title,
        maxParticipants: _meetingKind.usesDatingFlow ? 2 : _maxParticipants,
        currentParticipantCount: 1,
        participants: [uid],
        participantStatus: {uid: 'joined'},
        createdAt: DateTime.now(),
        desiredMinAge:
            _meetingKind.usesDatingFlow ? _datingAgeRange.start.round() : null,
        desiredMaxAge:
            _meetingKind.usesDatingFlow ? _datingAgeRange.end.round() : null,
        desiredGender: _meetingKind.usesDatingFlow ? _datingLookingFor : null,
        meetingTags: [
          _meetingKind.name,
          if (_purpose.name.isNotEmpty) _purpose.name,
        ],
      );
      final meeting = await _repo.create(draft);
      await _repo.upsertLocalMirror(meeting);
      await PremiumQuotaService().recordCreate(uid);
      if (!mounted) return;
      Navigator.of(context).pop(meeting);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось создать встречу')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('d MMM yyyy, HH:mm', 'ru').format(_scheduledAt);
    final event = widget.linkedEvent;
    final venue = widget.venue;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _meetingKind == MeetingKind.dating
              ? 'Новая дейтинг-встреча'
              : (_isEventMeeting ? 'Компания на событие' : 'Новая встреча'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_meetingKind == MeetingKind.dating && _profileCityEmpty)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const ListTile(
                leading: Icon(Icons.location_city_outlined),
                title: Text('Функция скоро в вашем городе'),
                subtitle: Text(
                  'Город в профиле не указан — дейтинг 1:1 доступен, '
                  'но подбор по городу пока мягкий. Групповые встречи работают без города.',
                ),
              ),
            ),
          if (event != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.event),
                title: Text(event.title),
                subtitle: Text(
                  '${event.city} · ${event.place}\n'
                  '${DateFormat('d MMM, HH:mm', 'ru').format(event.date)}',
                ),
                isThreeLine: true,
              ),
            )
          else if (venue != null) ...[
            Text(venue.name, style: Theme.of(context).textTheme.titleLarge),
            Text('${venue.type.labelRu} · ${venue.address}'),
          ],
          const SizedBox(height: 20),
          Text('Режим', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                _availableKinds.map((kind) {
                  return ChoiceChip(
                    label: Text(kind.labelRu),
                    selected: _meetingKind == kind,
                    onSelected:
                        _kindsLockedToEvent
                            ? null
                            : (_) => setState(() {
                              _meetingKind = kind;
                              if (kind == MeetingKind.event) {
                                _format = MeetingFormat.walk;
                                _purpose = MeetingPurpose.activity;
                              }
                            }),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Цель встречи', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                MeetingPurpose.values.map((purpose) {
                  return ChoiceChip(
                    label: Text(purpose.labelRu),
                    selected: _purpose == purpose,
                    onSelected: (_) => setState(() => _purpose = purpose),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _topicController,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: 'Тема (обязательно)',
              hintText: _purpose.topicHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_meetingKind != MeetingKind.event) ...[
            const SizedBox(height: 8),
            Text('Формат', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  MeetingFormat.values.map((format) {
                    return ChoiceChip(
                      label: Text(format.labelRu),
                      selected: _format == format,
                      onSelected: (_) => setState(() => _format = format),
                    );
                  }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Когда'),
            subtitle: Text(when),
            trailing: const Icon(Icons.schedule),
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 8),
          if (_meetingKind == MeetingKind.dating) ...[
            Text(
              'Количество участников: 2 (фиксировано)',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Возраст кандидата: ${_datingAgeRange.start.round()} - ${_datingAgeRange.end.round()}',
            ),
            RangeSlider(
              min: 18,
              max: 60,
              divisions: 42,
              values: _datingAgeRange,
              labels: RangeLabels(
                '${_datingAgeRange.start.round()}',
                '${_datingAgeRange.end.round()}',
              ),
              onChanged: (value) => setState(() => _datingAgeRange = value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _datingLookingFor,
              decoration: const InputDecoration(labelText: 'Кого ищу'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Мужчины')),
                DropdownMenuItem(value: 'female', child: Text('Женщины')),
                DropdownMenuItem(value: 'any', child: Text('Любой')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _datingLookingFor = value);
              },
            ),
          ] else ...[
            Text(
              'Сколько человек ищете (включая вас)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                IconButton(
                  onPressed:
                      _maxParticipants > 2
                          ? () => setState(() => _maxParticipants--)
                          : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_maxParticipants',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed:
                      _maxParticipants < 6
                          ? () => setState(() => _maxParticipants++)
                          : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (_saving)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canCreate ? _save : null,
                child: const Text('Создать встречу'),
              ),
            ),
        ],
      ),
    );
  }
}
