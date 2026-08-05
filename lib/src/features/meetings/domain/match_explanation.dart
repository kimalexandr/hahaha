import 'package:eventa/src/features/meetings/domain/compatibility_score.dart';
import 'package:eventa/src/features/meetings/domain/dating_rules.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';

/// Детерминированное объяснение «почему подобран» без LLM.
class MatchExplanation {
  const MatchExplanation({
    required this.sharedInterests,
    required this.quizHooks,
    this.zodiacNote,
  });

  final List<String> sharedInterests;
  final List<String> quizHooks;
  final String? zodiacNote;

  bool get isEmpty =>
      sharedInterests.isEmpty &&
      quizHooks.isEmpty &&
      (zodiacNote == null || zodiacNote!.isEmpty);

  bool get isNotEmpty => !isEmpty;

  /// Строки для компактного subtitle (group/dating).
  List<String> get lines {
    final out = <String>[];
    if (sharedInterests.isNotEmpty) {
      out.add('Общее: ${sharedInterests.join(', ')}');
    }
    out.addAll(quizHooks);
    if (zodiacNote != null && zodiacNote!.isNotEmpty) {
      out.add(zodiacNote!);
    }
    return out;
  }

  static MatchExplanation between(
    UserProfile me,
    UserProfile other, {
    bool dating = false,
    int maxInterests = 4,
    int maxQuizHooks = 2,
  }) {
    final interests =
        CompatibilityScore.sharedInterests(
          me,
          other,
        ).take(maxInterests).toList();

    final hooks = <String>[];
    if (dating) {
      final a = normalizePlacesQuizAnswers(me.placesQuizAnswers);
      final b = normalizePlacesQuizAnswers(other.placesQuizAnswers);
      for (final entry in a.entries) {
        final otherAnswers = b[entry.key];
        if (otherAnswers == null || otherAnswers.isEmpty) continue;
        final shared =
            entry.value.toSet().intersection(otherAnswers.toSet()).toList()
              ..sort();
        for (final option in shared) {
          hooks.add('Вы оба: $option');
          if (hooks.length >= maxQuizHooks) break;
        }
        if (hooks.length >= maxQuizHooks) break;
      }
    }

    String? zodiacNote;
    if (dating && me.zodiacSign != null && other.zodiacSign != null) {
      final score = zodiacScore(me.zodiacSign, other.zodiacSign);
      zodiacNote =
          'Знаки: ${zodiacRuLabel(me.zodiacSign)} · '
          '${zodiacRuLabel(other.zodiacSign)} — ${_zodiacCompatRu(score)}';
    }

    return MatchExplanation(
      sharedInterests: interests,
      quizHooks: hooks,
      zodiacNote: zodiacNote,
    );
  }
}

String _zodiacCompatRu(double score) {
  if (score >= 0.75) return 'высокая совместимость';
  if (score >= 0.65) return 'хорошая совместимость';
  if (score >= 0.5) return 'средняя совместимость';
  return 'слабая совместимость';
}
