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
  bool _profileCreated = false;

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (password == 'password') {
      _authStateController.add(true);
    } else {
      _authStateController.add(false);
      throw Exception('Wrong password');
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
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
  Future<String?> currentUserId() async => mockUserId;

  @override
  Future<void> completeProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 100));
    await _persistence.save(profile);
    _profileCreated = true;
  }
}
