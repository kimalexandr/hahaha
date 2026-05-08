class UserProfile {
  final String id;
  final DateTime createdAt;
  final String ownerId;
  final String name;
  final String bio;
  final String role;

  const UserProfile({
    required this.id,
    required this.createdAt,
    required this.ownerId,
    required this.name,
    required this.bio,
    required this.role,
  });

  UserProfile copyWith({String? name, String? bio, String? role}) {
    return UserProfile(
      id: id,
      createdAt: createdAt,
      ownerId: ownerId,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      role: role ?? this.role,
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
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      ownerId: map['ownerId'] as String,
      name: map['name'] as String,
      bio: map['bio'] as String,
      role: map['role'] as String? ?? 'user',
    );
  }
}
