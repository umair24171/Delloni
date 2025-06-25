import 'dart:async';
import 'dart:developer';
import 'package:arabicmarketplace/controller/review_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/reviews_page/model/review_model.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  
  // State management
  List<ReviewModel> _userReviews = [];
  List<ReviewModel> _givenReviews = [];
  Map<String, dynamic> _ratingSummary = {};
  bool _isLoading = false;
  String? _error;
  
  // Streams
  StreamSubscription? _userReviewsSubscription;
  StreamSubscription? _givenReviewsSubscription;

  // Getters
  List<ReviewModel> get userReviews => _userReviews;
  List<ReviewModel> get givenReviews => _givenReviews;
  Map<String, dynamic> get ratingSummary => _ratingSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  double get averageRating => _ratingSummary['averageRating']?.toDouble() ?? 0.0;
  int get reviewCount => _ratingSummary['reviewCount'] ?? 0;
  Map<int, int> get ratingDistribution => 
      Map<int, int>.from(_ratingSummary['ratingDistribution'] ?? {1: 0, 2: 0, 3: 0, 4: 0, 5: 0});

  ReviewProvider() {
    _initialize();
  }

  void _initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      loadUserReviews(user.uid);
      loadGivenReviews(user.uid);
      loadRatingSummary(user.uid);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Load reviews received by user
  void loadUserReviews(String userId) {
    _userReviewsSubscription?.cancel();
    _userReviewsSubscription = _reviewService
        .getUserReviews(userId)
        .listen(
      (QuerySnapshot snapshot) {
        _userReviews = snapshot.docs
            .map((doc) => ReviewModel.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList();
        notifyListeners();
      },
      onError: (error) {
        _setError('Error loading reviews: $error');
      },
    );
  }

  // Load reviews given by user
  void loadGivenReviews(String userId) {
    _givenReviewsSubscription?.cancel();
    _givenReviewsSubscription = _reviewService
        .getReviewsByUser(userId)
        .listen(
      (QuerySnapshot snapshot) {
        _givenReviews = snapshot.docs
            .map((doc) => ReviewModel.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList();
        notifyListeners();
      },
      onError: (error) {
        _setError('Error loading given reviews: $error');
      },
    );
  }

  // Load rating summary
  Future<void> loadRatingSummary(String userId) async {
    try {
      _setLoading(true);
      _ratingSummary = await _reviewService.getUserRatingSummary(userId);
      _setLoading(false);
    } catch (e) {
      _setError('Error loading rating summary: $e');
      _setLoading(false);
    }
  }

  // Create new review
  Future<bool> createReview({
    required String revieweeId,
    required String itemId,
    required double rating,
    required String comment,
    required String transactionType,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      
      Map<String, dynamic> result = await _reviewService.createReview(
        revieweeId: revieweeId,
        itemId: itemId,
        rating: rating,
        comment: comment,
        transactionType: transactionType,
      );

      _setLoading(false);

      if (result['success']) {
        // Refresh given reviews
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          loadGivenReviews(user.uid);
        }
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('Error creating review: $e');
      return false;
    }
  }

  // Mark review as helpful
  Future<bool> markReviewHelpful(String reviewId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      bool isMarked = await _reviewService.markReviewHelpful(reviewId, user.uid);
      
      // Update local state
      int index = _userReviews.indexWhere((review) => review.reviewId == reviewId);
      if (index != -1) {
        ReviewModel review = _userReviews[index];
        _userReviews[index] = review.copyWith(
          helpfulCount: isMarked ? review.helpfulCount + 1 : review.helpfulCount - 1,
        );
        notifyListeners();
      }

      return isMarked;
    } catch (e) {
      _setError('Error marking review helpful: $e');
      return false;
    }
  }

  // Report review
  Future<bool> reportReview(String reviewId, String reason) async {
    try {
      bool success = await _reviewService.reportReview(reviewId, reason);
      if (success) {
        _setError(null);
      } else {
        _setError('Failed to report review');
      }
      return success;
    } catch (e) {
      _setError('Error reporting review: $e');
      return false;
    }
  }

  // Delete review
  Future<bool> deleteReview(String reviewId) async {
    try {
      bool success = await _reviewService.deleteReview(reviewId);
      if (success) {
        // Remove from local state
        _givenReviews.removeWhere((review) => review.reviewId == reviewId);
        notifyListeners();
        _setError(null);
      } else {
        _setError('Failed to delete review');
      }
      return success;
    } catch (e) {
      _setError('Error deleting review: $e');
      return false;
    }
  }

  // Get item reviews
  Stream<List<ReviewModel>> getItemReviews(String itemId) {
    return _reviewService.getItemReviews(itemId).map(
      (QuerySnapshot snapshot) => snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  // Get eligible items for review
  Future<List<Map<String, dynamic>>> getEligibleItemsForReview() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      return await _reviewService.getEligibleItemsForReview(user.uid);
    } catch (e) {
      _setError('Error getting eligible items: $e');
      return [];
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      loadUserReviews(user.uid);
      loadGivenReviews(user.uid);
      await loadRatingSummary(user.uid);
    }
  }

  @override
  void dispose() {
    _userReviewsSubscription?.cancel();
    _givenReviewsSubscription?.cancel();
    super.dispose();
  }
}
