class EventComment {
  const EventComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.authorPhotoUrl,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EventComment.fromMap(Map<dynamic, dynamic> map) {
    return EventComment(
      id: map['id'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Пользователь',
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
      text: map['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Старый формат — просто строка текста.
  factory EventComment.fromLegacy(String text, {int index = 0}) {
    return EventComment(
      id: 'legacy-$index',
      authorId: '',
      authorName: 'Гость',
      text: text,
      createdAt: DateTime.now(),
    );
  }
}
