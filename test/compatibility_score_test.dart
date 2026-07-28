import 'package:eventa/src/features/meetings/domain/compatibility_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compatibility grows with shared interests', () {
    expect(CompatibilityScore.byInterests(['Кофе'], ['Кино']), 0);
    expect(
      CompatibilityScore.byInterests(['Кофе', 'Кино'], ['Кофе', 'Спорт']),
      greaterThan(0),
    );
    expect(
      CompatibilityScore.byInterests(['Кофе', 'Кино'], ['Кофе', 'Кино']),
      100,
    );
  });
}
