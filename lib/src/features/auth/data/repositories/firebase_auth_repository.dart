import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventa/src/features/auth/data/google_sign_in_helper.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthRepository, env: [Environment.dev])
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository() : _googleSignIn = createGoogleSignIn();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn;

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

  @override
  Future<void> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
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
            'Google не вернул idToken. Проверьте Web Client ID и SHA-1 в Firebase.',
      );
    }

    await _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: idToken,
      ),
    );
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
