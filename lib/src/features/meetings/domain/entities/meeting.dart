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
    this.status = MeetingStatus.open,
    required this.createdAt,
  });

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
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Meeting.fromMap(Map<dynamic, dynamic> map) {
    return Meeting(
      id: map['id'] as String? ?? '',
      venueId: map['venueId'] as String? ?? '',
      venueName: map['venueName'] as String? ?? '',
      city: map['city'] as String? ?? '',
      hostUserId: map['hostUserId'] as String? ?? '',
      hostName: map['hostName'] as String? ?? '',
      format: MeetingFormat.fromString(map['format'] as String?),
      scheduledAt: DateTime.parse(
        map['scheduledAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      note: map['note'] as String? ?? '',
      status: MeetingStatus.fromString(map['status'] as String?),
      createdAt: DateTime.parse(
        map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
