
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final double? budget;
  final Timestamp? createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.budget,
    this.createdAt,
  });

  /// Helper factory to create a UserModel from a Firebase User
  /// (Used right after sign-up)
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      budget: 5000,
      createdAt: Timestamp.now(), // Set creation time
    );
  }

  /// Factory to create a UserModel from a Firestore Map
  /// (Used when fetching data)
  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      budget: data['budget'] as double?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  /// Converts the UserModel into a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'budget': budget,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// Creates a copy of the user with updated fields
  UserModel copyWith({
    String? displayName,
    String? email,
    String? phoneNumber,
    String? phoneCountryCode,
    double? budget,
    Timestamp? createdAt,
    String? photoURL,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      budget: budget ?? this.budget,
    );
  }
}