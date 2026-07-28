import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:eventa/src/features/meetings/presentation/pages/create_meeting_page.dart';
import 'package:eventa/src/features/meetings/presentation/pages/meeting_created_page.dart';
import 'package:eventa/src/features/venues/domain/entities/venue.dart';
import 'package:flutter/material.dart';

class VenueDetailsPage extends StatelessWidget {
  const VenueDetailsPage({super.key, required this.venue});

  final Venue venue;

  Future<void> _createMeeting(BuildContext context) async {
    final meeting = await Navigator.of(context).push<Meeting>(
      MaterialPageRoute(builder: (_) => CreateMeetingPage(venue: venue)),
    );
    if (meeting == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeetingCreatedPage(meeting: meeting, venue: venue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(venue.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(venue.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('${venue.type.labelRu} · ${venue.city}'),
          const SizedBox(height: 4),
          Text(venue.address),
          if (venue.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(venue.description),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _createMeeting(context),
              icon: const Icon(Icons.people_outline),
              label: const Text('Найти компанию здесь'),
            ),
          ),
        ],
      ),
    );
  }
}
