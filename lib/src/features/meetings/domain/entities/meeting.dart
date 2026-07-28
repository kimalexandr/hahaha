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
  event;

  String get labelRu => this == MeetingKind.venue ? 'У заведения' : 'К событию';

  static MeetingKind fromString(String? value) {
    return MeetingKind.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MeetingKind.venue,
    );
  }
}

enum MeetingStatus {
  open,
  matched,
  cancelled;

  static MeetingStatus fromString(String? value) {
    return MeetingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MeetingStatus.open,
    );
  }
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
  final List<String> participants;
  final Map<String, String> participantStatus;
  final MeetingStatus status;
  final DateTime createdAt;

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
    this.participants = const [],
    this.participantStatus = const {},
    this.status = MeetingStatus.open,
    required this.createdAt,
  });

  Meeting copyWith({
    int? maxParticipants,
    List<String>? participants,
    Map<String, String>? participantStatus,
    MeetingStatus? status,
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
      participants: participants ?? this.participants,
      participantStatus: participantStatus ?? this.participantStatus,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  int get joinedCount =>
      participantStatus.values.where((s) => s == 'joined').length;

  bool get isFull => joinedCount >= maxParticipants;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venueId': venueId,
      'venueName': venueName,
      'city': city,
      'hostUserId': hostUserId,
      'hostName': hostName,
      'format': format.name,
      'scheduledAt': scheduledAt.toIso8601String(),
      'note': note,
      'purpose': purpose.name,
      'topic': topic,
      'meetingKind': meetingKind.name,
      'linkedEventId': linkedEventId,
      'linkedEventTitle': linkedEventTitle,
      'maxParticipants': maxParticipants,
      'participants': participants,
      'participantStatus': participantStatus,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Meeting.fromMap(Map<dynamic, dynamic> map) {
    final legacyNote = map['note'] as String? ?? '';
    final topic = (map['topic'] as String?)?.trim();
    final rawParticipants = map['participants'];
    final rawStatus = map['participantStatus'];
    final hostId = map['hostUserId'] as String? ?? '';
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
    return Meeting(
      id: map['id'] as String? ?? '',
      venueId: map['venueId'] as String? ?? '',
      venueName: map['venueName'] as String? ?? '',
      city: map['city'] as String? ?? '',
      hostUserId: hostId,
      hostName: map['hostName'] as String? ?? '',
      format: MeetingFormat.fromString(map['format'] as String?),
      scheduledAt: DateTime.parse(
        map['scheduledAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      note: legacyNote,
      purpose: MeetingPurpose.fromString(map['purpose'] as String?),
      topic: (topic != null && topic.isNotEmpty) ? topic : legacyNote,
      meetingKind: MeetingKind.fromString(map['meetingKind'] as String?),
      linkedEventId: map['linkedEventId'] as String?,
      linkedEventTitle: map['linkedEventTitle'] as String?,
      maxParticipants: (map['maxParticipants'] as num?)?.toInt() ?? 2,
      participants: participants,
      participantStatus: statusMap,
      status: MeetingStatus.fromString(map['status'] as String?),
      createdAt: DateTime.parse(
        map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
