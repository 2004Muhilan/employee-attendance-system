import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Sign In Method
  Future<User?> loginWithEmailPassword(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // We throw a clean error message so the UI doesn't have to guess
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unknown error occurred. Please try again.';
    }
  }

  // 2. Sign Out Method
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 3. Get Current User (Utility)
  User? get currentUser => _auth.currentUser;

  // 4. Get ID Token (For Flask)
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // Helper: Parse Firebase Error Codes into Human Text
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection.';
      default:
        return 'Login failed: ${e.message}';
    }
  }
}