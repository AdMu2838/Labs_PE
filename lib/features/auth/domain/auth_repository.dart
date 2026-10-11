import 'session.dart';

abstract interface class AuthRepository {
  Stream<AppSession?> get sessions;
  Future<AppSession?> current();
  Future<void> signIn(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signUp(String email, String password, String name, String cui);
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String password);
  Future<void> signOut();
}
