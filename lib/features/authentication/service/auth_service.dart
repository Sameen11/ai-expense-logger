import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/firestore_service.dart';

// This service class abstracts away the Firebase Auth implementation details
// from the UI, making the code cleaner and easier to test/maintain.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // --- ADD FIRESTORE SERVICE INSTANCE ---
  final FirestoreService _firestoreService = FirestoreService();

  // Stream to listen for authentication state changes.
  // This is the primary way to check if a user is logged in.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get the current user, if any.
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign in with email and password.
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // --- ADDED ---
      // After successful sign-in, check and create Firestore doc if needed
      if (userCredential.user != null) {
        await _firestoreService.checkAndCreateUserDocument(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Re-throw the exception to be handled by the UI layer.
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password.
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // --- ADDED ---
      // After successful sign-up, create the Firestore document
      if (userCredential.user != null) {
        await _firestoreService.createUserDocument(userCredential.user!);
      }

      return userCredential;
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

  // Check if demo user exists, if not create it
  Future<bool> ensureDemoUserExists() async {
    const demoEmail = 'demo@expenselogger.com';
    const demoPassword = 'demo123';
    
    try {
      // Try to sign in with demo credentials
      await _firebaseAuth.signInWithEmailAndPassword(
        email: demoEmail,
        password: demoPassword,
      );
      // If successful, demo user exists
      await _firebaseAuth.signOut(); // Sign out immediately
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Demo user doesn't exist, create it
        try {
          final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: demoEmail,
            password: demoPassword,
          );
          
          // Update display name
          await userCredential.user?.updateDisplayName('Demo User');
          
          // Create Firestore document
          if (userCredential.user != null) {
            await _firestoreService.createUserDocument(userCredential.user!);
          }
          
          await _firebaseAuth.signOut(); // Sign out immediately
          return true;
        } catch (createError) {
          print('Error creating demo user: $createError');
          return false;
        }
      }
      return false;
    }
  }

  /// Updates the user's profile in both Firebase Auth and Firestore.
  ///
  /// Throws an error if the update fails.
  Future<void> updateUserProfile({
    required String newName,
    required String newEmail,
    String? newPhoneNumber,
    String? newPhoneCountryCode,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No user logged in.');
    }

    try {
      // --- 1. Update Firebase Auth ---

      // Update Display Name in Auth
      if (newName != user.displayName) {
        await user.updateDisplayName(newName);
      }

      // Update Email in Auth (sensitive operation)
      if (newEmail != user.email) {
        await user.updateEmail(newEmail);
      }

      // --- 2. Update Firestore Document ---
      final Map<String, dynamic> dataToUpdate = {
        'displayName': newName,
        'email': newEmail,
        'phoneNumber': newPhoneNumber, // Will be null or a value
        'phoneCountryCode': newPhoneCountryCode, // ⭐️ ADD THIS
      };

      // Remove any keys where the value is null, just in case
      dataToUpdate.removeWhere((key, value) => value == null);

      if (dataToUpdate.isNotEmpty) {
        await _firestoreService.updateUserData(user.uid, dataToUpdate);
      }

      // --- 3. Reload user data ---
      // This ensures the `currentUser` object (and the auth stream)
      // gets the latest data from Firebase Auth.
      await user.reload();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Provide a more specific error message for this common case
        throw Exception(
            'This change requires you to sign in again. Please log out and log back in to update your email.');
      }
      // Re-throw other errors to be handled by our helper
      throw _handleAuthException(e);
    } catch (e) {
      rethrow; // Re-throw any other errors
    }
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

