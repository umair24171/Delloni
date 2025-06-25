import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AccountService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No user is currently logged in',
        };
      }

      // Update user's last seen timestamp before logout
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': false,
        });
      } catch (e) {
        // Non-critical error
        log('Failed to update last seen: $e');
      }

      // Sign out from Firebase Auth
      await _auth.signOut();
      
      // Sign out from Google if signed in with Google
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        // Google sign out failed, but this is not critical
        log('Google sign out failed: $e');
      }

      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    } catch (e) {
      log('Logout error: $e');
      return {
        'success': false,
        'message': 'Failed to logout: ${e.toString()}',
      };
    }
  }

  // Delete user account and all associated data
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No user is currently logged in',
        };
      }

      final userId = user.uid;
      
      // Step 1: Delete user's items/listings
      await _deleteUserItems(userId);
      
      // Step 2: Delete user's messages and conversations
      await _deleteUserMessages(userId);
      
      // Step 3: Delete user's reviews and ratings
      await _deleteUserReviews(userId);
      
      // Step 4: Delete user's favorites
      await _deleteUserFavorites(userId);
      
      // Step 5: Delete user's notifications
      await _deleteUserNotifications(userId);
      
      // Step 6: Delete user's contact submissions and support tickets
      await _deleteUserSupportData(userId);
      
      // Step 7: Delete user's profile images and other files
      await _deleteUserFiles(userId);
      
      // Step 8: Delete user document from Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Step 9: Delete user location data
      try {
        await _firestore.collection('users').doc(userId).collection('location').doc('current').delete();
      } catch (e) {
        log('Failed to delete location data: $e');
      }
      
      // Step 10: Finally delete the Firebase Auth user
      await user.delete();
      
      // Sign out from Google if signed in with Google
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        log('Google sign out failed: $e');
      }

      return {
        'success': true,
        'message': 'Account deleted successfully',
      };
    } catch (e) {
      log('Delete account error: $e');
      
      // Handle specific Firebase Auth errors
      if (e is FirebaseAuthException) {
        if (e.code == 'requires-recent-login') {
          return {
            'success': false,
            'message': 'For security reasons, please log in again before deleting your account',
            'requiresReauth': true,
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Failed to delete account: ${e.toString()}',
      };
    }
  }

  // Delete user's items/listings
  Future<void> _deleteUserItems(String userId) async {
    try {
      final itemsQuery = await _firestore
          .collection('items')
          .where('sellerId', isEqualTo: userId)
          .get();

      for (var doc in itemsQuery.docs) {
        // Delete item images from storage
        final imageUrls = List<String>.from(doc.data()['imageUrls'] ?? []);
        for (var imageUrl in imageUrls) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (e) {
            log('Failed to delete item image: $e');
          }
        }
        
        // Delete item document
        await doc.reference.delete();
      }
      
      log('Deleted ${itemsQuery.docs.length} items for user $userId');
    } catch (e) {
      log('Error deleting user items: $e');
    }
  }

  // Delete user's messages and conversations
  Future<void> _deleteUserMessages(String userId) async {
    try {
      // Delete conversations where user is participant
      final conversationsQuery = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .get();

      for (var doc in conversationsQuery.docs) {
        // Delete all messages in this conversation
        final messagesQuery = await doc.reference.collection('messages').get();
        for (var messageDoc in messagesQuery.docs) {
          await messageDoc.reference.delete();
        }
        
        // Delete conversation document
        await doc.reference.delete();
      }
      
      log('Deleted ${conversationsQuery.docs.length} conversations for user $userId');
    } catch (e) {
      log('Error deleting user messages: $e');
    }
  }

  // Delete user's reviews and ratings
  Future<void> _deleteUserReviews(String userId) async {
    try {
      // Delete reviews given by user
      final reviewsGivenQuery = await _firestore
          .collection('reviews')
          .where('reviewerId', isEqualTo: userId)
          .get();

      for (var doc in reviewsGivenQuery.docs) {
        await doc.reference.delete();
      }

      // Delete reviews received by user
      final reviewsReceivedQuery = await _firestore
          .collection('reviews')
          .where('revieweeId', isEqualTo: userId)
          .get();

      for (var doc in reviewsReceivedQuery.docs) {
        await doc.reference.delete();
      }
      
      log('Deleted reviews for user $userId');
    } catch (e) {
      log('Error deleting user reviews: $e');
    }
  }

  // Delete user's favorites
  Future<void> _deleteUserFavorites(String userId) async {
    try {
      final favoritesQuery = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in favoritesQuery.docs) {
        await doc.reference.delete();
      }
      
      log('Deleted ${favoritesQuery.docs.length} favorites for user $userId');
    } catch (e) {
      log('Error deleting user favorites: $e');
    }
  }

  // Delete user's notifications
  Future<void> _deleteUserNotifications(String userId) async {
    try {
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in notificationsQuery.docs) {
        await doc.reference.delete();
      }
      
      log('Deleted ${notificationsQuery.docs.length} notifications for user $userId');
    } catch (e) {
      log('Error deleting user notifications: $e');
    }
  }

  // Delete user's support data (contact submissions, bug reports)
  Future<void> _deleteUserSupportData(String userId) async {
    try {
      // Delete contact submissions
      final contactQuery = await _firestore
          .collection('contact_submissions')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in contactQuery.docs) {
        await doc.reference.delete();
      }

      // Delete bug reports
      final bugReportsQuery = await _firestore
          .collection('bug_reports')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in bugReportsQuery.docs) {
        await doc.reference.delete();
      }

      // Delete terms acceptances
      final termsQuery = await _firestore
          .collection('user_legal_acceptances')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in termsQuery.docs) {
        await doc.reference.delete();
      }
      
      log('Deleted support data for user $userId');
    } catch (e) {
      log('Error deleting user support data: $e');
    }
  }

  // Delete user's files from Storage
  Future<void> _deleteUserFiles(String userId) async {
    try {
      // Delete profile images
      try {
        final profileRef = _storage.ref().child('company_profiles/$userId');
        final profileItems = await profileRef.listAll();
        for (var item in profileItems.items) {
          await item.delete();
        }
      } catch (e) {
        log('No profile images to delete or error: $e');
      }

      // Delete item images (if any remain)
      try {
        final itemsRef = _storage.ref().child('items');
        final itemsFolders = await itemsRef.listAll();
        for (var folder in itemsFolders.prefixes) {
          if (folder.name.contains(userId)) {
            final items = await folder.listAll();
            for (var item in items.items) {
              await item.delete();
            }
          }
        }
      } catch (e) {
        log('No item images to delete or error: $e');
      }
      
      log('Deleted files for user $userId');
    } catch (e) {
      log('Error deleting user files: $e');
    }
  }

  // Re-authenticate user before account deletion (if required)
  Future<Map<String, dynamic>> reauthenticateUser(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No user is currently logged in',
        };
      }

      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);

      return {
        'success': true,
        'message': 'Re-authentication successful',
      };
    } catch (e) {
      log('Re-authentication error: $e');
      return {
        'success': false,
        'message': 'Re-authentication failed: ${e.toString()}',
      };
    }
  }

  // Get user data before deletion (for confirmation)
  Future<Map<String, dynamic>> getUserDeletionSummary() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No user is currently logged in',
        };
      }

      final userId = user.uid;
      
      // Count user's data
      final itemsCount = await _firestore
          .collection('items')
          .where('sellerId', isEqualTo: userId)
          .get()
          .then((snapshot) => snapshot.docs.length);

      final conversationsCount = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .get()
          .then((snapshot) => snapshot.docs.length);

      final reviewsCount = await _firestore
          .collection('reviews')
          .where('reviewerId', isEqualTo: userId)
          .get()
          .then((snapshot) => snapshot.docs.length);

      final favoritesCount = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get()
          .then((snapshot) => snapshot.docs.length);

      return {
        'success': true,
        'data': {
          'email': user.email,
          'itemsCount': itemsCount,
          'conversationsCount': conversationsCount,
          'reviewsCount': reviewsCount,
          'favoritesCount': favoritesCount,
          'accountCreated': user.metadata.creationTime?.toIso8601String(),
        },
      };
    } catch (e) {
      log('Error getting user deletion summary: $e');
      return {
        'success': false,
        'message': 'Failed to get account summary: ${e.toString()}',
      };
    }
  }

  // Update user online status
  Future<void> updateUserOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      log('Error updating online status: $e');
    }
  }

  // Check if user needs to re-authenticate
  bool needsReauthentication() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final lastSignIn = user.metadata.lastSignInTime;
    if (lastSignIn == null) return true;
    
    final now = DateTime.now();
    final timeSinceLastSignIn = now.difference(lastSignIn);
    
    // Require re-auth if last sign in was more than 5 minutes ago
    return timeSinceLastSignIn.inMinutes > 5;
  }
}