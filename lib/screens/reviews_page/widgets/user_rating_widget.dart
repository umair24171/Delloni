import 'package:arabicmarketplace/controller/review_provider.dart';
import 'package:arabicmarketplace/controller/review_service.dart';
import 'package:arabicmarketplace/screens/reviews_page/view/reviews_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../model/review_model.dart';

// Compact rating display widget for user profiles
class UserRatingWidget extends StatelessWidget {
  final String userId;
  final bool showCount;
  final double iconSize;
  final double fontSize;

  const UserRatingWidget({
    Key? key,
    required this.userId,
    this.showCount = true,
    this.iconSize = 16,
    this.fontSize = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReviewService().getUserRatingSummary(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: iconSize, color: Colors.grey[300]),
              const SizedBox(width: 4),
              Text(
                '--',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  color: Colors.grey[500],
                ),
              ),
            ],
          );
        }

        final data = snapshot.data!;
        final rating = data['averageRating']?.toDouble() ?? 0.0;
        final count = data['reviewCount'] ?? 0;

        if (count == 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border, size: iconSize, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                'No reviews',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  color: Colors.grey[500],
                ),
              ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: iconSize, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showCount) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: GoogleFonts.poppins(
                  fontSize: fontSize - 2,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// Recent reviews widget for user profiles
class RecentReviewsWidget extends StatelessWidget {
  final String userId;
  final int maxReviews;

  const RecentReviewsWidget({
    Key? key,
    required this.userId,
    this.maxReviews = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ReviewService().getUserReviews(userId, limit: maxReviews),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No reviews yet',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        final reviews = snapshot.data!.docs
            .map((doc) => ReviewModel.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewsPage(userId: userId, showCreateReviewButton: false),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFFEC6A5A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...reviews.map((review) => _buildCompactReviewCard(review)),
          ],
        );
      },
    );
  }

  Widget _buildCompactReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFFEC6A5A),
                child: Text(
                  review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildStarRating(review.rating, size: 12),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            review.formattedDate,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 12}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}

// Rating summary card for item details
class ItemRatingWidget extends StatelessWidget {
  final String itemId;

  const ItemRatingWidget({
    Key? key,
    required this.itemId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReviewModel>>(
      stream: context.read<ReviewProvider>().getItemReviews(itemId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final reviews = snapshot.data!;
        final averageRating = reviews.fold(0.0, (sum, review) => sum + review.rating) / reviews.length;

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${averageRating.toStringAsFixed(1)} (${reviews.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...reviews.take(2).map((review) => _buildMiniReviewCard(review)),
              if (reviews.length > 2) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Show all item reviews dialog
                      _showAllItemReviews(context, itemId, reviews);
                    },
                    child: Text(
                      'View all ${reviews.length} reviews',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFEC6A5A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.reviewerName,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              ...List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 12,
                );
              }),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.comment,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  void _showAllItemReviews(BuildContext context, String itemId, List<ReviewModel> reviews) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'All Reviews',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return _buildFullReviewCard(reviews[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFEC6A5A),
                child: Text(
                  review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      review.formattedDate,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Quick action button to leave a review
class LeaveReviewButton extends StatelessWidget {
  final String sellerId;
  final String itemId;
  final String itemTitle;

  const LeaveReviewButton({
    Key? key,
    required this.sellerId,
    required this.itemId,
    required this.itemTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showQuickReviewDialog(context),
      icon: const Icon(Icons.star_outline, size: 18),
      label: Text(
        'Leave Review',
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFEC6A5A),
        side: const BorderSide(color: Color(0xFFEC6A5A)),
      ),
    );
  }

  void _showQuickReviewDialog(BuildContext context) {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Rate your experience',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                itemTitle,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => rating = index + 1.0),
                    child: Icon(
                      Icons.star,
                      size: 32,
                      color: index < rating ? Colors.amber : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Leave a comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final reviewProvider = context.read<ReviewProvider>();
                
                bool success = await reviewProvider.createReview(
                  revieweeId: sellerId,
                  itemId: itemId,
                  rating: rating,
                  comment: commentController.text.trim(),
                  transactionType: 'purchase',
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                          ? 'Review submitted successfully!' 
                          : 'Failed to submit review'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC6A5A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}