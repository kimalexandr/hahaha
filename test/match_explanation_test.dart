import 'package:eventa/src/features/meetings/domain/dating_rules.dart';
import 'package:eventa/src/features/meetings/domain/match_explanation.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfile _profile({
  required String id,
  List<String> interests = const [],
  Map<String, List<String>> quiz = const {},
  String? zodiac,
}) {
  return UserProfile(
    id: id,
    createdAt: DateTime.utc(2026, 1, 1),
    ownerId: id,
    name: id,
    bio: '',
    role: 'user',
    interests: interests,
    placesQuizAnswers: quiz,
    zodiacSign: zodiac,
  );
}

void main() {
  test('group explanation shows shared interests only', () {
    final me = _profile(id: 'me', interests: const ['Кофе', 'Кино', 'Спорт']);
    final other = _profile(id: 'other', interests: const ['Кино', 'Йога']);
    final e = MatchExplanation.between(me, other, dating: false);
    expect(e.sharedInterests, ['Кино']);
    expect(e.quizHooks, isEmpty);
    expect(e.zodiacNote, isNull);
    expect(e.lines.first, contains('Общее: Кино'));
  });

  test('dating explanation includes quiz hooks and zodiac note', () {
    final q1 = placesQuizQuestions.first;
    final qid = q1['id'] as String;
    final option = (q1['options'] as List).first as String;
    final me = _profile(
      id: 'me',
      interests: const ['Кофе'],
      quiz: {
        qid: [option],
      },
      zodiac: 'aries',
    );
    final other = _profile(
      id: 'other',
      interests: const ['Кофе', 'Бег'],
      quiz: {
        qid: [option],
      },
      zodiac: 'leo',
    );
    final e = MatchExplanation.between(me, other, dating: true);
    expect(e.sharedInterests, ['Кофе']);
    expect(e.quizHooks, contains('Вы оба: $option'));
    expect(e.zodiacNote, contains('Овен'));
    expect(e.zodiacNote, contains('Лев'));
    expect(e.zodiacNote, contains('совместимость'));
    expect(e.isNotEmpty, isTrue);
  });
}
