import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventa/src/features/auth/data/google_sign_in_helper.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthRepository, env: [Environment.dev])
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository()
    : _googleSignIn = createGoogleSignIn(),
      _persistence = ProfilePersistence();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn;
  final ProfilePersistence _persistence;

  @override
  Stream<bool> get authStateChanges =>
      _firebaseAuth.authStateChanges().map((user) => user != null);

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    Object? pluginError;
    try {
      await _signInWithGooglePlugin();
      return;
    } catch (e, st) {
      pluginError = e;
      debugPrint('GoogleSignIn plugin failed: $e\n$st');
      if (e is FirebaseAuthException && e.code == 'google-sign-in-cancelled') {
        rethrow;
      }
      if (!shouldFallbackToFirebaseGoogleProvider(e)) {
        if (e is FirebaseAuthException) rethrow;
        throw FirebaseAuthException(
          code: 'google-sign-in-failed',
          message: googleSignInUserMessage(e),
        );
      }
    }

    try {
      debugPrint('Falling back to FirebaseAuth.signInWithProvider(Google)');
      await _signInWithGoogleProvider();
    } catch (e, st) {
      debugPrint('Google signInWithProvider failed: $e\n$st');
      if (e is FirebaseAuthException) {
        if (e.code == 'web-context-canceled' ||
            e.code == 'canceled' ||
            e.code == 'user-cancelled') {
          throw FirebaseAuthException(
            code: 'google-sign-in-cancelled',
            message: 'Вход через Google отменён.',
          );
        }
        if (e.code == 'account-exists-with-different-credential') {
          throw FirebaseAuthException(
            code: e.code,
            message:
                'Этот email уже зарегистрирован другим способом '
                '(обычно email/пароль). Войдите тем же способом или '
                'восстановите пароль.',
          );
        }
        throw FirebaseAuthException(
          code: e.code,
          message: googleSignInUserMessage(pluginError),
        );
      }
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: googleSignInUserMessage(pluginError),
      );
    }
  }

  Future<void> _signInWithGooglePlugin() async {
    try {
      // Сброс зависшей сессии — частая причина «отмены» / reauth failed.
      await _googleSignIn.signOut();
    } catch (_) {}

    final GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } catch (e, st) {
      debugPrint('GoogleSignIn.signIn failed: $e\n$st');
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: googleSignInUserMessage(e),
      );
    }

    if (account == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Вход через Google отменён.',
      );
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'google-id-token-missing',
        message:
            'Google не вернул idToken. Проверьте Web Client ID '
            '(default_web_client_id), SHA-1/SHA-256 в Firebase Console и '
            'актуальный google-services.json.',
      );
    }

    try {
      await _firebaseAuth.signInWithCredential(
        GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: idToken,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw FirebaseAuthException(
          code: e.code,
          message:
              'Этот email уже зарегистрирован другим способом '
              '(обычно email/пароль). Войдите тем же способом или '
              'восстановите пароль.',
        );
      }
      rethrow;
    }
  }

  Future<void> _signInWithGoogleProvider() async {
    final provider =
        GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
    await _firebaseAuth.signInWithProvider(provider);
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }

  @override
  Future<bool> isNewUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return true;
    try {
      final profileDoc =
          await _firestore.collection('profiles').doc(user.uid).get();
      if (!profileDoc.exists) return true;
      final data = profileDoc.data();
      if (data == null) return true;
      if (data['profileCreated'] == true) return false;
      final interests = data['interests'];
      return !(interests is List && interests.isNotEmpty);
    } catch (e) {
      debugPrint('isNewUser failed: $e');
      // При сетевой ошибке не блокируем вход — считаем онбординг нужным.
      return true;
    }
  }

  @override
  Future<String?> currentUserId() async => _firebaseAuth.currentUser?.uid;

  @override
  Future<AuthAccountInfo> accountInfo() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return const AuthAccountInfo();
    final providers = user.providerData.map((p) => p.providerId).toSet();
    String? phone = user.phoneNumber;
    try {
      final profile = await _persistence.read(user.uid);
      phone ??= profile?.phoneNumber;
    } catch (_) {}
    return AuthAccountInfo(
      email: user.email,
      phoneNumber: phone,
      hasPasswordProvider: providers.contains('password'),
      hasGoogleProvider: providers.contains('google.com'),
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Нет авторизованного пользователя с email.',
      );
    }
    final providers = user.providerData.map((p) => p.providerId).toSet();
    if (!providers.contains('password')) {
      throw FirebaseAuthException(
        code: 'wrong-provider',
        message:
            'Этот аккаунт входит через Google. Смена пароля недоступна — '
            'используйте Google для входа.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    try {
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Неверный текущий пароль.',
        );
      }
      if (e.code == 'weak-password') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Новый пароль слишком слабый (минимум 6 символов).',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> completeProfile(UserProfile profile) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Нет авторизованного пользователя.',
      );
    }
    final toSave = UserProfile(
      id: user.uid,
      createdAt: profile.createdAt,
      ownerId: user.uid,
      name: profile.name,
      bio: profile.bio,
      role: profile.role,
      city: profile.city,
      interests: profile.interests,
      readyForMeeting: profile.readyForMeeting,
      phoneVerified: profile.phoneVerified,
      phoneVerifiedAt: profile.phoneVerifiedAt,
      phoneNumber: profile.phoneNumber,
      gender: profile.gender,
      birthDate: profile.birthDate,
      lookingFor: profile.lookingFor,
      zodiacSign: profile.zodiacSign,
      placesQuizAnswers: profile.placesQuizAnswers,
      profilePhotoUrls: profile.profilePhotoUrls,
      mainPhotoIndex: profile.mainPhotoIndex,
      isPremium: profile.isPremium,
      isVerified: profile.isVerified,
      isModerator: profile.isModerator,
      premiumUntil: profile.premiumUntil,
    );
    await _persistence.save(toSave);
    await _firestore.collection('profiles').doc(user.uid).set({
      ...toSave.toMap(),
      'profileCreated': true,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
