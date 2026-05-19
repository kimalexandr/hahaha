import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventa/src/features/auth/data/google_sign_in_helper.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthRepository, env: [Environment.dev])
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<bool> get authStateChanges =>
      _firebaseAuth.authStateChanges().map((user) => user != null);

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  bool get _useFirebaseGoogleProvider =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> signInWithGoogle() async {
    // Android/iOS: нативный поток Firebase (обходит google_sign_in 7 / Credential Manager [16]).
    if (_useFirebaseGoogleProvider) {
      await _firebaseAuth.signInWithProvider(GoogleAuthProvider());
      return;
    }

    await ensureGoogleSignInInitialized();
    const scopes = <String>['email', 'profile'];
    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;

    var clientAuth = await googleUser.authorizationClient
        .authorizationForScopes(scopes);
    clientAuth ??= await googleUser.authorizationClient.authorizeScopes(scopes);

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'google-id-token-missing',
        message:
            'Google не вернул idToken. Проверьте Web Client ID и SHA-1 в Firebase.',
      );
    }

    await _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: clientAuth.accessToken,
      ),
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await ensureGoogleSignInInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }

  @override
  Future<bool> isNewUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return true;
    final profileDoc =
        await _firestore.collection('profiles').doc(user.uid).get();
    if (!profileDoc.exists) return true;
    return !(profileDoc.data()?['profileCreated'] as bool? ?? false);
  }

  @override
  Future<void> markProfileAsCreated() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    await _firestore.collection('profiles').doc(user.uid).set({
      'profileCreated': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
