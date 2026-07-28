import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';

abstract class AuthRepository {
  Stream<bool> get authStateChanges;
  Future<void> signInWithEmailAndPassword(String email, String password);

  /// Создаёт аккаунт email/пароль и сразу авторизует.
  Future<void> registerWithEmailAndPassword(String email, String password);

  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<bool> isNewUser();

  /// UID текущего пользователя (или демо-id в mock).
  Future<String?> currentUserId();

  /// Сохраняет профиль и помечает онбординг завершённым.
  Future<void> completeProfile(UserProfile profile);
}
