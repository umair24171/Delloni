
// Review model
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String reviewerId;
  final String reviewerName;
  final String reviewerType;
  final String revieweeId;
  final String itemId;
  final String itemTitle;
  final double rating;
  final String comment;
  final String transactionType;
  final DateTime createdAt;
  final bool isReported;
  final int helpfulCount;

  ReviewModel({
    required this.reviewId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerType,
    required this.revieweeId,
    required this.itemId,
    required this.itemTitle,
    required this.rating,
    required this.comment,
    required this.transactionType,
    required this.createdAt,
    required this.isReported,
    required this.helpfulCount,
  });

  factory ReviewModel.fromFirestore(Map<String, dynamic> data) {
    return ReviewModel(
      reviewId: data['reviewId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? 'Anonymous',
      reviewerType: data['reviewerType'] ?? 'individual',
      revieweeId: data['revieweeId'] ?? '',
      itemId: data['itemId'] ?? '',
      itemTitle: data['itemTitle'] ?? '',
      rating: data['rating']?.toDouble() ?? 0.0,
      comment: data['comment'] ?? '',
      transactionType: data['transactionType'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isReported: data['isReported'] ?? false,
      helpfulCount: data['helpfulCount'] ?? 0,
    );
  }

  ReviewModel copyWith({
    String? reviewId,
    String? reviewerId,
    String? reviewerName,
    String? reviewerType,
    String? revieweeId,
    String? itemId,
    String? itemTitle,
    double? rating,
    String? comment,
    String? transactionType,
    DateTime? createdAt,
    bool? isReported,
    int? helpfulCount,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerType: reviewerType ?? this.reviewerType,
      revieweeId: revieweeId ?? this.revieweeId,
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      transactionType: transactionType ?? this.transactionType,
      createdAt: createdAt ?? this.createdAt,
      isReported: isReported ?? this.isReported,
      helpfulCount: helpfulCount ?? this.helpfulCount,
    );
  }

  // Helper method to get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // Helper method to get star rating display
  String get starsDisplay {
    return '★' * rating.round() + '☆' * (5 - rating.round());
  }
}