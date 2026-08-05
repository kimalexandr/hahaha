class CampaignMetrics {
  final int impressions;
  final int detailOpens;
  final int meetingsLinked;
  final int launches;

  const CampaignMetrics({
    this.impressions = 0,
    this.detailOpens = 0,
    this.meetingsLinked = 0,
    this.launches = 0,
  });

  CampaignMetrics copyWith({
    int? impressions,
    int? detailOpens,
    int? meetingsLinked,
    int? launches,
  }) {
    return CampaignMetrics(
      impressions: impressions ?? this.impressions,
      detailOpens: detailOpens ?? this.detailOpens,
      meetingsLinked: meetingsLinked ?? this.meetingsLinked,
      launches: launches ?? this.launches,
    );
  }

  Map<String, dynamic> toMap() => {
    'impressions': impressions,
    'detailOpens': detailOpens,
    'meetingsLinked': meetingsLinked,
    'launches': launches,
  };

  factory CampaignMetrics.fromMap(dynamic raw) {
    if (raw is! Map) return const CampaignMetrics();
    return CampaignMetrics(
      impressions: (raw['impressions'] as num?)?.toInt() ?? 0,
      detailOpens: (raw['detailOpens'] as num?)?.toInt() ?? 0,
      meetingsLinked: (raw['meetingsLinked'] as num?)?.toInt() ?? 0,
      launches: (raw['launches'] as num?)?.toInt() ?? 0,
    );
  }
}

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

  /// Продвижение в карточке события / ленте (обычно при paid / Premium).
  final bool promoted;

  final CampaignMetrics metrics;

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
    this.metrics = const CampaignMetrics(),
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
    CampaignMetrics? metrics,
    int? targetGroupSize,
  }) {
    return EventMeetupCampaign(
      id: id,
      eventId: eventId,
      eventTitle: eventTitle,
      organizerId: organizerId,
      title: title,
      createdAt: createdAt,
      targetGroupSize: targetGroupSize ?? this.targetGroupSize,
      linkedMeetingIds: linkedMeetingIds ?? this.linkedMeetingIds,
      status: status ?? this.status,
      billingTier: billingTier ?? this.billingTier,
      promoted: promoted ?? this.promoted,
      metrics: metrics ?? this.metrics,
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
      'metrics': metrics.toMap(),
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
      metrics: CampaignMetrics.fromMap(map['metrics']),
    );
  }
}
