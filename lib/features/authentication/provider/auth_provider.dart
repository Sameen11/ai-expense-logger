import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../service/auth_service.dart';

// AuthProvider manages the application's authentication state.
// It uses ChangeNotifier to notify listening widgets of any state changes.
class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService firestoreService = FirestoreService();
  User? _user;
  bool _isLoading = false;
  UserModel? _userProfile;
  String? _errorMessage;

  // Constructor: Initializes the provider and sets up a listener for auth state changes.
  AuthProvider(this._authService) {
    _authService.authStateChanges.listen(_onAuthStateChanged);
    _user = _authService.currentUser;
    // ⭐️ Fetch profile if user is already logged in
    if (_user != null) {
      _fetchUserProfile(_user!.uid);
    }
  }

  // Getters for the state properties. Widgets can listen to these.
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  UserModel? get userProfile => _userProfile;

  // Private method to handle auth state changes from the AuthService stream.
  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user != null) {
      _fetchUserProfile(user.uid); // ⭐️ Fetch profile on login
    } else {
      _userProfile = null; // ⭐️ Clear profile on logout
    }
    notifyListeners();
  }

  // ⭐️ NEW: Private method to fetch and cache the profile
  Future<void> _fetchUserProfile(String uid) async {
    try {
      final data = await firestoreService.getUserData(uid);
      if (data != null) {
        _userProfile = UserModel.fromMap(uid, data);
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
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

  // ⭐️ UPDATED: to use the cached profile
  Future<Map<String, String>> getProfileForEdit() async {
    if (_user == null) throw Exception('No user logged in.');

    // 1. Check for cached profile
    if (_userProfile == null) {
      // 2. If not cached, fetch it
      await _fetchUserProfile(_user!.uid);
    }

    // 3. Return data from the cached profile
    return {
      'name': _userProfile?.displayName ?? _user!.displayName ?? '',
      'email': _userProfile?.email ?? _user!.email ?? '',
      'phone': _userProfile?.phoneNumber ?? '',
      'countryCode': _userProfile?.phoneCountryCode ?? '', // ⭐️ ADD THIS
    };
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

  /// Updates the user's profile.
  Future<void> updateUserProfile({
    required String newName,
    required String newEmail,
    String? newPhoneNumber,
    String? newPhoneCountryISOCode, // ⭐️ ADD THIS
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.updateUserProfile(
        newName: newName,
        newEmail: newEmail,
        newPhoneNumber: newPhoneNumber,
        newPhoneCountryCode: newPhoneCountryISOCode, // ⭐️ PASS IT
      );

      // ⭐️ Manually update the local user object and profile
      _user = _authService.currentUser;
      _userProfile = _userProfile?.copyWith(
        displayName: newName,
        email: newEmail,
        phoneNumber: newPhoneNumber,
        phoneCountryCode: newPhoneCountryISOCode,
      );

    } catch (e) {
      _errorMessage = e.toString();
      throw e;
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

