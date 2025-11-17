
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? phoneCountryCode; // ⭐️ For the country code
  final String? photoURL;
  final Timestamp? createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.phoneCountryCode,
    this.photoURL,
    this.createdAt,
  });

  /// Helper factory to create a UserModel from a Firebase User
  /// (Used right after sign-up)
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
      photoURL: user.photoURL,
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
      phoneNumber: data['phoneNumber'] as String?,
      phoneCountryCode: data['phoneCountryCode'] as String?, // ⭐️ Get new field
      photoURL: data['photoURL'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  /// Converts the UserModel into a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'phoneCountryCode': phoneCountryCode, // ⭐️ Save new field
      'photoURL': photoURL,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// Creates a copy of the user with updated fields
  UserModel copyWith({
    String? displayName,
    String? email,
    String? phoneNumber,
    String? phoneCountryCode,
    String? photoURL,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
    );
  }
}