import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get reference to users collection
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create or update user profile in Firestore
  Future<void> createOrUpdateUser(User firebaseUser, String authProvider) async {
    final userDoc = _usersCollection.doc(firebaseUser.uid);
    final docSnapshot = await userDoc.get();

    final now = DateTime.now();

    if (docSnapshot.exists) {
      // User exists, update last login
      await userDoc.update({
        'lastLoginAt': now.toIso8601String(),
        'email': firebaseUser.email, // Update email in case it changed
        'displayName': firebaseUser.displayName, // Update display name
        'photoUrl': firebaseUser.photoURL, // Update photo URL
      });
      print('✓ Updated user ${firebaseUser.uid} last login');
    } else {
      // New user, create profile
      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        authProvider: authProvider,
        createdAt: now,
        lastLoginAt: now,
      );

      await userDoc.set(userModel.toMap());
      print('✓ Created new user profile for ${firebaseUser.uid}');
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      if (docSnapshot.exists) {
        return UserModel.fromMap(docSnapshot.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Stream user profile (real-time updates)
  Stream<UserModel?> streamUserProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _usersCollection.doc(uid).update(updates);
      print('✓ Updated user profile for $uid');
    }
  }

  // Delete user profile (for account deletion)
  Future<void> deleteUserProfile(String uid) async {
    await _usersCollection.doc(uid).delete();
    print('✓ Deleted user profile for $uid');
  }

  // Get all users (admin function - use with caution)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _usersCollection.get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Get user count
  Future<int> getUserCount() async {
    try {
      final querySnapshot = await _usersCollection.get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting user count: $e');
      return 0;
    }
  }
}
