// providers/product_detail_provider.dart
import 'dart:async';
import 'dart:developer';
import 'package:arabicmarketplace/screens/chat/view/messages_screen.dart';
import 'package:arabicmarketplace/screens/product_detail/model/product_detail_model.dart';
import 'package:arabicmarketplace/screens/reviews_page/model/review_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  bool _isLoading = true;
  String? _error;
  ProductDetailModel? _product;
  SellerModel? _seller;
  List<ReviewModel> _reviews = [];
  List<ProductDetailModel> _relatedProducts = [];
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  
  // Streams
  StreamSubscription? _productSubscription;
  StreamSubscription? _sellerSubscription;
  StreamSubscription? _reviewsSubscription;
  StreamSubscription? _favoriteSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  ProductDetailModel? get product => _product;
  SellerModel? get seller => _seller;
  List<ReviewModel> get reviews => _reviews;
  List<ProductDetailModel> get relatedProducts => _relatedProducts;
  bool get isFavorite => _isFavorite;
  int get currentImageIndex => _currentImageIndex;

  // Initialize product detail with real-time updates
  Future<void> initializeProduct(String productId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Setup real-time listeners
      _setupProductListener(productId);
      await _incrementViewCount(productId);
      
    } catch (e) {
      _setError('Failed to load product: $e');
      log('ProductDetailProvider initialization error: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  // Setup real-time listeners
  void _setupProductListener(String productId) {
    _productSubscription = _firestore
        .collection('items')
        .doc(productId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        _product = ProductDetailModel.fromFirestore(snapshot);
        
        // Load seller info
        await _loadSellerInfo(_product!.sellerId);
        
        // Setup other listeners
        _setupSellerListener(_product!.sellerId);
        _setupReviewsListener(_product!.sellerId);
        _setupFavoriteListener(productId);
        
        // Load related products
        await _loadRelatedProducts();
        
        _setLoading(false);
      } else {
        _setError('Product not found');
      }
    }, onError: (e) {
      _setError('Error loading product: $e');
      log('Product stream error: $e');
    });
  }

  void _setupSellerListener(String sellerId) {
    _sellerSubscription = _firestore
        .collection('users')
        .doc(sellerId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _seller = SellerModel.fromFirestore(snapshot);
        notifyListeners();
      }
    }, onError: (e) => log('Seller stream error: $e'));
  }

  void _setupReviewsListener(String sellerId) {
    _reviewsSubscription = _firestore
        .collection('reviews')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      _reviews = snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.data()))
          .toList();
      notifyListeners();
    }, onError: (e) => log('Reviews stream error: $e'));
  }

  

  void _setupFavoriteListener(String productId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _favoriteSubscription = _firestore
        .collection('userFavorites')
        .where('userId', isEqualTo: currentUser.uid)
        .where('productId', isEqualTo: productId)
        .snapshots()
        .listen((snapshot) {
      _isFavorite = snapshot.docs.isNotEmpty;
      notifyListeners();
    }, onError: (e) => log('Favorite stream error: $e'));
  }

  // Load seller information
  Future<void> _loadSellerInfo(String sellerId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(sellerId).get();
      if (snapshot.exists) {
        _seller = SellerModel.fromFirestore(snapshot);
      }
    } catch (e) {
      log('Error loading seller info: $e');
    }
  }

  // Load related products
  Future<void> _loadRelatedProducts() async {
    if (_product == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('category', isEqualTo: _product!.category)
          .where('status', isEqualTo: 'active')
          .where(FieldPath.documentId, isNotEqualTo: _product!.id)
          .limit(6)
          .get();

      _relatedProducts = snapshot.docs
          .map((doc) => ProductDetailModel.fromFirestore(doc))
          .toList();
      
      notifyListeners();
    } catch (e) {
      log('Error loading related products: $e');
    }
  }

  // Increment view count
  Future<void> _incrementViewCount(String productId) async {
    try {
      await _firestore.collection('items').doc(productId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      log('Error incrementing view count: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite() async {
    if (_product == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('Please login to add favorites');
      return;
    }

    try {
      if (_isFavorite) {
        // Remove from favorites
        final favoriteQuery = await _firestore
            .collection('userFavorites')
            .where('userId', isEqualTo: currentUser.uid)
            .where('productId', isEqualTo: _product!.id)
            .get();

        for (var doc in favoriteQuery.docs) {
          await doc.reference.delete();
        }

        // Decrement favorite count
        await _firestore.collection('items').doc(_product!.id).update({
          'favoriteCount': FieldValue.increment(-1),
        });
      } else {
        // Add to favorites
        await _firestore.collection('userFavorites').add({
          'userId': currentUser.uid,
          'productId': _product!.id,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Increment favorite count
        await _firestore.collection('items').doc(_product!.id).update({
          'favoriteCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      _setError('Failed to update favorite: $e');
      log('Error toggling favorite: $e');
    }
  }

 // Replace your existing callSeller method and add these new methods to your ProductDetailProvider class:

// Enhanced call seller method
// Enhanced call functionality that works with ALL country codes
// Replace the existing call methods in your ProductDetailProvider

// Enhanced call seller method - works with any country code
Future<void> callSeller() async {
  try {
    String? phoneNumber = _seller?.phone;
    
    // Clean and validate phone number
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      phoneNumber = _cleanPhoneNumber(phoneNumber);
      phoneNumber = _formatPhoneNumber(phoneNumber);
      
      await _makePhoneCall(phoneNumber);
    } else {
      // If no phone number, still open dialer but show message
      await _openDialerWithMessage();
    }
  } catch (e) {
    log('Error making phone call: $e');
    // Fallback to opening dialer
    await _openDialerWithMessage();
  }
}

// Method to clean phone number (remove formatting)
String _cleanPhoneNumber(String phoneNumber) {
  // Remove spaces, dashes, parentheses, dots, and other non-digit characters except +
  return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
}

// Method to format phone number intelligently
String _formatPhoneNumber(String phoneNumber) {
  // If already has country code, return as is
  if (phoneNumber.startsWith('+')) {
    return phoneNumber;
  }
  
  // If starts with 00, replace with +
  if (phoneNumber.startsWith('00')) {
    return '+' + phoneNumber.substring(2);
  }
  
  // Auto-detect country based on app context or user location
  // For now, we'll handle common patterns but you can customize this
  
  // Pakistani numbers (for your current context)
  if (phoneNumber.startsWith('0') && phoneNumber.length >= 10) {
    return '+92' + phoneNumber.substring(1);
  }
  
  // US/Canada numbers
  if (phoneNumber.length == 10 && phoneNumber.startsWith(RegExp(r'[2-9]'))) {
    return '+1' + phoneNumber;
  }
  
  // UK numbers
  if (phoneNumber.startsWith('0') && phoneNumber.length == 11) {
    return '+44' + phoneNumber.substring(1);
  }
  
  // Indian numbers
  if (phoneNumber.length == 10 && phoneNumber.startsWith(RegExp(r'[6-9]'))) {
    return '+91' + phoneNumber;
  }
  
  // UAE numbers
  if (phoneNumber.startsWith('0') && phoneNumber.length == 9) {
    return '+971' + phoneNumber.substring(1);
  }
  
  // Saudi Arabia numbers
  if (phoneNumber.startsWith('0') && phoneNumber.length == 10) {
    return '+966' + phoneNumber.substring(1);
  }
  
  // If no pattern matches, try to detect based on length
  if (phoneNumber.length >= 7) {
    // For numbers that don't match common patterns, assume they're already properly formatted
    // or add a default country code based on your app's primary market
    return phoneNumber.startsWith('+') ? phoneNumber : '+' + phoneNumber;
  }
  
  // Return as is if can't determine format
  return phoneNumber;
}

// Method with country code detection
String _formatPhoneNumberWithCountryDetection(String phoneNumber, {String? defaultCountryCode}) {
  phoneNumber = _cleanPhoneNumber(phoneNumber);
  
  // If already has country code, return as is
  if (phoneNumber.startsWith('+')) {
    return phoneNumber;
  }
  
  // If starts with 00, replace with +
  if (phoneNumber.startsWith('00')) {
    return '+' + phoneNumber.substring(2);
  }
  
  // Use provided default country code
  if (defaultCountryCode != null) {
    if (phoneNumber.startsWith('0')) {
      return defaultCountryCode + phoneNumber.substring(1);
    } else {
      return defaultCountryCode + phoneNumber;
    }
  }
  
  // Auto-detection logic (same as above)
  return _formatPhoneNumber(phoneNumber);
}

// Method that returns status for UI handling - now works with all country codes
Future<Map<String, dynamic>> callSellerWithStatus() async {
  try {
    String? phoneNumber = _seller?.phone;
    
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // Clean and format phone number
      String originalNumber = phoneNumber;
      phoneNumber = _cleanPhoneNumber(phoneNumber);
      phoneNumber = _formatPhoneNumber(phoneNumber);

      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        return {
          'success': true,
          'message': 'Calling ${_formatPhoneNumberForDisplay(phoneNumber)}',
          'hasNumber': true,
          'phoneNumber': phoneNumber,
          'originalNumber': originalNumber,
          'detectedCountry': _detectCountryFromNumber(phoneNumber),
        };
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } else {
      // Open dialer anyway but return info about no number
      final Uri phoneUri = Uri(scheme: 'tel', path: '');
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
      
      return {
        'success': true,
        'message': 'No phone number available for this seller',
        'hasNumber': false,
        'phoneNumber': null,
      };
    }
  } catch (e) {
    log('Call error: $e');
    return {
      'success': false,
      'message': 'Error: $e',
      'hasNumber': _seller?.phone?.isNotEmpty ?? false,
      'phoneNumber': _seller?.phone,
    };
  }
}

// Method to detect country from phone number
String _detectCountryFromNumber(String phoneNumber) {
  if (!phoneNumber.startsWith('+')) return 'Unknown';
  
  // Common country codes
  Map<String, String> countryCodes = {
    '+1': 'US/Canada',
    '+44': 'UK',
    '+91': 'India',
    '+92': 'Pakistan',
    '+971': 'UAE',
    '+966': 'Saudi Arabia',
    '+974': 'Qatar',
    '+968': 'Oman',
    '+965': 'Kuwait',
    '+973': 'Bahrain',
    '+964': 'Iraq',
    '+962': 'Jordan',
    '+961': 'Lebanon',
    '+963': 'Syria',
    '+20': 'Egypt',
    '+49': 'Germany',
    '+33': 'France',
    '+39': 'Italy',
    '+34': 'Spain',
    '+86': 'China',
    '+81': 'Japan',
    '+82': 'South Korea',
    '+61': 'Australia',
    '+55': 'Brazil',
    '+52': 'Mexico',
    '+7': 'Russia',
  };
  
  // Check for exact matches first
  for (String code in countryCodes.keys) {
    if (phoneNumber.startsWith(code)) {
      return countryCodes[code]!;
    }
  }
  
  // Check for longer country codes (some countries have 3-digit codes)
  if (phoneNumber.length >= 4) {
    String threeDigitCode = phoneNumber.substring(0, 4);
    // Add more 3-digit country codes as needed
    Map<String, String> threeDigitCodes = {
      '+971': 'UAE',
      '+966': 'Saudi Arabia',
      '+974': 'Qatar',
      '+968': 'Oman',
      '+965': 'Kuwait',
      '+973': 'Bahrain',
    };
    
    if (threeDigitCodes.containsKey(threeDigitCode)) {
      return threeDigitCodes[threeDigitCode]!;
    }
  }
  
  return 'International';
}

// Enhanced method to format phone number for display - works with all countries
String _formatPhoneNumberForDisplay(String phone) {
  if (!phone.startsWith('+')) return phone;
  
  // Pakistani numbers
  if (phone.startsWith('+92')) {
    String number = phone.substring(3);
    if (number.length >= 10) {
      return '+92 ${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
    }
  }
  
  // US/Canada numbers
  else if (phone.startsWith('+1')) {
    String number = phone.substring(2);
    if (number.length == 10) {
      return '+1 (${number.substring(0, 3)}) ${number.substring(3, 6)}-${number.substring(6)}';
    }
  }
  
  // UK numbers
  else if (phone.startsWith('+44')) {
    String number = phone.substring(3);
    if (number.length >= 10) {
      return '+44 ${number.substring(0, 4)} ${number.substring(4, 7)} ${number.substring(7)}';
    }
  }
  
  // Indian numbers
  else if (phone.startsWith('+91')) {
    String number = phone.substring(3);
    if (number.length == 10) {
      return '+91 ${number.substring(0, 5)} ${number.substring(5)}';
    }
  }
  
  // UAE numbers
  else if (phone.startsWith('+971')) {
    String number = phone.substring(4);
    if (number.length >= 8) {
      return '+971 ${number.substring(0, 2)} ${number.substring(2, 5)} ${number.substring(5)}';
    }
  }
  
  // Saudi Arabia numbers
  else if (phone.startsWith('+966')) {
    String number = phone.substring(4);
    if (number.length >= 8) {
      return '+966 ${number.substring(0, 2)} ${number.substring(2, 5)} ${number.substring(5)}';
    }
  }
  
  // Generic formatting for other countries
  else {
    // Try to format as: +XX XXX XXX XXXX
    if (phone.length >= 8) {
      String countryCode = '';
      String number = '';
      
      // Extract country code (1-3 digits after +)
      for (int i = 1; i < phone.length && i <= 4; i++) {
        if (phone.substring(1, i + 1).length <= 3) {
          countryCode = phone.substring(0, i + 1);
          number = phone.substring(i + 1);
        }
      }
      
      if (countryCode.isNotEmpty && number.length >= 6) {
        // Format as groups of 3-4 digits
        String formatted = countryCode + ' ';
        for (int i = 0; i < number.length; i += 3) {
          int end = (i + 3 > number.length) ? number.length : i + 3;
          formatted += number.substring(i, end) + ' ';
        }
        return formatted.trim();
      }
    }
  }
  
  return phone; // Return original if no formatting rule matches
}

// Method to validate phone number format
bool _isValidPhoneNumber(String phoneNumber) {
  phoneNumber = _cleanPhoneNumber(phoneNumber);
  
  // Must have at least 7 digits (minimum for a valid phone number)
  if (phoneNumber.length < 7) return false;
  
  // If starts with +, must have country code
  if (phoneNumber.startsWith('+')) {
    return phoneNumber.length >= 10; // Country code + minimum 7 digits
  }
  
  // Local numbers should have reasonable length
  return phoneNumber.length >= 7 && phoneNumber.length <= 15;
}

// Method to get phone number with custom country code
String formatPhoneNumberWithCustomCountry(String phoneNumber, String countryCode) {
  phoneNumber = _cleanPhoneNumber(phoneNumber);
  
  // If already has country code, return as is
  if (phoneNumber.startsWith('+')) {
    return phoneNumber;
  }
  
  // Ensure country code starts with +
  if (!countryCode.startsWith('+')) {
    countryCode = '+' + countryCode;
  }
  
  // Remove leading zero if present
  if (phoneNumber.startsWith('0')) {
    phoneNumber = phoneNumber.substring(1);
  }
  
  return countryCode + phoneNumber;
}

// Updated method to get formatted seller phone number
String? get sellerFormattedPhone {
  if (!sellerHasPhoneNumber) return null;
  
  String phoneNumber = _cleanPhoneNumber(_seller!.phone);
  phoneNumber = _formatPhoneNumber(phoneNumber);
  
  return _formatPhoneNumberForDisplay(phoneNumber);
}

// Method to get detected country for seller's phone
String get sellerPhoneCountry {
  if (!sellerHasPhoneNumber) return 'Unknown';
  
  String phoneNumber = _cleanPhoneNumber(_seller!.phone);
  phoneNumber = _formatPhoneNumber(phoneNumber);
  
  return _detectCountryFromNumber(phoneNumber);
}
// Method to make actual phone call
Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
  
  try {
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
      log('Calling: $phoneNumber');
    } else {
      throw Exception('Could not launch phone dialer');
    }
  } catch (e) {
    log('Error launching phone dialer: $e');
    _setError('Could not open phone dialer');
  }
}

// Method to open dialer with message when no number available
Future<void> _openDialerWithMessage() async {
  final Uri phoneUri = Uri(scheme: 'tel', path: '');
  
  try {
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
      log('Opened dialer - no phone number available');
    } else {
      _setError('Could not open phone dialer');
    }
  } catch (e) {
    log('Phone dialer not available: $e');
    _setError('Phone dialer not available');
  }
}


// Enhanced method with confirmation dialog
Future<void> callSellerWithConfirmation(BuildContext context) async {
  String? phoneNumber = _seller?.phone;
  
  if (phoneNumber != null && phoneNumber.isNotEmpty) {
    // Clean phone number
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Format phone number
    if (!phoneNumber.startsWith('+')) {
      if (phoneNumber.startsWith('0')) {
        phoneNumber = '+92' + phoneNumber.substring(1);
      } else if (phoneNumber.length >= 10) {
        phoneNumber = '+92' + phoneNumber;
      }
    }
    
    // Format phone number for display
    String displayNumber = _formatPhoneNumberForDisplay(phoneNumber);
    
    // Show confirmation dialog
    bool? shouldCall = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Call ${_seller?.getDisplayName() ?? 'Seller'}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone,
                size: 48,
                color: Color(0xFF2D5016),
              ),
              SizedBox(height: 16),
              Text(
                'Do you want to call?',
                style: GoogleFonts.outfit(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                displayNumber,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: Icon(Icons.phone, color: Colors.white),
              label: Text(
                'Call Now',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2D5016),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldCall == true) {
      await _makePhoneCall(phoneNumber);
    }
  } else {
    // Show dialog for no phone number
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'No Phone Number',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_disabled,
                size: 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'This seller hasn\'t provided a phone number.',
                style: GoogleFonts.outfit(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'You can still chat with them!',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.outfit(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                chatWithSeller(context); // Redirect to chat
              },
              icon: Icon(Icons.chat, color: Colors.white),
              label: Text(
                'Chat Instead',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2D5016),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );

    // Still open dialer as requested
    await _openDialerWithMessage();
  }
}


// Method to check if seller has phone number
bool get sellerHasPhoneNumber {
  return _seller?.phone != null && _seller!.phone.isNotEmpty;
}


  // Share product
  Future<void> shareProduct() async {
    if (_product == null) return;

    try {
      final String shareText = '''
${_product!.title}
${_product!.getFormattedPrice()}
${_product!.locationAddress ?? ''}

Check out this amazing product on our marketplace!
''';

      await Share.share(shareText, subject: _product!.title);
    } catch (e) {
      log('Error sharing product: $e');
    }
  }

  // Update current image index for image slider
  void updateImageIndex(int index) {
    _currentImageIndex = index;
    notifyListeners();
  }

  // Add review (if you want to implement reviews)
  Future<void> addReview({
    required double rating,
    required String comment,
    List<String>? imageUrls,
  }) async {
    if (_seller == null) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('Please login to add review');
      return;
    }

    try {
      await _firestore.collection('reviews').add({
        'reviewerId': currentUser.uid,
        'reviewerName': currentUser.displayName ?? 'Anonymous',
        'reviewerImageUrl': currentUser.photoURL ?? '',
        'sellerId': _seller!.id,
        'productId': _product!.id,
        'rating': rating,
        'comment': comment,
        'imageUrls': imageUrls ?? [],
        'isVerifiedPurchase': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update seller's rating
      await _updateSellerRating(_seller!.id);
      
    } catch (e) {
      _setError('Failed to add review: $e');
      log('Error adding review: $e');
    }
  }

  // Update seller rating
  Future<void> _updateSellerRating(String sellerId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        int reviewCount = reviewsSnapshot.docs.length;

        for (var doc in reviewsSnapshot.docs) {
          totalRating += (doc.data()['rating'] ?? 0.0).toDouble();
        }

        double averageRating = totalRating / reviewCount;

        await _firestore.collection('users').doc(sellerId).update({
          'rating': averageRating,
          'reviewCount': reviewCount,
        });
      }
    } catch (e) {
      log('Error updating seller rating: $e');
    }
  }

  
  // Report product
  Future<void> reportProduct({
    required String reason,
    String? description,
  }) async {
    if (_product == null) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('Please login to report');
      return;
    }

    try {
      await _firestore.collection('reports').add({
        'reporterId': currentUser.uid,
        'reporterName': currentUser.displayName ?? 'Anonymous',
        'productId': _product!.id,
        'sellerId': _product!.sellerId,
        'reason': reason,
        'description': description,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // You might want to show a success message here
    } catch (e) {
      _setError('Failed to report product: $e');
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    if (_product != null) {
      await initializeProduct(_product!.id);
    }
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    _sellerSubscription?.cancel();
    _reviewsSubscription?.cancel();
    _favoriteSubscription?.cancel();
    super.dispose();
  }

  Future<void> chatWithSeller(BuildContext context) async {
  if (_seller == null || _product == null) {
    _setError('Seller or product information not available');
    return;
  }

  final currentUser = _auth.currentUser;
  if (currentUser == null) {
    _setError('Please login to chat');
    return;
  }

  if (currentUser.uid == _seller!.id) {
    _setError('You cannot chat with yourself');
    return;
  }

  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Starting chat...',
                style: GoogleFonts.jost(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Get current user info
    final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final currentUserData = currentUserDoc.data() ?? {};
    final currentUserName = currentUserData['companyName'] ?? 
                           currentUserData['name'] ?? 
                           currentUser.displayName ?? 
                           'User';

    // Create or get existing chat using the ChatSetupService method
    final chatId = await _createOrGetChat(
      currentUserId: currentUser.uid,
      currentUserName: currentUserName,
      currentUserImage: currentUserData['profileImage'] ?? currentUser.photoURL ?? '',
      sellerId: _seller!.id,
      sellerName: _seller!.getDisplayName(),
      sellerImage: _seller!.profileImageUrl ?? '',
      productId: _product!.id,
      productTitle: _product!.title,
      productImage: _product!.imageUrls.isNotEmpty ? _product!.imageUrls.first : '',
      productPrice: _product!.price,
    );

    // Close loading dialog
    Navigator.pop(context);

    if (chatId != null) {
      // Navigate to MessagesPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesScreen(chatId: chatId),
        ),
      );
    } else {
      _setError('Failed to create chat');
    }
    
  } catch (e) {
    // Close loading dialog if still open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    _setError('Failed to start chat: $e');
    log('Error starting chat: $e');
  }
}

// Helper method to create or get existing chat
Future<String?> _createOrGetChat({
  required String currentUserId,
  required String currentUserName,
  required String currentUserImage,
  required String sellerId,
  required String sellerName,
  required String sellerImage,
  required String productId,
  required String productTitle,
  required String productImage,
  required double productPrice,
}) async {
  try {
    final chatId = _generateChatId(currentUserId, sellerId);
    
    // Check if chat already exists
    final existingChat = await _firestore.collection('chats').doc(chatId).get();
    
    if (existingChat.exists) {
      // Update the chat with current product info if it's different
      final chatData = existingChat.data() as Map<String, dynamic>;
      if (chatData['productId'] != productId) {
        await _firestore.collection('chats').doc(chatId).update({
          'productId': productId,
          'productTitle': productTitle,
          'productImage': productImage,
          'productPrice': productPrice,
        });
      }
      return chatId;
    }

    // Create new chat
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [currentUserId, sellerId],
      'participantNames': {
        currentUserId: currentUserName,
        sellerId: sellerName,
      },
      'participantImages': {
        currentUserId: currentUserImage,
        sellerId: sellerImage,
      },
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'productPrice': productPrice,
      'unreadCount': {
        currentUserId: 0,
        sellerId: 0,
      },
      'isTyping': {
        currentUserId: false,
        sellerId: false,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'chatType': 'buying', // Current user is buying from seller
    });

    // Send an initial system message (optional)
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'chatId': chatId,
      'senderId': 'system',
      'senderName': 'System',
      'message': 'Chat started about: $productTitle',
      'type': 'system',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'status': 'sent',
    });

    return chatId;
  } catch (e) {
    log('Error creating chat: $e');
    return null;
  }
}

// Generate consistent chat ID
String _generateChatId(String userId1, String userId2) {
  List<String> ids = [userId1, userId2];
  ids.sort();
  return '${ids[0]}_${ids[1]}';
}

}