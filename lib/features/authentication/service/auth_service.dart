import 'package:firebase_auth/firebase_auth.dart';

// This service class abstracts away the Firebase Auth implementation details
// from the UI, making the code cleaner and easier to test/maintain.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Stream to listen for authentication state changes.
  // This is the primary way to check if a user is logged in.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get the current user, if any.
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign in with email and password.
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Re-throw the exception to be handled by the UI layer.
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password.
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out the current user.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // A helper method to convert Firebase Auth error codes into user-friendly messages.
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
