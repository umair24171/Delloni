import 'package:arabicmarketplace/controller/review_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CreateReviewPage extends StatefulWidget {
  final List<Map<String, dynamic>> eligibleItems;

  const CreateReviewPage({
    Key? key,
    required this.eligibleItems,
  }) : super(key: key);

  @override
  State<CreateReviewPage> createState() => _CreateReviewPageState();
}

class _CreateReviewPageState extends State<CreateReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  
  Map<String, dynamic>? _selectedItem;
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Write a Review',
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Selection
              _buildSectionTitle('Select Item'),
              const SizedBox(height: 12),
              _buildItemSelection(),
              const SizedBox(height: 24),

              // Rating Section
              if (_selectedItem != null) ...[
                _buildSectionTitle('Your Rating'),
                const SizedBox(height: 12),
                _buildRatingSection(),
                const SizedBox(height: 24),

                // Comment Section
                _buildSectionTitle('Your Review'),
                const SizedBox(height: 12),
                _buildCommentSection(),
                const SizedBox(height: 32),

                // Submit Button
                _buildSubmitButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildItemSelection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: widget.eligibleItems.map((item) {
          bool isSelected = _selectedItem?['itemId'] == item['itemId'];
          
          return InkWell(
            onTap: () {
              setState(() {
                _selectedItem = item;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEC6A5A).withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: const Color(0xFFEC6A5A), width: 2) : null,
              ),
              child: Row(
                children: [
                  // Selection indicator
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFFEC6A5A) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? const Color(0xFFEC6A5A) : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  
                  // Item info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['itemTitle'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seller: ${item['sellerName']}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Transaction: ${_formatDate(item['transactionDate'])}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            'How would you rate your experience?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = index + 1.0;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.star,
                    size: 40,
                    color: index < _rating ? Colors.amber : Colors.grey[300],
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 12),
          
          // Rating text
          Text(
            _getRatingText(_rating),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getRatingColor(_rating),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell others about your experience (optional)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _commentController,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Share details about your transaction...',
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEC6A5A)),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.poppins(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC6A5A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Submit Review',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent';
  }

  Color _getRatingColor(double rating) {
    if (rating <= 2) return Colors.red;
    if (rating <= 3) return Colors.orange;
    if (rating <= 4) return Colors.blue;
    return Colors.green;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown date';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Unknown date';
    }
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _submitReview() async {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an item to review'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reviewProvider = context.read<ReviewProvider>();
      
      bool success = await reviewProvider.createReview(
        revieweeId: _selectedItem!['sellerId'],
        itemId: _selectedItem!['itemId'],
        rating: _rating,
        comment: _commentController.text.trim(),
        transactionType: 'purchase',
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reviewProvider.error ?? 'Failed to submit review'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}