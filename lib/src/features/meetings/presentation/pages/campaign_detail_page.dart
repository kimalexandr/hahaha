import 'package:eventa/src/features/meetings/data/campaign_repository.dart';
import 'package:eventa/src/features/meetings/data/meeting_repository.dart';
import 'package:eventa/src/features/meetings/domain/entities/event_meetup_campaign.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:flutter/material.dart';

class CampaignDetailPage extends StatefulWidget {
  const CampaignDetailPage({super.key, required this.campaign});

  final EventMeetupCampaign campaign;

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage> {
  List<Meeting> _meetings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await MeetingRepository().readAll();
    final linked =
        all
            .where(
              (m) =>
                  m.linkedEventId == widget.campaign.eventId ||
                  widget.campaign.linkedMeetingIds.contains(m.id),
            )
            .toList();
    if (!mounted) return;
    setState(() {
      _meetings = linked;
      _loading = false;
    });
  }

  Future<void> _closeCampaign() async {
    final updated = widget.campaign.copyWith(status: 'closed');
    await CampaignRepository().upsert(updated);
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final participants = _meetings.fold<int>(
      0,
      (sum, m) => sum + m.joinedCount,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Кампания сбора')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.campaign.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('Событие: ${widget.campaign.eventTitle}'),
                  Text('Статус: ${widget.campaign.status}'),
                  const SizedBox(height: 12),
                  Text('Встреч создано: ${_meetings.length}'),
                  Text('Участников в компаниях: $participants'),
                  const SizedBox(height: 16),
                  Text(
                    'Встречи',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_meetings.isEmpty)
                    const Text('Пока нет встреч по этой кампании')
                  else
                    ..._meetings.map(
                      (m) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(m.topic.isEmpty ? m.venueName : m.topic),
                        subtitle: Text(
                          '${m.joinedCount}/${m.maxParticipants} · ${m.hostName}',
                        ),
                      ),
                    ),
                  if (widget.campaign.isActive) ...[
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: _closeCampaign,
                      child: const Text('Закрыть кампанию'),
                    ),
                  ],
                ],
              ),
    );
  }
}
