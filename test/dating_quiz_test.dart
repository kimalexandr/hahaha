import 'package:eventa/src/features/meetings/domain/dating_rules.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('places quiz schema', () {
    test('normalize drops unknown ids and options', () {
      final raw = <String, List<String>>{
        'q1_evening': ['уютное кафе с разговором', 'unknown-option'],
        'legacy_question': ['whatever'],
      };
      final normalized = normalizePlacesQuizAnswers(raw);
      expect(normalized.keys, ['q1_evening']);
      expect(normalized['q1_evening'], ['уютное кафе с разговором']);
    });

    test('complete requires all current questions', () {
      final partial = normalizePlacesQuizAnswers({
        'q1_evening': ['уютное кафе с разговором'],
      });
      expect(isPlacesQuizAnswersComplete(partial), isFalse);

      final full = <String, List<String>>{
        for (final q in placesQuizQuestions)
          q['id'] as String: [(q['options'] as List).first as String],
      };
      expect(isPlacesQuizAnswersComplete(full), isTrue);
      expect(
        isPlacesQuizAnswersComplete(full, version: kPlacesQuizVersion - 1),
        isFalse,
      );
    });

    test('legacy string answers parse and dating readiness', () {
      final profile = UserProfile.fromMap({
        'id': 'u1',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'ownerId': 'u1',
        'name': 'Аня',
        'bio': '',
        'role': 'user',
        'gender': 'female',
        'lookingFor': 'male',
        'birthDate': DateTime.utc(2000, 5, 1).toIso8601String(),
        'placesQuizAnswers': {
          for (final q in placesQuizQuestions)
            q['id'] as String: (q['options'] as List).first,
        },
        'placesQuizVersion': kPlacesQuizVersion,
      });
      expect(isPlacesQuizComplete(profile), isTrue);
      expect(isDatingProfileReady(profile), isTrue);
    });

    test('UserProfile keeps placesQuizVersion', () {
      final profile = UserProfile(
        id: 'u1',
        createdAt: DateTime.utc(2026, 1, 1),
        ownerId: 'u1',
        name: 'Аня',
        bio: '',
        role: 'user',
        placesQuizVersion: kPlacesQuizVersion,
        placesQuizAnswers: {
          for (final q in placesQuizQuestions)
            q['id'] as String: [(q['options'] as List).first as String],
        },
      );
      final restored = UserProfile.fromMap(profile.toMap());
      expect(restored.placesQuizVersion, kPlacesQuizVersion);
      expect(isPlacesQuizComplete(restored), isTrue);
    });
  });
}
