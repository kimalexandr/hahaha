import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';

class CompatibilityScore {
  CompatibilityScore._();

  /// Простой score по пересечению интересов (0..100).
  static int byInterests(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final setA = a.map((e) => e.toLowerCase()).toSet();
    final setB = b.map((e) => e.toLowerCase()).toSet();
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    if (union == 0) return 0;
    return ((intersection / union) * 100).round();
  }

  static List<String> sharedInterests(UserProfile a, UserProfile b) {
    final setB = b.interests.map((e) => e.toLowerCase()).toSet();
    return a.interests
        .where((e) => setB.contains(e.toLowerCase()))
        .toList();
  }
}
