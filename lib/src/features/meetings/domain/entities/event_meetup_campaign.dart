class EventMeetupCampaign {
  final String id;
  final String eventId;
  final String eventTitle;
  final String organizerId;
  final String title;
  final DateTime createdAt;
  final int targetGroupSize;
  final List<String> linkedMeetingIds;
  final String status; // active | closed

  const EventMeetupCampaign({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.organizerId,
    required this.title,
    required this.createdAt,
    this.targetGroupSize = 4,
    this.linkedMeetingIds = const [],
    this.status = 'active',
  });

  bool get isActive => status == 'active';

  EventMeetupCampaign copyWith({
    List<String>? linkedMeetingIds,
    String? status,
  }) {
    return EventMeetupCampaign(
      id: id,
      eventId: eventId,
      eventTitle: eventTitle,
      organizerId: organizerId,
      title: title,
      createdAt: createdAt,
      targetGroupSize: targetGroupSize,
      linkedMeetingIds: linkedMeetingIds ?? this.linkedMeetingIds,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'organizerId': organizerId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'targetGroupSize': targetGroupSize,
      'linkedMeetingIds': linkedMeetingIds,
      'status': status,
    };
  }

  factory EventMeetupCampaign.fromMap(Map<dynamic, dynamic> map) {
    final rawMeetings = map['linkedMeetingIds'];
    return EventMeetupCampaign(
      id: map['id'] as String? ?? '',
      eventId: map['eventId'] as String? ?? '',
      eventTitle: map['eventTitle'] as String? ?? '',
      organizerId: map['organizerId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      targetGroupSize: (map['targetGroupSize'] as num?)?.toInt() ?? 4,
      linkedMeetingIds:
          rawMeetings is List
              ? rawMeetings.map((e) => e.toString()).toList()
              : const [],
      status: map['status'] as String? ?? 'active',
    );
  }
}
