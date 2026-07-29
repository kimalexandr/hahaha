import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/home/domain/entities/event.dart';
import 'package:eventa/src/features/meetings/domain/dating_rules.dart';
import 'package:eventa/src/features/meetings/data/meeting_repository.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/venues/domain/entities/venue.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateMeetingPage extends StatefulWidget {
  const CreateMeetingPage({super.key, this.venue, this.linkedEvent, this.initialKind})
    : assert(venue != null || linkedEvent != null || initialKind == MeetingKind.dating);

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

  bool get _kindLocked => widget.linkedEvent != null || widget.venue != null;

  Future<void> _initDatingDefaults() async {
    final uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
    final profile = await ProfilePersistence().read(uid);
    if (!mounted || profile == null) return;
    setState(() {
      _datingLookingFor = profile.lookingFor ?? 'any';
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
      if (_meetingKind == MeetingKind.dating) {
        final birthDate = profile?.birthDate;
        if (birthDate == null ||
            calculateAge(birthDate) < 18 ||
            profile?.gender == null ||
            profile?.lookingFor == null ||
            (profile?.placesQuizAnswers.isEmpty ?? true)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Для дейтинг-режима заполните профиль 18+ и квиз по местам',
              ),
            ),
          );
          return;
        }
      }
      final hostName =
          profile?.name.isNotEmpty == true ? profile!.name : 'Пользователь';

      final event = widget.linkedEvent;
      final venue = widget.venue;

      final draft = Meeting(
        id: 'meeting-${DateTime.now().millisecondsSinceEpoch}',
        venueId:
            _meetingKind == MeetingKind.dating
                ? 'dating'
                : (venue?.id ?? event?.id ?? ''),
        venueName:
            _meetingKind == MeetingKind.dating
                ? 'Dating mode'
                : (venue?.name ?? event?.place ?? event?.title ?? ''),
        city: venue?.city ?? event?.city ?? profile?.city ?? '',
        hostUserId: uid,
        hostName: hostName,
        format: _format,
        scheduledAt: _scheduledAt,
        purpose: _purpose,
        topic: topic,
        note: topic,
        meetingKind:
            _meetingKind == MeetingKind.dating
                ? MeetingKind.dating
                : (event != null ? MeetingKind.event : MeetingKind.venue),
        linkedEventId: event?.id,
        linkedEventTitle: event?.title,
        maxParticipants: _meetingKind == MeetingKind.dating ? 2 : _maxParticipants,
        currentParticipantCount: 1,
        participants: [uid],
        participantStatus: {uid: 'joined'},
        createdAt: DateTime.now(),
        desiredMinAge:
            _meetingKind == MeetingKind.dating ? _datingAgeRange.start.round() : null,
        desiredMaxAge:
            _meetingKind == MeetingKind.dating ? _datingAgeRange.end.round() : null,
        desiredGender: _meetingKind == MeetingKind.dating ? _datingLookingFor : null,
      );
      final meeting = await _repo.create(draft);
      await _repo.upsertLocalMirror(meeting);
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
                MeetingKind.values.map((kind) {
                  return ChoiceChip(
                    label: Text(kind.labelRu),
                    selected: _meetingKind == kind,
                    onSelected:
                        _kindLocked
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
