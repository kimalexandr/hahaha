class UserProfile {
  final String id;
  final DateTime createdAt;
  final String ownerId;
  final String name;
  final String bio;
  final String role;
  final String city;
  final List<String> interests;
  final bool readyForMeeting;

  const UserProfile({
    required this.id,
    required this.createdAt,
    required this.ownerId,
    required this.name,
    required this.bio,
    required this.role,
    this.city = '',
    this.interests = const [],
    this.readyForMeeting = false,
  });

  UserProfile copyWith({
    String? name,
    String? bio,
    String? role,
    String? city,
    List<String>? interests,
    bool? readyForMeeting,
  }) {
    return UserProfile(
      id: id,
      createdAt: createdAt,
      ownerId: ownerId,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      city: city ?? this.city,
      interests: interests ?? this.interests,
      readyForMeeting: readyForMeeting ?? this.readyForMeeting,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'ownerId': ownerId,
      'name': name,
      'bio': bio,
      'role': role,
      'city': city,
      'interests': interests,
      'readyForMeeting': readyForMeeting,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    final rawInterests = map['interests'];
    return UserProfile(
      id: map['id'] as String? ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? 'Пользователь',
      bio: map['bio'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      city: map['city'] as String? ?? '',
      interests:
          rawInterests is List
              ? rawInterests.map((e) => e.toString()).toList()
              : const [],
      readyForMeeting: map['readyForMeeting'] as bool? ?? false,
    );
  }
}
