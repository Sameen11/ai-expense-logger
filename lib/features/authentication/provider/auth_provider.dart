import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../service/auth_service.dart';

// AuthProvider manages the application's authentication state.
// It uses ChangeNotifier to notify listening widgets of any state changes.
class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Constructor: Initializes the provider and sets up a listener for auth state changes.
  AuthProvider(this._authService) {
    _authService.authStateChanges.listen(_onAuthStateChanged);
    _user = _authService.currentUser;
  }

  // Getters for the state properties. Widgets can listen to these.
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Private method to handle auth state changes from the AuthService stream.
  void _onAuthStateChanged(User? user) {
    _user = user;
    notifyListeners(); // Notify all listening widgets to rebuild.
  }

  // Helper method to manage loading state and error messages.
  Future<void> _callAuthMethod(Future<void> Function() method) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await method();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Public methods for UI to call for authentication actions.
  Future<void> signIn(String email, String password) async {
    await _callAuthMethod(() => _authService.signInWithEmailAndPassword(email, password));
  }

  Future<void> signUp(String email, String password) async {
    await _callAuthMethod(() => _authService.createUserWithEmailAndPassword(email, password));
  }

  Future<void> signOut() async {
    await _callAuthMethod(() => _authService.signOut());
  }

  Future<void> sendPasswordResetEmail(String email) async {
    // This one is slightly different as it doesn't change the auth state directly.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _errorMessage = e.toString();
      throw e; // Re-throw to be caught in the UI for specific handling (e.g., showing a success message)
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to clear error messages, useful for the UI.
  void clearError() {
    _errorMessage = null;
  }
}
