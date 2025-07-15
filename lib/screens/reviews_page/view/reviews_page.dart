import 'package:arabicmarketplace/controller/review_provider.dart';
import 'package:arabicmarketplace/screens/reviews_page/model/review_model.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
class ReviewsPage extends StatefulWidget {
  final String? userId; // If null, shows current user's reviews
  final bool showCreateReviewButton;
  
  const ReviewsPage({
    Key? key,
    this.userId,
    this.showCreateReviewButton = true,
  }) : super(key: key);

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isCurrentUser ? 2 : 1, vsync: this);
    
    // Determine if viewing current user's reviews
    final currentUser = FirebaseAuth.instance.currentUser;
    _isCurrentUser = widget.userId == null || widget.userId == currentUser?.uid;
    
    // Load reviews
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReviewProvider>();
      if (widget.userId != null && !_isCurrentUser) {
        provider.loadUserReviews(widget.userId!);
        provider.loadRatingSummary(widget.userId!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isCurrentUser ? AppLocalizations.myReviews.tr() : AppLocalizations.reviews.tr(),
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        centerTitle: false,
        bottom: _isCurrentUser 
          ? TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.onBackground,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: const Color(0xFFEC6A5A),
              tabs: [
                Tab(text: AppLocalizations.received.tr()),
                Tab(text: AppLocalizations.given.tr()),
              ],
            )
          : null,
        actions: [
          if (widget.showCreateReviewButton && _isCurrentUser)
            IconButton(
              icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onBackground),
              onPressed: () => _showCreateReviewDialog(),
            ),
        ],
      ),
      body: _isCurrentUser 
        ? TabBarView(
            controller: _tabController,
            children: [
              _buildReceivedReviewsTab(),
              _buildGivenReviewsTab(),
            ],
          )
        : _buildReceivedReviewsTab(),
      floatingActionButton: widget.showCreateReviewButton && _isCurrentUser 
        ? FloatingActionButton(
            onPressed: () => _showCreateReviewDialog(),
            backgroundColor: const Color(0xFFEC6A5A),
            child: const Icon(Icons.add, color: Colors.white),
          )
        : null,
    );
  }

  Widget _buildReceivedReviewsTab() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        if (reviewProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => reviewProvider.refresh(),
          child: CustomScrollView(
            slivers: [
              // Rating Summary
              SliverToBoxAdapter(
                child: _buildRatingSummary(reviewProvider),
              ),
              
              // Reviews List
              if (reviewProvider.userReviews.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(
                    AppLocalizations.noReviewsYet.tr(), 
                    _isCurrentUser 
                      ? AppLocalizations.reviewsFromBuyersSellers.tr()
                      : AppLocalizations.thisUserHasntReceivedReviews.tr()
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final review = reviewProvider.userReviews[index];
                      return _buildReviewCard(review, reviewProvider);
                    },
                    childCount: reviewProvider.userReviews.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGivenReviewsTab() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        if (reviewProvider.givenReviews.isEmpty) {
          return _buildEmptyState(
            AppLocalizations.noReviewsGivenYet.tr(),
            AppLocalizations.reviewsYouveWritten.tr(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => reviewProvider.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviewProvider.givenReviews.length,
            itemBuilder: (context, index) {
              final review = reviewProvider.givenReviews[index];
              return _buildReviewCard(review, reviewProvider, showActions: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildRatingSummary(ReviewProvider reviewProvider) {
    final summary = reviewProvider.ratingSummary;
    final averageRating = summary['averageRating']?.toDouble() ?? 0.0;
    final reviewCount = summary['reviewCount'] ?? 0;
    final distribution = Map<int, int>.from(summary['ratingDistribution'] ?? {});

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Overall Rating
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStarRating(averageRating, size: 20),
                    const SizedBox(height: 8),
                    Text(
                      '$reviewCount ${reviewCount == 1 ? AppLocalizations.review.tr() : AppLocalizations.reviewsPlural.tr()}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Rating Distribution
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    for (int i = 5; i >= 1; i--)
                      _buildRatingBar(i, distribution[i] ?? 0, reviewCount),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    double percentage = total > 0 ? count / total : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC6A5A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review, ReviewProvider reviewProvider, {bool showActions = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFEC6A5A),
                  child: Text(
                    review.reviewerName.isNotEmpty 
                        ? review.reviewerName[0].toUpperCase() 
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        review.formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showActions)
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleReviewAction(value, review, reviewProvider),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppLocalizations.deleteReview.tr()),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Rating
            Row(
              children: [
                _buildStarRating(review.rating),
                const SizedBox(width: 8),
                Text(
                  '${review.rating.toStringAsFixed(1)} ${AppLocalizations.stars.tr()}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Item info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${AppLocalizations.item.tr()}: ${review.itemTitle}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Comment
            if (review.comment.isNotEmpty)
              Text(
                review.comment,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Actions
            Row(
              children: [
                // Helpful button
                if (!showActions)
                  InkWell(
                    onTap: () => reviewProvider.markReviewHelpful(review.reviewId),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_up_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${AppLocalizations.helpful.tr()} (${review.helpfulCount})',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Spacer(),
                
                // Report button
                if (!showActions && !_isCurrentUser)
                  TextButton(
                    onPressed: () => _showReportDialog(review, reviewProvider),
                    child: Text(
                      AppLocalizations.report.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                
                // Transaction type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: review.transactionType == 'purchase' 
                        ? Theme.of(context).colorScheme.primaryContainer 
                        : Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    review.transactionType == 'purchase' 
                        ? AppLocalizations.buyer.tr() 
                        : AppLocalizations.seller.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: review.transactionType == 'purchase' 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() 
              ? Icons.star 
              : index < rating.ceil() 
                  ? Icons.star_half 
                  : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleReviewAction(String action, ReviewModel review, ReviewProvider reviewProvider) {
    switch (action) {
      case 'delete':
        _showDeleteConfirmation(review, reviewProvider);
        break;
    }
  }

  void _showDeleteConfirmation(ReviewModel review, ReviewProvider reviewProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.deleteReview.tr(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          AppLocalizations.areYouSureDeleteReview.tr(),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.cancel.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await reviewProvider.deleteReview(review.reviewId);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(reviewProvider.error ?? AppLocalizations.failedToDeleteReview.tr()),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.delete.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(ReviewModel review, ReviewProvider reviewProvider) {
    String selectedReason = AppLocalizations.inappropriateContent.tr();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.reportReview.tr(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.whyReportingReview.tr(),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedReason,
              items: [
                AppLocalizations.inappropriateContent.tr(),
                AppLocalizations.spam.tr(),
                AppLocalizations.fakeReview.tr(),
                AppLocalizations.harassment.tr(),
                AppLocalizations.other.tr(),
              ].map((reason) => DropdownMenuItem(
                value: reason,
                child: Text(reason, style: GoogleFonts.poppins()),
              )).toList(),
              onChanged: (value) => selectedReason = value!,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                labelStyle: GoogleFonts.poppins(),
                hintStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.cancel.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await reviewProvider.reportReview(review.reviewId, selectedReason);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? AppLocalizations.reviewReportedSuccessfully.tr()
                        : AppLocalizations.failedToReportReview.tr()),
                    backgroundColor: success ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.report.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateReviewDialog() async {
    final reviewProvider = context.read<ReviewProvider>();
    List<Map<String, dynamic>> eligibleItems = await reviewProvider.getEligibleItemsForReview();
    
    if (eligibleItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.noItemsAvailableForReview.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => CreateReviewPage(eligibleItems: eligibleItems),
    //   ),
    // );
  }
}