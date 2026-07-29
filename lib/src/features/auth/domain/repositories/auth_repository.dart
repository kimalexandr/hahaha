import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';

class AuthAccountInfo {
  const AuthAccountInfo({
    this.email,
    this.phoneNumber,
    this.hasPasswordProvider = false,
    this.hasGoogleProvider = false,
  });

  final String? email;
  final String? phoneNumber;
  final bool hasPasswordProvider;
  final bool hasGoogleProvider;
}

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

  /// Email / телефон / способы входа текущего аккаунта.
  Future<AuthAccountInfo> accountInfo();

  /// Смена пароля (email/пароль). Требует текущий пароль.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Сохраняет профиль и помечает онбординг завершённым.
  Future<void> completeProfile(UserProfile profile);
}
