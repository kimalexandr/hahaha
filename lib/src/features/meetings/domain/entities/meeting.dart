enum MeetingFormat {
  coffee,
  dinner,
  bar,
  walk;

  String get labelRu {
    switch (this) {
      case MeetingFormat.coffee:
        return 'Кофе';
      case MeetingFormat.dinner:
        return 'Ужин';
      case MeetingFormat.bar:
        return 'Бар';
      case MeetingFormat.walk:
        return 'Прогулка';
    }
  }

  static MeetingFormat fromString(String? value) {
    return MeetingFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MeetingFormat.coffee,
    );
  }
}

enum MeetingPurpose {
  networking,
  hobby,
  talk,
  activity,
  other;

  String get labelRu {
    switch (this) {
      case MeetingPurpose.networking:
        return 'Нетворкинг';
      case MeetingPurpose.hobby:
        return 'Хобби';
      case MeetingPurpose.talk:
        return 'Поболтать';
      case MeetingPurpose.activity:
        return 'Активность';
      case MeetingPurpose.other:
        return 'Другое';
    }
  }

  String get topicHint {
    switch (this) {
      case MeetingPurpose.networking:
        return 'Например: обмен контактами в IT';
      case MeetingPurpose.hobby:
        return 'Например: обсудить книгу, посмотреть матч';
      case MeetingPurpose.talk:
        return 'Например: просто познакомиться за кофе';
      case MeetingPurpose.activity:
        return 'Например: настолки / прогулка по парку';
      case MeetingPurpose.other:
        return 'Кратко опишите цель встречи';
    }
  }

  static MeetingPurpose fromString(String? value) {
    return MeetingPurpose.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MeetingPurpose.talk,
    );
  }
}

enum MeetingKind {
  venue,
  event,
  dating,
  online,
  custom,

  /// Неизвестное значение из Firestore/Hive — не падаем при чтении.
  unknown;

  String get labelRu {
    switch (this) {
      case MeetingKind.venue:
        return 'У заведения';
      case MeetingKind.event:
        return 'К событию';
      case MeetingKind.dating:
        return 'Дейтинг';
      case MeetingKind.online:
        return 'Онлайн';
      case MeetingKind.custom:
        return 'Своя';
      case MeetingKind.unknown:
        return 'Другое';
    }
  }

  /// Типы, которые можно выбрать при создании.
  bool get isCreatable => this != MeetingKind.unknown;

  static List<MeetingKind> get creatableValues =>
      values.where((e) => e.isCreatable).toList();

  /// Дейтинг-флоу (1:1 + квиз), иначе групповые кандидаты.
  bool get usesDatingFlow => this == MeetingKind.dating;

  static MeetingKind fromString(String? value) {
    if (value == null || value.isEmpty) return MeetingKind.venue;
    for (final e in values) {
      if (e.name == value) return e;
    }
    return MeetingKind.unknown;
  }
}

enum MeetingStatus {
  open,
  full,
  closed,
  cancelled,

  /// Legacy Hive: полный набор пары.
  matched;

  static MeetingStatus fromString(String? value) {
    if (value == 'matched') return MeetingStatus.full;
    return MeetingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MeetingStatus.open,
    );
  }
}

class MeetingFullException implements Exception {
  const MeetingFullException();

  @override
  String toString() => 'meeting_full';
}

class Meeting {
  final String id;
  final String venueId;
  final String venueName;
  final String city;
  final String hostUserId;
  final String hostName;
  final MeetingFormat format;
  final DateTime scheduledAt;
  final String note;
  final MeetingPurpose purpose;
  final String topic;
  final MeetingKind meetingKind;
  final String? linkedEventId;
  final String? linkedEventTitle;
  final int maxParticipants;
  final int currentParticipantCount;
  final List<String> participants;
  final Map<String, String> participantStatus;
  final MeetingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? desiredMinAge;
  final int? desiredMaxAge;
  final String? desiredGender;
  final List<String> meetingTags;

  const Meeting({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.city,
    required this.hostUserId,
    required this.hostName,
    required this.format,
    required this.scheduledAt,
    this.note = '',
    this.purpose = MeetingPurpose.talk,
    this.topic = '',
    this.meetingKind = MeetingKind.venue,
    this.linkedEventId,
    this.linkedEventTitle,
    this.maxParticipants = 2,
    this.currentParticipantCount = 1,
    this.participants = const [],
    this.participantStatus = const {},
    this.status = MeetingStatus.open,
    required this.createdAt,
    this.updatedAt,
    this.desiredMinAge,
    this.desiredMaxAge,
    this.desiredGender,
    this.meetingTags = const [],
  });

  String get creatorId => hostUserId;

  String? get linkedVenueId =>
      meetingKind == MeetingKind.venue ? venueId : null;

  Meeting copyWith({
    int? maxParticipants,
    int? currentParticipantCount,
    List<String>? participants,
    Map<String, String>? participantStatus,
    MeetingStatus? status,
    DateTime? updatedAt,
    int? desiredMinAge,
    int? desiredMaxAge,
    String? desiredGender,
    List<String>? meetingTags,
  }) {
    return Meeting(
      id: id,
      venueId: venueId,
      venueName: venueName,
      city: city,
      hostUserId: hostUserId,
      hostName: hostName,
      format: format,
      scheduledAt: scheduledAt,
      note: note,
      purpose: purpose,
      topic: topic,
      meetingKind: meetingKind,
      linkedEventId: linkedEventId,
      linkedEventTitle: linkedEventTitle,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipantCount:
          currentParticipantCount ?? this.currentParticipantCount,
      participants: participants ?? this.participants,
      participantStatus: participantStatus ?? this.participantStatus,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      desiredMinAge: desiredMinAge ?? this.desiredMinAge,
      desiredMaxAge: desiredMaxAge ?? this.desiredMaxAge,
      desiredGender: desiredGender ?? this.desiredGender,
      meetingTags: meetingTags ?? this.meetingTags,
    );
  }

  int get joinedCount {
    if (participantStatus.isNotEmpty) {
      return participantStatus.values.where((s) => s == 'joined').length;
    }
    return currentParticipantCount;
  }

  bool get isFull =>
      status == MeetingStatus.full || joinedCount >= maxParticipants;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venueId': venueId,
      'venueName': venueName,
      'city': city,
      'hostUserId': hostUserId,
      'creatorId': hostUserId,
      'hostName': hostName,
      'format': format.name,
      'scheduledAt': scheduledAt.toIso8601String(),
      'dateTime': scheduledAt.toIso8601String(),
      'note': note,
      'purpose': purpose.name,
      'topic': topic,
      'meetingKind': meetingKind.name,
      // Дубль для гибкой эволюции схемы (string meetingType).
      'meetingType': meetingKind.name,
      'meetingTags': meetingTags,
      'linkedVenueId': linkedVenueId,
      'linkedEventId': linkedEventId,
      'linkedEventTitle': linkedEventTitle,
      'maxParticipants': maxParticipants,
      'currentParticipantCount': currentParticipantCount,
      'participants': participants,
      'participantStatus': participantStatus,
      'status': status == MeetingStatus.matched ? 'full' : status.name,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (desiredMinAge != null) 'desiredMinAge': desiredMinAge,
      if (desiredMaxAge != null) 'desiredMaxAge': desiredMaxAge,
      if (desiredGender != null) 'desiredGender': desiredGender,
    };
  }

  factory Meeting.fromMap(Map<dynamic, dynamic> map) {
    final legacyNote = map['note'] as String? ?? '';
    final topic = (map['topic'] as String?)?.trim();
    final rawParticipants = map['participants'];
    final rawStatus = map['participantStatus'];
    final hostId =
        map['hostUserId'] as String? ?? map['creatorId'] as String? ?? '';
    final participants =
        rawParticipants is List
            ? rawParticipants.map((e) => e.toString()).toList()
            : (hostId.isEmpty ? <String>[] : [hostId]);
    final statusMap = <String, String>{};
    if (rawStatus is Map) {
      rawStatus.forEach((key, value) {
        statusMap[key.toString()] = value.toString();
      });
    } else if (hostId.isNotEmpty) {
      statusMap[hostId] = 'joined';
    }

    final scheduledRaw = map['scheduledAt'] ?? map['dateTime'];
    DateTime scheduledAt;
    if (scheduledRaw is DateTime) {
      scheduledAt = scheduledRaw;
    } else {
      scheduledAt =
          DateTime.tryParse(scheduledRaw?.toString() ?? '') ?? DateTime.now();
    }

    final createdRaw = map['createdAt'];
    DateTime createdAt;
    if (createdRaw is DateTime) {
      createdAt = createdRaw;
    } else {
      createdAt =
          DateTime.tryParse(createdRaw?.toString() ?? '') ?? DateTime.now();
    }

    final count =
        (map['currentParticipantCount'] as num?)?.toInt() ??
        (statusMap.values.where((s) => s == 'joined').isNotEmpty
            ? statusMap.values.where((s) => s == 'joined').length
            : participants.length.clamp(1, 6));

    final rawTags = map['meetingTags'];
    final typeRaw =
        (map['meetingType'] as String?) ?? (map['meetingKind'] as String?);

    return Meeting(
      id: map['id'] as String? ?? '',
      venueId:
          map['venueId'] as String? ??
          map['linkedVenueId'] as String? ??
          map['linkedEventId'] as String? ??
          '',
      venueName: map['venueName'] as String? ?? '',
      city: map['city'] as String? ?? '',
      hostUserId: hostId,
      hostName: map['hostName'] as String? ?? '',
      format: MeetingFormat.fromString(map['format'] as String?),
      scheduledAt: scheduledAt,
      note: legacyNote,
      purpose: MeetingPurpose.fromString(map['purpose'] as String?),
      topic: (topic != null && topic.isNotEmpty) ? topic : legacyNote,
      meetingKind: MeetingKind.fromString(typeRaw),
      linkedEventId: map['linkedEventId'] as String?,
      linkedEventTitle: map['linkedEventTitle'] as String?,
      maxParticipants: (map['maxParticipants'] as num?)?.toInt() ?? 2,
      currentParticipantCount: count,
      participants: participants,
      participantStatus: statusMap,
      status: MeetingStatus.fromString(map['status'] as String?),
      createdAt: createdAt,
      updatedAt:
          map['updatedAt'] is DateTime
              ? map['updatedAt'] as DateTime
              : DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
      desiredMinAge: (map['desiredMinAge'] as num?)?.toInt(),
      desiredMaxAge: (map['desiredMaxAge'] as num?)?.toInt(),
      desiredGender: map['desiredGender'] as String?,
      meetingTags:
          rawTags is List
              ? rawTags.map((e) => e.toString()).toList()
              : const [],
    );
  }
}
