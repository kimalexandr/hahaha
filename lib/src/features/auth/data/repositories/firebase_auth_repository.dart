import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    final googleUser = await googleSignIn.authenticate();
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    await _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
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
