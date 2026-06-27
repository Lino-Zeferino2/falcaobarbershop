import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FCMTokenManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Determine which collection the user belongs to
  Future<String?> _getUserCollection(String uid) async {
    // Check admins collection first
    try {
      final adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        debugPrint('User found in admins collection');
        return 'admins';
      }
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        debugPrint('No permission to check admins collection, skipping...');
      } else {
        debugPrint('Error checking admins collection: $e');
      }
    }

    // Check profissionais collection
    try {
      final profDoc = await _firestore.collection('profissionais').doc(uid).get();
      if (profDoc.exists) {
        debugPrint('User found in profissionais collection');
        return 'profissionais';
      }
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        debugPrint('No permission to check profissionais collection, skipping...');
      } else {
        debugPrint('Error checking profissionais collection: $e');
      }
    }

    // Check clientes collection
    try {
      final clientDoc = await _firestore.collection('clientes').doc(uid).get();
      if (clientDoc.exists) {
        debugPrint('User found in clientes collection');
        return 'clientes';
      }
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        debugPrint('No permission to check clientes collection, skipping...');
      } else {
        debugPrint('Error checking clientes collection: $e');
      }
    }

    // Check users collection (legacy)
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        debugPrint('User found in users collection');
        return 'users';
      }
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        debugPrint('No permission to check users collection, skipping...');
      } else {
        debugPrint('Error checking users collection: $e');
      }
    }

    debugPrint('User not found in any collection');
    return null;
  }

  /// Save FCM token to the current user's document in Firestore
  Future<void> saveToken(String token) async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        debugPrint('No user logged in, cannot save FCM token');
        return;
      }

      // Determine the correct collection based on user type, fallback to 'clientes'
      final collection = await _getUserCollection(currentUser.uid) ?? 'clientes';

      final userDoc = _firestore.collection(collection).doc(currentUser.uid);

      // Check if user document exists
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        debugPrint('User document does not exist, cannot save FCM token');
        return;
      }

      // Get current tokens
      final data = docSnapshot.data();
      final List<String> currentTokens = List<String>.from(data?['fcmTokens'] ?? []);

      // Add token if it doesn't exist
      if (!currentTokens.contains(token)) {
        currentTokens.add(token);

        debugPrint('Updating document with ${currentTokens.length} tokens');
        await userDoc.update({
          'fcmTokens': currentTokens,
        });

        // Verify the update was successful
        final updatedDoc = await userDoc.get();
        final updatedData = updatedDoc.data();
        final updatedTokens = List<String>.from(updatedData?['fcmTokens'] ?? []);

        if (updatedTokens.contains(token)) {
          debugPrint('FCM token saved and verified successfully for user: ${currentUser.uid}');
        } else {
          debugPrint('ERROR: FCM token was not saved properly for user: ${currentUser.uid}');
        }
      } else {
        debugPrint('FCM token already exists for user: ${currentUser.uid}');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Delete FCM token from the current user's document in Firestore
  Future<void> deleteToken() async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        debugPrint('No user logged in, cannot delete FCM token');
        return;
      }

      // Determine the correct collection based on user type, fallback to 'clientes'
      final collection = await _getUserCollection(currentUser.uid) ?? 'clientes';

      final userDoc = _firestore.collection(collection).doc(currentUser.uid);
      
      // Remove all tokens (or you can pass specific token to remove)
      await userDoc.update({
        'fcmTokens': FieldValue.delete(),
      });
      
      debugPrint('FCM tokens deleted successfully for user: ${currentUser.uid}');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  /// Remove a specific token from the user's tokens array
  Future<void> removeToken(String token) async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        debugPrint('No user logged in, cannot remove FCM token');
        return;
      }

      // Determine the correct collection based on user type, fallback to 'clientes'
      final collection = await _getUserCollection(currentUser.uid) ?? 'clientes';

      final userDoc = _firestore.collection(collection).doc(currentUser.uid);

      await userDoc.update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });

      debugPrint('FCM token removed successfully for user: ${currentUser.uid}');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Get all FCM tokens for the current user
  Future<List<String>> getTokens() async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        debugPrint('No user logged in, cannot get FCM tokens');
        return [];
      }

      // Determine the correct collection based on user type, fallback to 'clientes'
      final collection = await _getUserCollection(currentUser.uid) ?? 'clientes';

      final userDoc = await _firestore.collection(collection).doc(currentUser.uid).get();

      if (!userDoc.exists) {
        debugPrint('User document does not exist');
        return [];
      }

      final data = userDoc.data();
      return List<String>.from(data?['fcmTokens'] ?? []);
    } catch (e) {
      debugPrint('Error getting FCM tokens: $e');
      return [];
    }
  }
}
