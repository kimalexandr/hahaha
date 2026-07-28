import 'package:eventa/src/features/venues/data/demo_venue_catalog.dart';
import 'package:eventa/src/features/venues/domain/entities/venue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo venues cover cafe/bar/restaurant', () {
    final venues = DemoVenueCatalog.all();
    expect(venues, isNotEmpty);
    expect(venues.any((v) => v.type == VenueType.cafe), isTrue);
    expect(venues.any((v) => v.type == VenueType.bar), isTrue);
    expect(venues.any((v) => v.type == VenueType.restaurant), isTrue);
  });

  test('Venue round-trip map', () {
    const venue = Venue(
      id: 'v1',
      name: 'Test Cafe',
      type: VenueType.cafe,
      city: 'Almaty',
      address: 'Street 1',
    );
    final restored = Venue.fromMap(venue.toMap());
    expect(restored.id, 'v1');
    expect(restored.type, VenueType.cafe);
    expect(restored.city, 'Almaty');
  });
}
