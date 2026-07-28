class NotificationSettings {
  const NotificationSettings({
    this.meetingChat = true,
    this.meetingJoined = true,
    this.eventChatDigest = true,
    this.campaignUpdates = true,
  });

  final bool meetingChat;
  final bool meetingJoined;
  final bool eventChatDigest;
  final bool campaignUpdates;

  Map<String, dynamic> toMap() => {
    'meetingChat': meetingChat,
    'meetingJoined': meetingJoined,
    'eventChatDigest': eventChatDigest,
    'campaignUpdates': campaignUpdates,
  };

  factory NotificationSettings.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const NotificationSettings();
    return NotificationSettings(
      meetingChat: map['meetingChat'] as bool? ?? true,
      meetingJoined: map['meetingJoined'] as bool? ?? true,
      eventChatDigest: map['eventChatDigest'] as bool? ?? true,
      campaignUpdates: map['campaignUpdates'] as bool? ?? true,
    );
  }
}
