// We can add a User entity later if needed.
// For now, a stream of bool is enough to represent auth state.

abstract class AuthRepository {
  Stream<bool> get authStateChanges;
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<bool> isNewUser();
  Future<void> markProfileAsCreated();
}
