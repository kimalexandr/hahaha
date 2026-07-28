import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventa/src/features/auth/data/google_sign_in_helper.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final data = profileDoc.data();
    if (data == null) return true;
    if (data['profileCreated'] == true) return false;
    final interests = data['interests'];
    return !(interests is List && interests.isNotEmpty);
  }

  @override
  Future<String?> currentUserId() async => _firebaseAuth.currentUser?.uid;

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
      id: profile.id.isEmpty ? user.uid : profile.id,
      createdAt: profile.createdAt,
      ownerId: user.uid,
      name: profile.name,
      bio: profile.bio,
      role: profile.role,
      city: profile.city,
      interests: profile.interests,
      readyForMeeting: profile.readyForMeeting,
    );
    await _persistence.save(toSave);
    await _firestore.collection('profiles').doc(user.uid).set({
      ...toSave.toMap(),
      'profileCreated': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
