import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/meetings/data/meeting_local_storage.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/venues/domain/entities/venue.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateMeetingPage extends StatefulWidget {
  const CreateMeetingPage({super.key, required this.venue});

  final Venue venue;

  @override
  State<CreateMeetingPage> createState() => _CreateMeetingPageState();
}

class _CreateMeetingPageState extends State<CreateMeetingPage> {
  final _noteController = TextEditingController();
  final _storage = MeetingLocalStorage();
  MeetingFormat _format = MeetingFormat.coffee;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 3));
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
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
    setState(() => _saving = true);
    try {
      final auth = getIt<AuthRepository>();
      final uid = await auth.currentUserId() ?? 'user-1';
      final profile = await ProfilePersistence().read(uid);
      final hostName =
          profile?.name.isNotEmpty == true ? profile!.name : 'Пользователь';

      final meeting = Meeting(
        id: 'meeting-${DateTime.now().millisecondsSinceEpoch}',
        venueId: widget.venue.id,
        venueName: widget.venue.name,
        city: widget.venue.city,
        hostUserId: uid,
        hostName: hostName,
        format: _format,
        scheduledAt: _scheduledAt,
        note: _noteController.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Новая встреча')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.venue.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text('${widget.venue.type.labelRu} · ${widget.venue.address}'),
          const SizedBox(height: 20),
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
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Когда'),
            subtitle: Text(when),
            trailing: const Icon(Icons.schedule),
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Комментарий (необязательно)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          if (_saving)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Создать встречу'),
              ),
            ),
        ],
      ),
    );
  }
}
