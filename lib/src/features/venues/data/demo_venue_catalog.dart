import 'package:eventa/src/features/venues/domain/entities/venue.dart';

/// Демо-каталог заведений для MVP (позже — Firestore).
class DemoVenueCatalog {
  DemoVenueCatalog._();

  static List<Venue> all() => [
    const Venue(
      id: 'venue-1',
      name: 'Coffee Lab',
      type: VenueType.cafe,
      city: 'Almaty',
      address: 'ул. Абая 10',
      description: 'Тихое кафе для первого знакомства за чашкой кофе.',
      photoUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085',
    ),
    const Venue(
      id: 'venue-2',
      name: 'Sky Lounge',
      type: VenueType.bar,
      city: 'Almaty',
      address: 'пр. Достык 50',
      description: 'Бар с видом на город — удобно для вечерней встречи.',
      photoUrl: 'https://images.unsplash.com/photo-1514933651103-005eec06c04b',
    ),
    const Venue(
      id: 'venue-3',
      name: 'Pasta House',
      type: VenueType.restaurant,
      city: 'Almaty',
      address: 'ул. Кабанбай батыра 22',
      description: 'Уютный ресторан для ужина и спокойного разговора.',
      photoUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
    ),
    const Venue(
      id: 'venue-4',
      name: 'Astana Brew',
      type: VenueType.cafe,
      city: 'Astana',
      address: 'ул. Сыганак 15',
      description: 'Кофейня в центре — быстрые дневные встречи.',
      photoUrl: 'https://images.unsplash.com/photo-1442512595331-e89e7382450f',
    ),
    const Venue(
      id: 'venue-5',
      name: 'River Side',
      type: VenueType.restaurant,
      city: 'Astana',
      address: 'наб. Есиль 3',
      description: 'Ресторан у воды для неспешного ужина.',
      photoUrl: 'https://images.unsplash.com/photo-1559339352-11d035aa65de',
    ),
    const Venue(
      id: 'venue-6',
      name: 'Neon Bar',
      type: VenueType.bar,
      city: 'Astana',
      address: 'пр. Мангилик Ел 8',
      description: 'Современный бар для вечерних форматов.',
      photoUrl: 'https://images.unsplash.com/photo-1572116469696-31de0f17cc34',
    ),
  ];
}
