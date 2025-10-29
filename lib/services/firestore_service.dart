import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get a reference to the 'users' collection
  late final CollectionReference _usersCollection;

  FirestoreService() {
    _usersCollection = _db.collection('users').withConverter<Map<String, dynamic>>(
      fromFirestore: (snapshot, _) => snapshot.data()!,
      toFirestore: (map, _) => map,
    );
  }

  /// Creates a new user document in Firestore upon sign-up.
  Future<void> createUserDocument(User user) async {
    final docRef = _usersCollection.doc(user.uid);

    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'phoneNumber': user.phoneNumber, // Often null initially
      'createdAt': FieldValue.serverTimestamp(),
      'photoURL': user.photoURL,
    };

    // Use set() to create the document
    await docRef.set(userData);
  }

  /// Checks if a user document exists on sign-in, and creates one if not.
  /// This is useful for users who signed up before this logic was implemented.
  Future<void> checkAndCreateUserDocument(User user) async {
    final docRef = _usersCollection.doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      // If the document doesn't exist, create it.
      await createUserDocument(user);
    }
  }

  /// Updates user data in their Firestore document.
  /// This is perfect for the "Edit Profile" screen.
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    // Use update() to modify specific fields without overwriting the whole doc
    await _usersCollection.doc(uid).update(data);
  }

  /// Fetches a user's data from Firestore as a Map.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final docSnap = await _usersCollection.doc(uid).get();

    if (docSnap.exists) {
      return docSnap.data() as Map<String, dynamic>;
    }
    return null;
  }
}
