import 'dart:async';

import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

@LazySingleton(as: AuthRepository, env: [Environment.dev])
class MockAuthRepository implements AuthRepository {
  final _authStateController = BehaviorSubject<bool>.seeded(false);
  bool _profileCreated = false;

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    // Simulate network delay
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
    // Simulate network delay and user selecting an account
    await Future.delayed(const Duration(seconds: 1));
    _authStateController.add(true);
  }

  @override
  Future<void> signOut() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    _authStateController.add(false);
    _profileCreated = false;
  }

  @override
  Future<bool> isNewUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return !_profileCreated;
  }

  @override
  Future<void> markProfileAsCreated() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _profileCreated = true;
  }
}
