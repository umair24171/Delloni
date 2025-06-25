import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new review
  Future<Map<String, dynamic>> createReview({
    required String revieweeId, // Person being reviewed
    required String itemId,
    required double rating,
    required String comment,
    required String transactionType, // 'purchase' or 'sale'
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      log('Creating review - ReviewerId: ${user.uid}, RevieweeId: $revieweeId, ItemId: $itemId');

      // Check if user already reviewed this transaction
      QuerySnapshot existingReview = await _firestore
          .collection('reviews')
          .where('reviewerId', isEqualTo: user.uid)
          .where('revieweeId', isEqualTo: revieweeId)
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      if (existingReview.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'You have already reviewed this transaction',
        };
      }

      // Get reviewer data
      DocumentSnapshot reviewerDoc = await _firestore.collection('users').doc(user.uid).get();
      log('Reviewer doc exists: ${reviewerDoc.exists}');
      
      if (!reviewerDoc.exists) {
        return {
          'success': false,
          'message': 'Reviewer profile not found. Please complete your profile first.',
        };
      }

      // Get reviewee data
      DocumentSnapshot revieweeDoc = await _firestore.collection('users').doc(revieweeId).get();
      log('Reviewee doc exists: ${revieweeDoc.exists}');
      
      if (!revieweeDoc.exists) {
        return {
          'success': false,
          'message': 'Seller profile not found.',
        };
      }

      // Get item data
      DocumentSnapshot itemDoc = await _firestore.collection('items').doc(itemId).get();
      log('Item doc exists: ${itemDoc.exists}');
      
      if (!itemDoc.exists) {
        return {
          'success': false,
          'message': 'Product not found.',
        };
      }

      // Extract data with proper field names
      Map<String, dynamic> reviewerData = reviewerDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;

      // Get reviewer name based on your user model structure
      String reviewerName = 'Anonymous';
      String reviewerType = reviewerData['type'] ?? 'individual';
      
      if (reviewerType == 'company') {
        reviewerName = reviewerData['companyName'] ?? 'Company User';
      } else {
        // For individual users, you might want to use email or create a display name
        reviewerName = reviewerData['email']?.split('@')[0] ?? 'Individual User';
      }

      // Get item title - check both possible field names
      String itemTitle = itemData['itemTitle'] ?? itemData['title'] ?? 'Unknown Item';

      log('Creating review with - ReviewerName: $reviewerName, ReviewerType: $reviewerType, ItemTitle: $itemTitle');

      // Create review document
      String reviewId = _firestore.collection('reviews').doc().id;
      
      await _firestore.collection('reviews').doc(reviewId).set({
        'reviewId': reviewId,
        'reviewerId': user.uid,
        'reviewerName': reviewerName,
        'reviewerType': reviewerType,
        'revieweeId': revieweeId,
        'itemId': itemId,
        'itemTitle': itemTitle,
        'rating': rating,
        'comment': comment.trim(),
        'transactionType': transactionType,
        'createdAt': FieldValue.serverTimestamp(),
        'isReported': false,
        'helpfulCount': 0,
      });

      log('Review document created successfully with ID: $reviewId');

      // Update reviewee's rating statistics
      await _updateUserRatingStats(revieweeId, rating);

      return {
        'success': true,
        'message': 'Review submitted successfully',
        'reviewId': reviewId,
      };
    } catch (e) {
      log('Error creating review: $e');
      return {
        'success': false,
        'message': 'Failed to submit review: ${e.toString()}',
      };
    }
  }

  // Update user rating statistics
  Future<void> _updateUserRatingStats(String userId, double newRating) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          log('User document does not exist for rating update: $userId');
          return;
        }
        
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        double currentAverage = userData['averageRating']?.toDouble() ?? 0.0;
        int currentCount = userData['reviewCount'] ?? 0;
        
        // Calculate new average
        double newAverage = currentCount == 0 
            ? newRating 
            : ((currentAverage * currentCount) + newRating) / (currentCount + 1);
        
        transaction.update(userRef, {
          'averageRating': newAverage,
          'reviewCount': currentCount + 1,
          'lastReviewAt': FieldValue.serverTimestamp(),
        });
        
        log('Updated rating stats for user $userId: $newAverage (${currentCount + 1} reviews)');
      });
    } catch (e) {
      log('Error updating rating stats: $e');
    }
  }

  // Get reviews for a specific user
  Stream<QuerySnapshot> getUserReviews(
    String userId, {
    int limit = 20,
    String? orderBy = 'createdAt',
    bool descending = true,
  }) {
    return _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: userId)
        .orderBy(orderBy!, descending: descending)
        .limit(limit)
        .snapshots();
  }

  // Get reviews given by a specific user
  Stream<QuerySnapshot> getReviewsByUser(
    String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('reviews')
        .where('reviewerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get reviews for a specific item
  Stream<QuerySnapshot> getItemReviews(
    String itemId, {
    int limit = 10,
  }) {
    return _firestore
        .collection('reviews')
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get user rating summary
  Future<Map<String, dynamic>> getUserRatingSummary(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return {
          'averageRating': 0.0,
          'reviewCount': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      // Get rating distribution
      QuerySnapshot reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('revieweeId', isEqualTo: userId)
          .get();

      Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      
      for (DocumentSnapshot doc in reviewsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int rating = (data['rating']?.toDouble() ?? 0.0).round();
        if (rating >= 1 && rating <= 5) {
          distribution[rating] = (distribution[rating] ?? 0) + 1;
        }
      }

      return {
        'averageRating': userData['averageRating']?.toDouble() ?? 0.0,
        'reviewCount': userData['reviewCount'] ?? 0,
        'ratingDistribution': distribution,
      };
    } catch (e) {
      log('Error getting rating summary: $e');
      return {
        'averageRating': 0.0,
        'reviewCount': 0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  // Mark review as helpful
  Future<bool> markReviewHelpful(String reviewId, String userId) async {
    try {
      DocumentReference reviewRef = _firestore.collection('reviews').doc(reviewId);
      
      // Check if user already marked this review as helpful
      DocumentSnapshot helpfulDoc = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .collection('helpful')
          .doc(userId)
          .get();

      if (helpfulDoc.exists) {
        // Remove helpful mark
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot reviewDoc = await transaction.get(reviewRef);
          if (reviewDoc.exists) {
            int currentCount = reviewDoc['helpfulCount'] ?? 0;
            
            transaction.update(reviewRef, {
              'helpfulCount': currentCount > 0 ? currentCount - 1 : 0,
            });
            
            transaction.delete(helpfulDoc.reference);
          }
        });
        return false; // Unmarked
      } else {
        // Add helpful mark
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot reviewDoc = await transaction.get(reviewRef);
          if (reviewDoc.exists) {
            int currentCount = reviewDoc['helpfulCount'] ?? 0;
            
            transaction.update(reviewRef, {
              'helpfulCount': currentCount + 1,
            });
            
            transaction.set(
              _firestore.collection('reviews').doc(reviewId).collection('helpful').doc(userId),
              {
                'userId': userId,
                'markedAt': FieldValue.serverTimestamp(),
              },
            );
          }
        });
        return true; // Marked
      }
    } catch (e) {
      log('Error marking review helpful: $e');
      return false;
    }
  }

  // Report a review
  Future<bool> reportReview(String reviewId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('review_reports').add({
        'reviewId': reviewId,
        'reporterId': user.uid,
        'reason': reason,
        'reportedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Update review to mark as reported
      await _firestore.collection('reviews').doc(reviewId).update({
        'isReported': true,
      });

      return true;
    } catch (e) {
      log('Error reporting review: $e');
      return false;
    }
  }

  // Delete review (only by reviewer)
  Future<bool> deleteReview(String reviewId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      
      if (!reviewDoc.exists) return false;

      Map<String, dynamic> reviewData = reviewDoc.data() as Map<String, dynamic>;
      
      // Check if current user is the reviewer
      if (reviewData['reviewerId'] != user.uid) return false;

      // Update reviewee's rating stats (subtract this rating)
      await _subtractFromUserRatingStats(reviewData['revieweeId'], reviewData['rating'].toDouble());

      // Delete the review
      await _firestore.collection('reviews').doc(reviewId).delete();

      return true;
    } catch (e) {
      log('Error deleting review: $e');
      return false;
    }
  }

  // Subtract rating from user stats when review is deleted
  Future<void> _subtractFromUserRatingStats(String userId, double removedRating) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) return;
        
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        double currentAverage = userData['averageRating']?.toDouble() ?? 0.0;
        int currentCount = userData['reviewCount'] ?? 0;
        
        if (currentCount <= 1) {
          // If this was the only review, reset to 0
          transaction.update(userRef, {
            'averageRating': 0.0,
            'reviewCount': 0,
          });
        } else {
          // Recalculate average without this rating
          double newAverage = ((currentAverage * currentCount) - removedRating) / (currentCount - 1);
          
          transaction.update(userRef, {
            'averageRating': newAverage,
            'reviewCount': currentCount - 1,
          });
        }
      });
    } catch (e) {
      log('Error updating rating stats after deletion: $e');
    }
  }

  // Check if user can review (prevent self reviews and duplicate reviews)
  Future<bool> canUserReview(String itemId, String sellerId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Can't review your own item
      if (user.uid == sellerId) return false;
      
      // Check if already reviewed
      QuerySnapshot existingReview = await _firestore
          .collection('reviews')
          .where('reviewerId', isEqualTo: user.uid)
          .where('revieweeId', isEqualTo: sellerId)
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();
      
      return existingReview.docs.isEmpty;
    } catch (e) {
      log('Error checking review eligibility: $e');
      return false;
    }
  }

  // Get eligible items for review (simplified version)
  Future<List<Map<String, dynamic>>> getEligibleItemsForReview(String userId) async {
    try {
      // For now, return empty list since transaction system might not be implemented
      // This can be expanded when you have a proper transaction/order system
      return [];
    } catch (e) {
      log('Error getting eligible items: $e');
      return [];
    }
  }

  // Utility method to verify document existence
  Future<bool> verifyDocumentExists(String collection, String documentId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collection).doc(documentId).get();
      bool exists = doc.exists;
      log('Document $collection/$documentId exists: $exists');
      return exists;
    } catch (e) {
      log('Error verifying document existence: $e');
      return false;
    }
  }

  // Debug method to check all required documents
  Future<Map<String, bool>> debugCheckDocuments({
    required String reviewerId,
    required String revieweeId,
    required String itemId,
  }) async {
    return {
      'reviewer': await verifyDocumentExists('users', reviewerId),
      'reviewee': await verifyDocumentExists('users', revieweeId),
      'item': await verifyDocumentExists('items', itemId),
    };
  }
}