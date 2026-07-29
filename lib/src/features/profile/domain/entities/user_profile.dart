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

  /// Номер телефона (если подтверждён или указан).
  final String? phoneNumber;
  final String? gender;
  final DateTime? birthDate;
  final String? lookingFor;
  final String? zodiacSign;
  final Map<String, List<String>> placesQuizAnswers;
  final List<String> profilePhotoUrls;
  final int mainPhotoIndex;

  /// Premium-подписка: без лимитов и без блюра чужих профилей.
  final bool isPremium;

  /// Профиль проверен (телефон или модератором через админку).
  final bool isVerified;

  /// Флаг модератора — выставляется только через админку, не в UI профиля.
  final bool isModerator;
  final DateTime? premiumUntil;

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
    this.phoneNumber,
    this.gender,
    this.birthDate,
    this.lookingFor,
    this.zodiacSign,
    this.placesQuizAnswers = const {},
    this.profilePhotoUrls = const [],
    this.mainPhotoIndex = 0,
    this.isPremium = false,
    this.isVerified = false,
    this.isModerator = false,
    this.premiumUntil,
  });

  /// Совместимость со старым полем.
  bool get isPaidProfile => isPremium;

  int get mainPhotoIndexSafe {
    if (profilePhotoUrls.isEmpty) return 0;
    return mainPhotoIndex.clamp(0, profilePhotoUrls.length - 1);
  }

  String? get mainPhotoUrl {
    if (profilePhotoUrls.isEmpty) return null;
    return profilePhotoUrls[mainPhotoIndexSafe];
  }

  bool get hasActivePremium {
    if (!isPremium) return false;
    if (premiumUntil == null) return true;
    return premiumUntil!.isAfter(DateTime.now());
  }

  UserProfile copyWith({
    String? name,
    String? bio,
    String? role,
    String? city,
    List<String>? interests,
    bool? readyForMeeting,
    bool? phoneVerified,
    DateTime? phoneVerifiedAt,
    String? phoneNumber,
    String? gender,
    DateTime? birthDate,
    String? lookingFor,
    String? zodiacSign,
    Map<String, List<String>>? placesQuizAnswers,
    List<String>? profilePhotoUrls,
    int? mainPhotoIndex,
    bool? isPremium,
    bool? isPaidProfile,
    bool? isVerified,
    bool? isModerator,
    DateTime? premiumUntil,
    bool clearPhoneVerifiedAt = false,
    bool clearBirthDate = false,
    bool clearPremiumUntil = false,
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
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      lookingFor: lookingFor ?? this.lookingFor,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      placesQuizAnswers: placesQuizAnswers ?? this.placesQuizAnswers,
      profilePhotoUrls: profilePhotoUrls ?? this.profilePhotoUrls,
      mainPhotoIndex: mainPhotoIndex ?? this.mainPhotoIndex,
      isPremium: isPremium ?? isPaidProfile ?? this.isPremium,
      isVerified: isVerified ?? this.isVerified,
      isModerator: isModerator ?? this.isModerator,
      premiumUntil:
          clearPremiumUntil ? null : (premiumUntil ?? this.premiumUntil),
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
      'phoneNumber': phoneNumber,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'lookingFor': lookingFor,
      'zodiacSign': zodiacSign,
      'placesQuizAnswers': placesQuizAnswers,
      'profilePhotoUrls': profilePhotoUrls,
      'mainPhotoIndex': mainPhotoIndex,
      'isPremium': isPremium,
      'isPaidProfile': isPremium,
      'isVerified': isVerified,
      'isModerator': isModerator,
      'premiumUntil': premiumUntil?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    final rawInterests = map['interests'];
    final verifiedAt = map['phoneVerifiedAt'];
    final rawQuiz = map['placesQuizAnswers'];
    final rawPhotos = map['profilePhotoUrls'];
    final rawBirthDate = map['birthDate'];
    final rawPremiumUntil = map['premiumUntil'];
    DateTime? parsedBirthDate;
    if (rawBirthDate is DateTime) {
      parsedBirthDate = rawBirthDate;
    } else if (rawBirthDate?.runtimeType.toString() == 'Timestamp') {
      parsedBirthDate = rawBirthDate.toDate() as DateTime?;
    } else if (rawBirthDate is String && rawBirthDate.isNotEmpty) {
      parsedBirthDate = DateTime.tryParse(rawBirthDate);
    }
    final phoneVerified = map['phoneVerified'] as bool? ?? false;
    final isPremium =
        map['isPremium'] as bool? ?? map['isPaidProfile'] as bool? ?? false;
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
      phoneVerified: phoneVerified,
      phoneVerifiedAt:
          verifiedAt is String && verifiedAt.isNotEmpty
              ? DateTime.tryParse(verifiedAt)
              : null,
      phoneNumber: map['phoneNumber'] as String?,
      gender: map['gender'] as String?,
      birthDate: parsedBirthDate,
      lookingFor: map['lookingFor'] as String?,
      zodiacSign: map['zodiacSign'] as String?,
      placesQuizAnswers: _parseQuizAnswers(rawQuiz),
      profilePhotoUrls:
          rawPhotos is List
              ? rawPhotos.map((e) => e.toString()).toList()
              : const [],
      mainPhotoIndex: (map['mainPhotoIndex'] as num?)?.toInt() ?? 0,
      isPremium: isPremium,
      isVerified: map['isVerified'] as bool? ?? phoneVerified,
      isModerator: map['isModerator'] as bool? ?? map['role'] == 'moderator',
      premiumUntil:
          rawPremiumUntil is String && rawPremiumUntil.isNotEmpty
              ? DateTime.tryParse(rawPremiumUntil)
              : null,
    );
  }
}

Map<String, List<String>> _parseQuizAnswers(dynamic rawQuiz) {
  if (rawQuiz is! Map) return const {};
  final result = <String, List<String>>{};
  rawQuiz.forEach((key, value) {
    final id = key.toString();
    if (value is List) {
      result[id] = value.map((e) => e.toString()).toList();
    } else if (value != null && value.toString().isNotEmpty) {
      // Старый формат: один ответ строкой.
      result[id] = [value.toString()];
    }
  });
  return result;
}
