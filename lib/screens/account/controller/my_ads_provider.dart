// providers/my_ads_provider.dart
import 'dart:async';
import 'dart:developer';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class MyAdsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  bool _isLoading = true;
  String? _error;
  List<ProductModel> _allAds = [];
  List<ProductModel> _activeAds = [];
  List<ProductModel> _soldAds = [];
  List<ProductModel> _inactiveAds = [];
  int _selectedTabIndex = 0;

  // Streams
  StreamSubscription? _adsSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProductModel> get allAds => _allAds;
  List<ProductModel> get activeAds => _activeAds;
  List<ProductModel> get soldAds => _soldAds;
  List<ProductModel> get inactiveAds => _inactiveAds;
  int get selectedTabIndex => _selectedTabIndex;

  List<ProductModel> get currentAds {
    switch (_selectedTabIndex) {
      case 0:
        return _allAds;
      case 1:
        return _activeAds;
      case 2:
        return _soldAds;
      case 3:
        return _inactiveAds;
      default:
        return _allAds;
    }
  }

  MyAdsProvider() {
    _initializeAds();
  }

  Future<void> _initializeAds() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('User not authenticated');
      return;
    }

    try {
      _setLoading(true);
      _setupAdsListener(currentUser.uid);
    } catch (e) {
      _setError('Failed to initialize ads: $e');
      log('MyAdsProvider initialization error: $e');
    }
  }

  // COMPLETE DELETION: Delete product and permanently remove all related chats
Future<bool> deleteAdWithChats(String productId) async {
  try {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    log('🗑️ Starting complete deletion of product: $productId');

    // 1. Find all chats related to this product
    final relatedChatsQuery = await _firestore
        .collection('chats')
        .where('productId', isEqualTo: productId)
        .get();

    // 2. Delete all related chats and their messages
    for (var chatDoc in relatedChatsQuery.docs) {
      await _deleteEntireChat(chatDoc.id);
    }

    // 3. Delete the product itself
    await _firestore.collection('items').doc(productId).delete();

    // 4. Update local state
    _allAds.removeWhere((ad) => ad.id == productId);
    _activeAds.removeWhere((ad) => ad.id == productId);
    _soldAds.removeWhere((ad) => ad.id == productId);
    _inactiveAds.removeWhere((ad) => ad.id == productId);

    notifyListeners();
    return true;

  } catch (e) {
    log('❌ Error in complete deletion: $e');
    return false;
  }
}

// Helper method to completely delete a chat and all its messages
Future<void> _deleteEntireChat(String chatId) async {
  try {
    // Delete all messages in batches
    bool hasMoreMessages = true;
    while (hasMoreMessages) {
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .limit(100)
          .get();

      if (messagesQuery.docs.isEmpty) {
        hasMoreMessages = false;
        break;
      }

      final batch = _firestore.batch();
      for (var messageDoc in messagesQuery.docs) {
        batch.delete(messageDoc.reference);
      }
      await batch.commit();
    }

    // Delete the chat document itself
    await _firestore.collection('chats').doc(chatId).delete();

  } catch (e) {
    log('❌ Error deleting chat $chatId: $e');
    throw e;
  }
}
// Get count of related chats
Future<int> getRelatedChatsCount(String productId) async {
  try {
    final chatsQuery = await _firestore
        .collection('chats')
        .where('productId', isEqualTo: productId)
        .get();
    return chatsQuery.docs.length;
  } catch (e) {
    return 0;
  }
}

// Get detailed info about what will be deleted
Future<Map<String, dynamic>> getDeletionInfo(String productId) async {
  try {
    final chatsQuery = await _firestore
        .collection('chats')
        .where('productId', isEqualTo: productId)
        .get();

    int totalMessages = 0;
    for (var chatDoc in chatsQuery.docs) {
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatDoc.id)
          .collection('messages')
          .get();
      totalMessages += messagesQuery.docs.length;
    }

    return {
      'chatCount': chatsQuery.docs.length,
      'messageCount': totalMessages,
    };
  } catch (e) {
    return {'chatCount': 0, 'messageCount': 0};
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

  // Setup real-time ads listener
  void _setupAdsListener(String userId) {
    _adsSubscription = _firestore
        .collection('items')
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _allAds = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();

      _categorizeAds();
      _setLoading(false);
    }, onError: (e) {
      _setError('Error loading ads: $e');
      log('Ads stream error: $e');
    });
  }

  // Categorize ads by status
  void _categorizeAds() {
    _activeAds = _allAds.where((ad) => ad.status == 'active').toList();
    _soldAds = _allAds.where((ad) => ad.status == 'sold').toList();
    _inactiveAds = _allAds.where((ad) => ad.status == 'inactive').toList();
    notifyListeners();
  }

  // Change selected tab
  void changeTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  // Update ad status
  Future<bool> updateAdStatus(String adId, String newStatus) async {
    try {
      await _firestore.collection('items').doc(adId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Failed to update ad status: $e');
      log('Error updating ad status: $e');
      return false;
    }
  }

  // Mark ad as sold
  Future<bool> markAsSold(String adId) async {
    return await updateAdStatus(adId, 'sold');
  }

  // Mark ad as active
  Future<bool> markAsActive(String adId) async {
    return await updateAdStatus(adId, 'active');
  }

  // Mark ad as inactive
  Future<bool> markAsInactive(String adId) async {
    return await updateAdStatus(adId, 'inactive');
  }

  // Delete ad
 Future<bool> deleteAd(String productId) async {
  return await deleteAdWithChats(productId);
}

  // Promote ad (mark as featured)
  Future<bool> promoteAd(String adId) async {
    try {
      await _firestore.collection('items').doc(adId).update({
        'isFeatured': true,
        'isPromoted': true,
        'promotedUntil': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Failed to promote ad: $e');
      log('Error promoting ad: $e');
      return false;
    }
  }

  // NEW: Remove promotion from ad
  Future<bool> removePromotion(String adId) async {
    try {
      await _firestore.collection('items').doc(adId).update({
        'isFeatured': false,
        'isPromoted': false,
        'promotedUntil': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Failed to remove promotion: $e');
      log('Error removing promotion: $e');
      return false;
    }
  }

  // NEW: Update ad basic information (title and description)
  Future<bool> updateAdBasicInfo(String adId, String title, String description) async {
    try {
      if (title.trim().isEmpty || description.trim().isEmpty) {
        _setError('Title and description cannot be empty');
        return false;
      }

      await _firestore.collection('items').doc(adId).update({
        'title': title.trim(),
        'description': description.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Failed to update ad information: $e');
      log('Error updating ad basic info: $e');
      return false;
    }
  }

  // NEW: Update ad price and negotiation settings
  Future<bool> updateAdPrice(String adId, double price, bool allowNegotiation) async {
    try {
      if (price <= 0) {
        _setError('Price must be greater than 0');
        return false;
      }

      await _firestore.collection('items').doc(adId).update({
        'price': price,
        'allowPriceNegotiation': allowNegotiation,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Failed to update price: $e');
      log('Error updating ad price: $e');
      return false;
    }
  }

  // NEW: Update ad category
  Future<bool> updateAdCategory(String adId, String categoryId, String categoryName) async {
    try {
      await _firestore.collection('items').doc(adId).update({
        'category': categoryId,
        'categoryName': categoryName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Failed to update category: $e');
      log('Error updating ad category: $e');
      return false;
    }
  }

  // NEW: Update ad condition
  Future<bool> updateAdCondition(String adId, String condition) async {
    try {
      await _firestore.collection('items').doc(adId).update({
        'condition': condition,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Failed to update condition: $e');
      log('Error updating ad condition: $e');
      return false;
    }
  }

  // NEW: Update ad shipping options
  Future<bool> updateAdShipping(String adId, String shippingOption) async {
    try {
      await _firestore.collection('items').doc(adId).update({
        'shippingOption': shippingOption,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Failed to update shipping option: $e');
      log('Error updating ad shipping: $e');
      return false;
    }
  }

  // NEW: Update ad images
  Future<bool> updateAdImages(String adId, List<String> imageUrls) async {
    try {
      if (imageUrls.isEmpty) {
        _setError('At least one image is required');
        return false;
      }

      await _firestore.collection('items').doc(adId).update({
        'imageUrls': imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Failed to update images: $e');
      log('Error updating ad images: $e');
      return false;
    }
  }

  // NEW: Boost ad (different from promote - could be shorter duration)
  Future<bool> boostAd(String adId, int durationDays) async {
    try {
      await _firestore.collection('items').doc(adId).update({
        'isBoosted': true,
        'boostedUntil': Timestamp.fromDate(DateTime.now().add(Duration(days: durationDays))),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Failed to boost ad: $e');
      log('Error boosting ad: $e');
      return false;
    }
  }

  // NEW: Get single ad details
  Future<ProductModel?> getAdDetails(String adId) async {
    try {
      final doc = await _firestore.collection('items').doc(adId).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _setError('Failed to get ad details: $e');
      log('Error getting ad details: $e');
      return null;
    }
  }

  // Get ad statistics
  Map<String, int> getAdStats() {
    return {
      'total': _allAds.length,
      'active': _activeAds.length,
      'sold': _soldAds.length,
      'inactive': _inactiveAds.length,
      'totalViews': _allAds.fold(0, (sum, ad) => sum + ad.viewCount),
      'totalFavorites': _allAds.fold(0, (sum, ad) => sum + ad.favoriteCount),
    };
  }

  // Refresh ads
  Future<void> refreshAds() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _setupAdsListener(currentUser.uid);
    }
  }

  // Search ads
  List<ProductModel> searchAds(String query) {
    if (query.isEmpty) return currentAds;

    return currentAds.where((ad) {
      final title = ad.title.toLowerCase();
      final description = ad.description.toLowerCase();
      final category = ad.category.toLowerCase();
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) ||
             description.contains(searchQuery) ||
             category.contains(searchQuery);
    }).toList();
  }

  // Get ads by date range
  List<ProductModel> getAdsByDateRange(DateTime startDate, DateTime endDate) {
    return currentAds.where((ad) {
      return ad.createdAt.isAfter(startDate) && ad.createdAt.isBefore(endDate);
    }).toList();
  }

  // Get top performing ads
  List<ProductModel> getTopPerformingAds({int limit = 5}) {
    final sortedAds = List<ProductModel>.from(_allAds);
    sortedAds.sort((a, b) => (b.viewCount + b.favoriteCount).compareTo(a.viewCount + a.favoriteCount));
    return sortedAds.take(limit).toList();
  }

  // NEW: Get promoted ads
  List<ProductModel> getPromotedAds() {
    return _allAds.where((ad) => ad.isPromoted).toList();
  }

  // NEW: Get ads by status
  List<ProductModel> getAdsByStatus(String status) {
    return _allAds.where((ad) => ad.status == status).toList();
  }

  // NEW: Get ads expiring soon (promoted ads near expiration)
  List<ProductModel> getAdsExpiringSoon({int daysThreshold = 7}) {
    final threshold = DateTime.now().add(Duration(days: daysThreshold));
    return _allAds.where((ad) {
      if (ad.promotedUntil != null) {
        return ad.promotedUntil!.isBefore(threshold);
      }
      return false;
    }).toList();
  }

  @override
  void dispose() {
    _adsSubscription?.cancel();
    super.dispose();
  }
}