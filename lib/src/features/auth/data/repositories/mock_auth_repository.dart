import 'dart:async';

import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

@LazySingleton(as: AuthRepository, env: ['mock'])
class MockAuthRepository implements AuthRepository {
  MockAuthRepository() : _persistence = ProfilePersistence();

  static const String mockUserId = 'user-1';

  final ProfilePersistence _persistence;
  final _authStateController = BehaviorSubject<bool>.seeded(false);
  final Map<String, String> _registeredAccounts = {
    'demo@eventa.app': 'password',
  };
  bool _profileCreated = false;

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final key = email.trim().toLowerCase();
    final stored = _registeredAccounts[key];
    if (stored != null && stored == password) {
      _authStateController.add(true);
      return;
    }
    // Обратная совместимость демо: любой email + password
    if (password == 'password') {
      _authStateController.add(true);
      return;
    }
    _authStateController.add(false);
    throw Exception('Неверный email или пароль');
  }

  @override
  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final key = email.trim().toLowerCase();
    if (key.isEmpty || !key.contains('@')) {
      throw Exception('Введите корректный email');
    }
    if (password.length < 6) {
      throw Exception('Пароль должен быть не короче 6 символов');
    }
    if (_registeredAccounts.containsKey(key)) {
      throw Exception('Аккаунт с таким email уже существует');
    }
    _registeredAccounts[key] = password;
    _profileCreated = false;
    _authStateController.add(true);
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Новый Google-вход в демо — как регистрация: нужен онбординг профиля,
    // если профиль ещё не заполняли в этой сессии.
    final existing = await _persistence.read(mockUserId);
    if (existing == null || existing.interests.isEmpty) {
      _profileCreated = false;
    }
    _authStateController.add(true);
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _authStateController.add(false);
    _profileCreated = false;
  }

  @override
  Future<bool> isNewUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_profileCreated) return false;
    final existing = await _persistence.read(mockUserId);
    if (existing != null && existing.interests.isNotEmpty) {
      _profileCreated = true;
      return false;
    }
    return true;
  }

  @override
  Future<String?> currentUserId() async {
    if (!_authStateController.value) return null;
    return mockUserId;
  }

  @override
  Future<void> completeProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 100));
    await _persistence.save(profile);
    _profileCreated = true;
  }
}
