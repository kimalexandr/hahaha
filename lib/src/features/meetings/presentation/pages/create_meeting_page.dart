import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/home/domain/entities/event.dart';
import 'package:eventa/src/features/meetings/data/meeting_local_storage.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/venues/domain/entities/venue.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateMeetingPage extends StatefulWidget {
  const CreateMeetingPage({super.key, this.venue, this.linkedEvent})
    : assert(venue != null || linkedEvent != null);

  final Venue? venue;
  final Event? linkedEvent;

  @override
  State<CreateMeetingPage> createState() => _CreateMeetingPageState();
}

class _CreateMeetingPageState extends State<CreateMeetingPage> {
  final _topicController = TextEditingController();
  final _storage = MeetingLocalStorage();
  MeetingFormat _format = MeetingFormat.coffee;
  MeetingPurpose _purpose = MeetingPurpose.talk;
  int _maxParticipants = 2;
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
      _purpose = MeetingPurpose.activity;
      _format = MeetingFormat.walk;
    }
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
      final hostName =
          profile?.name.isNotEmpty == true ? profile!.name : 'Пользователь';

      final event = widget.linkedEvent;
      final venue = widget.venue;

      final meeting = Meeting(
        id: 'meeting-${DateTime.now().millisecondsSinceEpoch}',
        venueId: venue?.id ?? event?.id ?? '',
        venueName: venue?.name ?? event?.place ?? event?.title ?? '',
        city: venue?.city ?? event?.city ?? '',
        hostUserId: uid,
        hostName: hostName,
        format: _format,
        scheduledAt: _scheduledAt,
        purpose: _purpose,
        topic: topic,
        note: topic,
        meetingKind: event != null ? MeetingKind.event : MeetingKind.venue,
        linkedEventId: event?.id,
        linkedEventTitle: event?.title,
        maxParticipants: _maxParticipants,
        participants: [uid],
        participantStatus: {uid: 'joined'},
        createdAt: DateTime.now(),
      );
      await _storage.upsert(meeting);
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
        title: Text(_isEventMeeting ? 'Компания на событие' : 'Новая встреча'),
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
          if (!_isEventMeeting) ...[
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
              Text('$_maxParticipants', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                onPressed:
                    _maxParticipants < 6
                        ? () => setState(() => _maxParticipants++)
                        : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
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
