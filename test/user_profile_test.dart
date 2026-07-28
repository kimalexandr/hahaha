import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UserProfile serializes interests and meeting flags', () {
    final profile = UserProfile(
      id: 'u1',
      createdAt: DateTime.utc(2026, 1, 1),
      ownerId: 'u1',
      name: 'Аня',
      bio: 'Люблю кофе',
      role: 'user',
      city: 'Алматы',
      interests: const ['Кофе', 'Кино'],
      readyForMeeting: true,
    );

    final restored = UserProfile.fromMap(profile.toMap());

    expect(restored.name, 'Аня');
    expect(restored.city, 'Алматы');
    expect(restored.interests, ['Кофе', 'Кино']);
    expect(restored.readyForMeeting, isTrue);
  });
}
