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

  /// free | paid — soft monetization (Premium), без платёжного провайдера.
  final String billingTier;

  /// Продвижение в карточке события (обычно при paid / Premium).
  final bool promoted;

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
    this.billingTier = 'free',
    this.promoted = false,
  });

  bool get isActive => status == 'active';
  bool get isPaid => billingTier == 'paid';
  bool get isPromoted => promoted || isPaid;

  String get billingLabelRu => isPaid ? 'Premium / оплачено' : 'Бесплатно';

  EventMeetupCampaign copyWith({
    List<String>? linkedMeetingIds,
    String? status,
    String? billingTier,
    bool? promoted,
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
      billingTier: billingTier ?? this.billingTier,
      promoted: promoted ?? this.promoted,
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
      'billingTier': billingTier,
      'promoted': promoted,
    };
  }

  factory EventMeetupCampaign.fromMap(Map<dynamic, dynamic> map) {
    final rawMeetings = map['linkedMeetingIds'];
    final tier = map['billingTier']?.toString() ?? 'free';
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
      billingTier: tier == 'paid' ? 'paid' : 'free',
      promoted: map['promoted'] as bool? ?? tier == 'paid',
    );
  }
}
