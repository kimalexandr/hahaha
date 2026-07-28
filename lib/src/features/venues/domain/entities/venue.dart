enum VenueType {
  cafe,
  restaurant,
  bar,
  other;

  String get labelRu {
    switch (this) {
      case VenueType.cafe:
        return 'Кафе';
      case VenueType.restaurant:
        return 'Ресторан';
      case VenueType.bar:
        return 'Бар';
      case VenueType.other:
        return 'Другое';
    }
  }

  static VenueType fromString(String? value) {
    return VenueType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VenueType.other,
    );
  }
}

class Venue {
  final String id;
  final String name;
  final VenueType type;
  final String city;
  final String address;
  final String description;
  final String? photoUrl;

  const Venue({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    required this.address,
    this.description = '',
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'city': city,
      'address': address,
      'description': description,
      'photoUrl': photoUrl,
    };
  }

  factory Venue.fromMap(Map<dynamic, dynamic> map) {
    return Venue(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: VenueType.fromString(map['type'] as String?),
      city: map['city'] as String? ?? '',
      address: map['address'] as String? ?? '',
      description: map['description'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
    );
  }
}
