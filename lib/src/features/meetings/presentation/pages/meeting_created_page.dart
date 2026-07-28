import 'package:eventa/src/features/home/domain/entities/event.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:eventa/src/features/meetings/presentation/pages/meeting_candidates_page.dart';
import 'package:eventa/src/features/venues/domain/entities/venue.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MeetingCreatedPage extends StatelessWidget {
  const MeetingCreatedPage({
    super.key,
    required this.meeting,
    this.venue,
    this.event,
  });

  final Meeting meeting;
  final Venue? venue;
  final Event? event;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat(
      'd MMM yyyy, HH:mm',
      'ru',
    ).format(meeting.scheduledAt);
    final title =
        event?.title ??
        venue?.name ??
        meeting.linkedEventTitle ??
        meeting.venueName;

    return Scaffold(
      appBar: AppBar(title: const Text('Встреча создана')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              meeting.topic.isEmpty ? 'Без темы' : meeting.topic,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Тип: ${meeting.meetingKind.labelRu}'),
            Text('Цель: ${meeting.purpose.labelRu}'),
            Text('Формат: ${meeting.format.labelRu}'),
            Text('Компания: ${meeting.joinedCount}/${meeting.maxParticipants}'),
            Text('Когда: $when'),
            Text('Организатор: ${meeting.hostName}'),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MeetingCandidatesPage(meeting: meeting),
                  ),
                );
              },
              icon: const Icon(Icons.people_outline),
              label: const Text('Подобрать компанию'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    );
  }
}
