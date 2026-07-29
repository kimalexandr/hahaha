class Event {
  final String id;
  final DateTime createdAt;
  final String ownerId;
  final String organizerName;
  final String title;
  final String city;
  final String category;
  final double price;
  final DateTime date;
  final String place;
  final String description;
  final List<String> photos;
  final double? latitude;
  final double? longitude;
  int likes;
  int going;
  int comments;
  bool isLiked;
  bool isGoing;
  bool isBookmarked;
  bool hasTicket;
  bool isTicketUsed;
  bool isCreatedByMe;

  /// Скрыто из публичной ленты — только для организатора.
  bool isHidden;

  Event({
    required this.id,
    required this.createdAt,
    required this.ownerId,
    required this.organizerName,
    required this.title,
    required this.city,
    required this.category,
    required this.price,
    required this.date,
    required this.place,
    required this.description,
    required this.photos,
    this.latitude,
    this.longitude,
    this.likes = 0,
    this.going = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isGoing = false,
    this.isBookmarked = false,
    this.hasTicket = false,
    this.isTicketUsed = false,
    this.isCreatedByMe = false,
    this.isHidden = false,
  });

  Event copyWith({
    String? id,
    DateTime? createdAt,
    String? ownerId,
    String? organizerName,
    String? title,
    String? city,
    String? category,
    double? price,
    DateTime? date,
    String? place,
    String? description,
    List<String>? photos,
    double? latitude,
    double? longitude,
    int? likes,
    int? going,
    int? comments,
    bool? isLiked,
    bool? isGoing,
    bool? isBookmarked,
    bool? hasTicket,
    bool? isTicketUsed,
    bool? isCreatedByMe,
    bool? isHidden,
  }) {
    return Event(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      ownerId: ownerId ?? this.ownerId,
      organizerName: organizerName ?? this.organizerName,
      title: title ?? this.title,
      city: city ?? this.city,
      category: category ?? this.category,
      price: price ?? this.price,
      date: date ?? this.date,
      place: place ?? this.place,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      likes: likes ?? this.likes,
      going: going ?? this.going,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      isGoing: isGoing ?? this.isGoing,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      hasTicket: hasTicket ?? this.hasTicket,
      isTicketUsed: isTicketUsed ?? this.isTicketUsed,
      isCreatedByMe: isCreatedByMe ?? this.isCreatedByMe,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'ownerId': ownerId,
      'organizerName': organizerName,
      'title': title,
      'city': city,
      'category': category,
      'price': price,
      'date': date.toIso8601String(),
      'place': place,
      'description': description,
      'photos': photos,
      'latitude': latitude,
      'longitude': longitude,
      'likes': likes,
      'going': going,
      'comments': comments,
      'isLiked': isLiked,
      'isGoing': isGoing,
      'isBookmarked': isBookmarked,
      'hasTicket': hasTicket,
      'isTicketUsed': isTicketUsed,
      'isCreatedByMe': isCreatedByMe,
      'isHidden': isHidden,
    };
  }

  factory Event.fromMap(Map<dynamic, dynamic> map) {
    return Event(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      ownerId: map['ownerId'] as String,
      organizerName: map['organizerName'] as String,
      title: map['title'] as String,
      city: map['city'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      place: map['place'] as String,
      description: map['description'] as String,
      photos: List<String>.from((map['photos'] as List<dynamic>? ?? const [])),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      likes: map['likes'] as int? ?? 0,
      going: map['going'] as int? ?? 0,
      comments: map['comments'] as int? ?? 0,
      isLiked: map['isLiked'] as bool? ?? false,
      isGoing: map['isGoing'] as bool? ?? false,
      isBookmarked: map['isBookmarked'] as bool? ?? false,
      hasTicket: map['hasTicket'] as bool? ?? false,
      isTicketUsed: map['isTicketUsed'] as bool? ?? false,
      isCreatedByMe: map['isCreatedByMe'] as bool? ?? false,
      isHidden: map['isHidden'] as bool? ?? false,
    );
  }
}
