import 'package:eventa/src/features/meetings/data/meeting_local_storage.dart';
import 'package:eventa/src/features/meetings/domain/entities/meeting.dart';
import 'package:eventa/src/features/meetings/presentation/pages/meeting_candidates_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Каталог локальных встреч с фильтром по цели (purpose).
class MeetingsCatalogPage extends StatefulWidget {
  const MeetingsCatalogPage({super.key});

  @override
  State<MeetingsCatalogPage> createState() => _MeetingsCatalogPageState();
}

class _MeetingsCatalogPageState extends State<MeetingsCatalogPage> {
  final _storage = MeetingLocalStorage();
  List<Meeting> _meetings = [];
  MeetingPurpose? _purposeFilter;
  MeetingKind? _kindFilter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _storage.readAll();
    if (!mounted) return;
    setState(() {
      _meetings = all;
      _loading = false;
    });
  }

  List<Meeting> get _filtered {
    return _meetings.where((m) {
      final purposeOk =
          _purposeFilter == null || m.purpose == _purposeFilter;
      final kindOk = _kindFilter == null || m.meetingKind == _kindFilter;
      return purposeOk && kindOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('Встречи')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Все типы'),
                  selected: _kindFilter == null,
                  onSelected: (_) => setState(() => _kindFilter = null),
                ),
                const SizedBox(width: 8),
                ...MeetingKind.values.map(
                  (kind) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(kind.labelRu),
                      selected: _kindFilter == kind,
                      onSelected: (selected) {
                        setState(() => _kindFilter = selected ? kind : null);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Все цели'),
                  selected: _purposeFilter == null,
                  onSelected: (_) => setState(() => _purposeFilter = null),
                ),
                const SizedBox(width: 8),
                ...MeetingPurpose.values.map(
                  (purpose) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(purpose.labelRu),
                      selected: _purposeFilter == purpose,
                      onSelected: (selected) {
                        setState(
                          () => _purposeFilter = selected ? purpose : null,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                    ? const Center(child: Text('Пока нет встреч'))
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final meeting = items[index];
                        final when = DateFormat(
                          'd MMM, HH:mm',
                          'ru',
                        ).format(meeting.scheduledAt);
                        return Card(
                          child: ListTile(
                            title: Text(
                              meeting.topic.isEmpty
                                  ? meeting.venueName
                                  : meeting.topic,
                            ),
                            subtitle: Text(
                              '${meeting.meetingKind.labelRu} · ${meeting.purpose.labelRu} · ${meeting.format.labelRu}\n'
                              '${meeting.linkedEventTitle ?? meeting.venueName} · $when',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => MeetingCandidatesPage(
                                        meeting: meeting,
                                      ),
                                ),
                              );
                            },
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
