import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:eventa/src/features/meetings/presentation/pages/meeting_candidates_page.dart';
import 'package:eventa/src/features/venues/domain/entities/venue.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MeetingCreatedPage extends StatelessWidget {
  const MeetingCreatedPage({
    super.key,
    required this.meeting,
    required this.venue,
  });

  final Meeting meeting;
  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat(
      'd MMM yyyy, HH:mm',
      'ru',
    ).format(meeting.scheduledAt);
    return Scaffold(
      appBar: AppBar(title: const Text('Встреча создана')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(venue.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Формат: ${meeting.format.labelRu}'),
            Text('Когда: $when'),
            Text('Организатор: ${meeting.hostName}'),
            if (meeting.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Комментарий: ${meeting.note}'),
            ],
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
