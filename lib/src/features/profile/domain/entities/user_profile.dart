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
  final bool phoneVerified;
  final DateTime? phoneVerifiedAt;
  final String? gender;
  final DateTime? birthDate;
  final String? lookingFor;
  final String? zodiacSign;
  final Map<String, String> placesQuizAnswers;
  final List<String> profilePhotoUrls;
  final int mainPhotoIndex;

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
    this.phoneVerified = false,
    this.phoneVerifiedAt,
    this.gender,
    this.birthDate,
    this.lookingFor,
    this.zodiacSign,
    this.placesQuizAnswers = const {},
    this.profilePhotoUrls = const [],
    this.mainPhotoIndex = 0,
  });

  UserProfile copyWith({
    String? name,
    String? bio,
    String? role,
    String? city,
    List<String>? interests,
    bool? readyForMeeting,
    bool? phoneVerified,
    DateTime? phoneVerifiedAt,
    String? gender,
    DateTime? birthDate,
    String? lookingFor,
    String? zodiacSign,
    Map<String, String>? placesQuizAnswers,
    List<String>? profilePhotoUrls,
    int? mainPhotoIndex,
    bool clearPhoneVerifiedAt = false,
    bool clearBirthDate = false,
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
      phoneVerified: phoneVerified ?? this.phoneVerified,
      phoneVerifiedAt:
          clearPhoneVerifiedAt
              ? null
              : (phoneVerifiedAt ?? this.phoneVerifiedAt),
      gender: gender ?? this.gender,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      lookingFor: lookingFor ?? this.lookingFor,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      placesQuizAnswers: placesQuizAnswers ?? this.placesQuizAnswers,
      profilePhotoUrls: profilePhotoUrls ?? this.profilePhotoUrls,
      mainPhotoIndex: mainPhotoIndex ?? this.mainPhotoIndex,
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
      'phoneVerified': phoneVerified,
      'phoneVerifiedAt': phoneVerifiedAt?.toIso8601String(),
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'lookingFor': lookingFor,
      'zodiacSign': zodiacSign,
      'placesQuizAnswers': placesQuizAnswers,
      'profilePhotoUrls': profilePhotoUrls,
      'mainPhotoIndex': mainPhotoIndex,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    final rawInterests = map['interests'];
    final verifiedAt = map['phoneVerifiedAt'];
    final rawQuiz = map['placesQuizAnswers'];
    final rawPhotos = map['profilePhotoUrls'];
    final rawBirthDate = map['birthDate'];
    DateTime? parsedBirthDate;
    if (rawBirthDate is DateTime) {
      parsedBirthDate = rawBirthDate;
    } else if (rawBirthDate?.runtimeType.toString() == 'Timestamp') {
      parsedBirthDate = rawBirthDate.toDate() as DateTime?;
    } else if (rawBirthDate is String && rawBirthDate.isNotEmpty) {
      parsedBirthDate = DateTime.tryParse(rawBirthDate);
    }
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
      phoneVerified: map['phoneVerified'] as bool? ?? false,
      phoneVerifiedAt:
          verifiedAt is String && verifiedAt.isNotEmpty
              ? DateTime.tryParse(verifiedAt)
              : null,
      gender: map['gender'] as String?,
      birthDate: parsedBirthDate,
      lookingFor: map['lookingFor'] as String?,
      zodiacSign: map['zodiacSign'] as String?,
      placesQuizAnswers:
          rawQuiz is Map
              ? rawQuiz.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              )
              : const {},
      profilePhotoUrls:
          rawPhotos is List
              ? rawPhotos.map((e) => e.toString()).toList()
              : const [],
      mainPhotoIndex: (map['mainPhotoIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
