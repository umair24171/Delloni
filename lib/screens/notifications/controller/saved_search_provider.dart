// models/saved_search_model.dart
import 'dart:async';
import 'dart:developer' as dev show log;
import 'dart:math';
import 'dart:math' as math;

import 'package:arabicmarketplace/controller/notification_provider.dart';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:arabicmarketplace/screens/search_page/controller/search_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SavedSearchModel {
  final String id;
  final String userId;
  final String name;
  final String query;
  final String? categoryId;
  final String? categoryName;
  final double? minPrice;
  final double? maxPrice;
  final String? condition;
  final String? adType;
  final String? cityId;
  final String? cityName;
  final String? districtId;
  final String? districtName;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final bool isActive;
  final int matchCount;
  final DateTime createdAt;
  final DateTime? lastNotificationSent;

  SavedSearchModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.query,
    this.categoryId,
    this.categoryName,
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.adType,
    this.cityId,
    this.cityName,
    this.districtId,
    this.districtName,
    this.latitude,
    this.longitude,
    this.radiusKm,
    required this.isActive,
    required this.matchCount,
    required this.createdAt,
    this.lastNotificationSent,
  });

  // Empty constructor for error handling
  SavedSearchModel.empty()
      : id = '',
        userId = '',
        name = '',
        query = '',
        categoryId = null,
        categoryName = null,
        minPrice = null,
        maxPrice = null,
        condition = null,
        adType = null,
        cityId = null,
        cityName = null,
        districtId = null,
        districtName = null,
        latitude = null,
        longitude = null,
        radiusKm = null,
        isActive = false,
        matchCount = 0,
        createdAt = DateTime.now(),
        lastNotificationSent = null;

  // Create from Firestore document
  factory SavedSearchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SavedSearchModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      query: data['query'] ?? '',
      categoryId: data['categoryId'],
      categoryName: data['categoryName'],
      minPrice: (data['minPrice'] as num?)?.toDouble(),
      maxPrice: (data['maxPrice'] as num?)?.toDouble(),
      condition: data['condition'],
      adType: data['adType'],
      cityId: data['cityId'],
      cityName: data['cityName'],
      districtId: data['districtId'],
      districtName: data['districtName'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      radiusKm: (data['radiusKm'] as num?)?.toDouble(),
      isActive: data['isActive'] ?? true,
      matchCount: data['matchCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastNotificationSent: (data['lastNotificationSent'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'query': query,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'condition': condition,
      'adType': adType,
      'cityId': cityId,
      'cityName': cityName,
      'districtId': districtId,
      'districtName': districtName,
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'isActive': isActive,
      'matchCount': matchCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastNotificationSent': lastNotificationSent != null 
          ? Timestamp.fromDate(lastNotificationSent!) 
          : null,
    };
  }

  // Copy with method for updates
  SavedSearchModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? query,
    String? categoryId,
    String? categoryName,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? adType,
    String? cityId,
    String? cityName,
    String? districtId,
    String? districtName,
    double? latitude,
    double? longitude,
    double? radiusKm,
    bool? isActive,
    int? matchCount,
    DateTime? createdAt,
    DateTime? lastNotificationSent,
  }) {
    return SavedSearchModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      condition: condition ?? this.condition,
      adType: adType ?? this.adType,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      isActive: isActive ?? this.isActive,
      matchCount: matchCount ?? this.matchCount,
      createdAt: createdAt ?? this.createdAt,
      lastNotificationSent: lastNotificationSent ?? this.lastNotificationSent,
    );
  }

  // Get display text for UI
  String getDisplayText() {
    List<String> parts = [];
    
    if (query.isNotEmpty) {
      parts.add('"$query"');
    }
    
    if (categoryName != null && categoryName!.isNotEmpty) {
      parts.add('in $categoryName');
    }
    
    if (minPrice != null || maxPrice != null) {
      if (minPrice != null && maxPrice != null) {
        parts.add('\$${minPrice!.toStringAsFixed(0)} - \$${maxPrice!.toStringAsFixed(0)}');
      } else if (minPrice != null) {
        parts.add('${"above".tr()} \$${minPrice!.toStringAsFixed(0)}');
      } else if (maxPrice != null) {
        parts.add('${"below".tr()} \$${maxPrice!.toStringAsFixed(0)}');
      }
    }
    
    if (cityName != null && cityName!.isNotEmpty) {
      String location = districtName != null && districtName!.isNotEmpty
          ? '$districtName, $cityName'
          : cityName!;
      parts.add('in $location');
    }
    
    if (adType != null && adType != 'All' && adType!.isNotEmpty) {
      parts.add('$adType ads');
    }
    
    if (radiusKm != null && radiusKm! > 0) {
      parts.add('${"within".tr()} ${radiusKm!.toStringAsFixed(0)}km');
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : 'All items'.tr();
  }

  // Get search summary for notifications
  String getSearchSummary() {
    List<String> parts = [];
    
    if (query.isNotEmpty) {
      parts.add(query);
    }
    
    if (categoryName != null && categoryName!.isNotEmpty) {
      parts.add(categoryName!);
    }
    
    if (cityName != null && cityName!.isNotEmpty) {
      parts.add(cityName!);
    }
    
    return parts.isNotEmpty ? parts.join(' in ') : 'Items';
  }

  // Check if search has location filters
  bool get hasLocationFilters {
    return (cityId != null && cityId!.isNotEmpty) ||
           (districtId != null && districtId!.isNotEmpty) ||
           (latitude != null && longitude != null && radiusKm != null);
  }

  // Check if search has price filters
  bool get hasPriceFilters {
    return minPrice != null || maxPrice != null;
  }

  // Check if search has category filters
  bool get hasCategoryFilters {
    return categoryId != null && categoryId!.isNotEmpty;
  }

  // Check if search has any filters
  bool get hasFilters {
    return query.isNotEmpty ||
           hasCategoryFilters ||
           hasPriceFilters ||
           hasLocationFilters ||
           (adType != null && adType != 'All');
  }

  // Get time since creation
  String getTimeSinceCreation() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Get last notification info
  String? getLastNotificationInfo() {
    if (lastNotificationSent == null) return null;
    
    final now = DateTime.now();
    final difference = now.difference(lastNotificationSent!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Validate search criteria
  bool isValid() {
    return userId.isNotEmpty &&
           name.trim().isNotEmpty &&
           name.trim().length >= 3;
  }

  @override
  String toString() {
    return 'SavedSearchModel(id: $id, name: $name, query: $query, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedSearchModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class SavedSearchProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<SavedSearchModel> _savedSearches = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<SavedSearchModel> get savedSearches => _savedSearches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SavedSearchProvider() {
    _initializeListener();
  }

  void _initializeListener() {
    final user = _auth.currentUser;
    if (user != null) {
      _setupListener(user.uid);
    }
    
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _setupListener(user.uid);
      } else {
        _clearSearches();
      }
    });
  }

  void _setupListener(String userId) {
    _subscription?.cancel();
    _setLoading(true);
    
    _subscription = _firestore
        .collection('savedSearches')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          _savedSearches = snapshot.docs
              .map((doc) => SavedSearchModel.fromFirestore(doc))
              .toList();
          _setError(null);
          _setLoading(false);
        } catch (e) {
          dev.log('Error parsing saved searches: $e');
          _setError('Failed to load saved searches');
          _setLoading(false);
        }
      },
      onError: (error) {
        dev.log('Error in saved search listener: $error');
        _setError('Connection error. Please check your internet connection.');
        _setLoading(false);
      },
    );
  }

  void _clearSearches() {
    _savedSearches.clear();
    _subscription?.cancel();
    _setError(null);
    _setLoading(false);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Enhanced save current search with validation
  Future<bool> saveCurrentSearch({
    required String name,
    required String query,
    required SearchFilters filters,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _setError('Please login to save searches');
        return false;
      }

      // Validate input
      if (name.trim().isEmpty) {
        _setError('Search name cannot be empty');
        return false;
      }

      if (name.trim().length < 3) {
        _setError('Search name must be at least 3 characters');
        return false;
      }

      // Check for duplicate names
      final existingSearch = _savedSearches.firstWhere(
        (search) => search.name.toLowerCase() == name.trim().toLowerCase(),
        orElse: () => SavedSearchModel.empty(),
      );

      if (existingSearch.id.isNotEmpty) {
        _setError('A search with this name already exists');
        return false;
      }

      // Check limits (max 10 saved searches per user)
      if (_savedSearches.length >= 10) {
        _setError('Maximum 10 saved searches allowed. Please delete some old searches first.');
        return false;
      }

      final savedSearch = SavedSearchModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        name: name.trim(),
        query: query.trim(),
        categoryId: filters.selectedCategory,
        categoryName: filters.selectedCategory,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        condition: null,
        adType: filters.adType,
        cityId: filters.cityId,
        cityName: filters.cityName,
        districtId: filters.districtId,
        districtName: filters.districtName,
        latitude: filters.latitude,
        longitude: filters.longitude,
        radiusKm: filters.radiusKm,
        isActive: true,
        matchCount: 0,
        createdAt: DateTime.now(),
        lastNotificationSent: null,
      );

      final docRef = await _firestore.collection('savedSearches').add(savedSearch.toJson());
      
      // Update the local model with the generated ID
      final updatedSearch = savedSearch.copyWith(id: docRef.id);
      
      dev.log('Successfully saved search: ${updatedSearch.name}');
      _setError(null);
      return true;
      
    } catch (e) {
      dev.log('Failed to save search: $e');
      if (e.toString().contains('permission-denied')) {
        _setError('Permission denied. Please check your account settings.');
      } else if (e.toString().contains('network')) {
        _setError('Network error. Please check your internet connection.');
      } else {
        _setError('Failed to save search. Please try again.');
      }
      return false;
    }
  }

  // Enhanced delete with confirmation
  Future<bool> deleteSavedSearch(String searchId) async {
    try {
      if (searchId.isEmpty) {
        _setError('Invalid search ID');
        return false;
      }

      await _firestore.collection('savedSearches').doc(searchId).delete();
      
      dev.log('Successfully deleted search: $searchId');
      _setError(null);
      return true;
      
    } catch (e) {
      dev.log('Failed to delete search: $e');
      if (e.toString().contains('permission-denied')) {
        _setError('Permission denied. You can only delete your own searches.');
      } else if (e.toString().contains('not-found')) {
        _setError('Search not found. It may have already been deleted.');
      } else {
        _setError('Failed to delete search. Please try again.');
      }
      return false;
    }
  }

  // Enhanced update with validation
  Future<bool> updateSavedSearch(String searchId, {
    String? name,
    bool? isActive,
  }) async {
    try {
      if (searchId.isEmpty) {
        _setError('Invalid search ID');
        return false;
      }

      Map<String, dynamic> updates = {};
      
      if (name != null) {
        final trimmedName = name.trim();
        if (trimmedName.isEmpty) {
          _setError('Search name cannot be empty');
          return false;
        }
        if (trimmedName.length < 3) {
          _setError('Search name must be at least 3 characters');
          return false;
        }
        
        // Check for duplicate names (excluding current search)
        final existingSearch = _savedSearches.firstWhere(
          (search) => search.id != searchId && 
                      search.name.toLowerCase() == trimmedName.toLowerCase(),
          orElse: () => SavedSearchModel.empty(),
        );

        if (existingSearch.id.isNotEmpty) {
          _setError('A search with this name already exists');
          return false;
        }
        
        updates['name'] = trimmedName;
      }
      
      if (isActive != null) {
        updates['isActive'] = isActive;
        updates['updatedAt'] = FieldValue.serverTimestamp();
      }
      
      if (updates.isNotEmpty) {
        await _firestore.collection('savedSearches').doc(searchId).update(updates);
        dev.log('Successfully updated search: $searchId');
      }
      
      _setError(null);
      return true;
      
    } catch (e) {
      dev.log('Failed to update search: $e');
      if (e.toString().contains('permission-denied')) {
        _setError('Permission denied. You can only edit your own searches.');
      } else if (e.toString().contains('not-found')) {
        _setError('Search not found. It may have been deleted.');
      } else {
        _setError('Failed to update search. Please try again.');
      }
      return false;
    }
  }

  // Get saved search by ID with error handling
  SavedSearchModel? getSavedSearchById(String searchId) {
    try {
      return _savedSearches.firstWhere((search) => search.id == searchId);
    } catch (e) {
      dev.log('Saved search not found: $searchId');
      return null;
    }
  }

  // Enhanced execute saved search with better filtering
  Future<List<ProductModel>> executeSavedSearch(SavedSearchModel savedSearch) async {
    try {
      dev.log('Executing saved search: ${savedSearch.name}');
      
      Query query = _firestore
          .collection('items')
          .where('status', isEqualTo: 'active');

      // Apply filters from saved search
      if (savedSearch.categoryId != null && savedSearch.categoryId!.isNotEmpty) {
        query = query.where('category', isEqualTo: savedSearch.categoryId);
      }

      if (savedSearch.minPrice != null && savedSearch.minPrice! > 0) {
        query = query.where('price', isGreaterThanOrEqualTo: savedSearch.minPrice);
      }

      if (savedSearch.maxPrice != null && savedSearch.maxPrice! > 0) {
        query = query.where('price', isLessThanOrEqualTo: savedSearch.maxPrice);
      }

      if (savedSearch.adType != null && savedSearch.adType != 'All' && savedSearch.adType!.isNotEmpty) {
        final sellerType = savedSearch.adType == 'Individual' ? 'individual' : 'company';
        query = query.where('sellerType', isEqualTo: sellerType);
      }

      if (savedSearch.cityId != null && savedSearch.cityId!.isNotEmpty) {
        query = query.where('cityId', isEqualTo: savedSearch.cityId);
      }

      if (savedSearch.districtId != null && savedSearch.districtId!.isNotEmpty) {
        query = query.where('districtId', isEqualTo: savedSearch.districtId);
      }

      query = query.orderBy('createdAt', descending: true).limit(50);

      final snapshot = await query.get();
      List<ProductModel> products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();

      // Apply text search if query exists
      if (savedSearch.query.isNotEmpty) {
        final searchTerms = savedSearch.query.toLowerCase().split(' ')
            .where((term) => term.isNotEmpty)
            .toList();
            
        if (searchTerms.isNotEmpty) {
          products = products.where((product) {
            final searchableText = '''
              ${product.title ?? ''} 
              ${product.description ?? ''} 
              ${product.brand ?? ''} 
              ${product.category ?? ''} 
              ${product.color ?? ''}
            '''.toLowerCase().replaceAll('\n', ' ');
            
            return searchTerms.any((term) => searchableText.contains(term));
          }).toList();
        }
      }

      // Apply location-based filtering if coordinates are available
      if (savedSearch.latitude != null && 
          savedSearch.longitude != null && 
          savedSearch.radiusKm != null && 
          savedSearch.radiusKm! > 0) {
        products = products.where((product) {
          if (product.latitude == null || product.longitude == null) {
            return false;
          }
          
          final distance = _calculateDistance(
            savedSearch.latitude!,
            savedSearch.longitude!,
            product.latitude!,
            product.longitude!,
          );
          
          return distance <= savedSearch.radiusKm!;
        }).toList();
      }

      dev.log('Found ${products.length} products for saved search: ${savedSearch.name}');
      return products.take(20).toList(); // Limit final results
      
    } catch (e) {
      dev.log('Failed to execute search: $e');
      if (e.toString().contains('permission-denied')) {
        _setError('Permission denied. Please check your account settings.');
      } else if (e.toString().contains('network')) {
        _setError('Network error. Please check your internet connection.');
      } else {
        _setError('Failed to execute search. Please try again.');
      }
      return [];
    }
  }

  // Calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Get search statistics
  Map<String, int> getSearchStatistics() {
    return {
      'total': _savedSearches.length,
      'active': _savedSearches.where((s) => s.isActive).length,
      'inactive': _savedSearches.where((s) => !s.isActive).length,
      'totalMatches': _savedSearches.fold(0, (sum, s) => sum + s.matchCount),
    };
  }

  // Bulk operations
  Future<bool> toggleAllSearches(bool isActive) async {
    try {
      final batch = _firestore.batch();
      
      for (final search in _savedSearches) {
        final docRef = _firestore.collection('savedSearches').doc(search.id);
        batch.update(docRef, {
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      dev.log('Successfully toggled all searches to: $isActive');
      return true;
      
    } catch (e) {
      dev.log('Failed to toggle all searches: $e');
      _setError('Failed to update searches. Please try again.');
      return false;
    }
  }

  // Clean up old inactive searches
  Future<bool> cleanupOldSearches() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final oldInactiveSearches = _savedSearches
          .where((search) => 
              !search.isActive && 
              search.createdAt.isBefore(thirtyDaysAgo))
          .toList();

      if (oldInactiveSearches.isEmpty) {
        return true;
      }

      final batch = _firestore.batch();
      
      for (final search in oldInactiveSearches) {
        final docRef = _firestore.collection('savedSearches').doc(search.id);
        batch.delete(docRef);
      }
      
      await batch.commit();
      dev.log('Cleaned up ${oldInactiveSearches.length} old searches');
      return true;
      
    } catch (e) {
      dev.log('Failed to cleanup old searches: $e');
      _setError('Failed to cleanup old searches.');
      return false;
    }
  }

  // Force refresh saved searches
  Future<void> loadSavedSearches() async {
    final user = _auth.currentUser;
    if (user != null) {
      _setLoading(true);
      _setError(null);
      _setupListener(user.uid);
    } else {
      _setError('User not authenticated');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// services/saved_search_service.dart
class SavedSearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if new item matches any saved searches
  static Future<void> checkSavedSearchesForNewItem(Map<String, dynamic> newItem) async {
    try {
      // Get all active saved searches
      final snapshot = await _firestore
          .collection('savedSearches')
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        final savedSearch = SavedSearchModel.fromFirestore(doc);
        
        // Check if item matches this saved search
        if (await _itemMatchesSavedSearch(newItem, savedSearch)) {
          // Send notification
          await _sendSavedSearchNotification(savedSearch, newItem);
          
          // Update match count
          await _updateMatchCount(savedSearch.id);
        }
      }
    } catch (e) {
      print('Error checking saved searches: $e');
    }
  }

  // Check if item matches saved search criteria
  static Future<bool> _itemMatchesSavedSearch(
    Map<String, dynamic> item, 
    SavedSearchModel savedSearch
  ) async {
    try {
      // Text search match
      if (savedSearch.query.isNotEmpty) {
        final searchTerms = savedSearch.query.toLowerCase().split(' ');
        final searchableText = '${item['itemTitle'] ?? ''} ${item['description'] ?? ''} ${item['brand'] ?? ''} ${item['categoryName'] ?? ''} ${item['color'] ?? ''}'.toLowerCase();
        
        bool hasTextMatch = searchTerms.any((term) => searchableText.contains(term));
        if (!hasTextMatch) return false;
      }

      // Category match
      if (savedSearch.categoryId != null) {
        if (item['category'] != savedSearch.categoryId) return false;
      }

      // Price range match
      final itemPrice = (item['price'] ?? 0).toDouble();
      if (savedSearch.minPrice != null && itemPrice < savedSearch.minPrice!) return false;
      if (savedSearch.maxPrice != null && itemPrice > savedSearch.maxPrice!) return false;

      // Ad type match
      if (savedSearch.adType != null && savedSearch.adType != 'All') {
        final expectedSellerType = savedSearch.adType == 'Individual' ? 'individual' : 'company';
        if (item['sellerType'] != expectedSellerType) return false;
      }

      // Location match
      if (savedSearch.cityId != null) {
        if (item['cityId'] != savedSearch.cityId) return false;
      }

      if (savedSearch.districtId != null) {
        if (item['districtId'] != savedSearch.districtId) return false;
      }

      // Radius match (if coordinates are available)
      if (savedSearch.latitude != null && savedSearch.longitude != null && 
          savedSearch.radiusKm != null && item['latitude'] != null && item['longitude'] != null) {
        final distance = _calculateDistance(
          savedSearch.latitude!,
          savedSearch.longitude!,
          (item['latitude'] as num).toDouble(),
          (item['longitude'] as num).toDouble(),
        );
        if (distance > savedSearch.radiusKm!) return false;
      }

      return true;
    } catch (e) {
      print('Error matching item to saved search: $e');
      return false;
    }
  }

  // Send notification for matching item
  static Future<void> _sendSavedSearchNotification(
    SavedSearchModel savedSearch,
    Map<String, dynamic> item
  ) async {
    try {
      // Check if enough time has passed since last notification (prevent spam)
      if (savedSearch.lastNotificationSent != null) {
        final timeSinceLastNotification = DateTime.now().difference(savedSearch.lastNotificationSent!);
        if (timeSinceLastNotification.inHours < 6) {
          return; // Don't send notification if less than 6 hours since last one
        }
      }

      // Get location string
      String location = item['cityName'] ?? item['locationAddress'] ?? 'Unknown location';
      if (item['districtName'] != null) {
        location = '${item['districtName']}, $location';
      }

      // Send notification using your existing notification service
      await SimpleNotificationService.sendSavedSearchNotification(
        userId: savedSearch.userId,
        itemTitle: item['itemTitle'] ?? 'New Item',
        itemId: item['id'] ?? item['itemId'] ?? '',
        savedSearchName: savedSearch.name,
        location: location,
      );

      // Update last notification sent timestamp
      await _firestore.collection('savedSearches').doc(savedSearch.id).update({
        'lastNotificationSent': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('Error sending saved search notification: $e');
    }
  }

  // Update match count
  static Future<void> _updateMatchCount(String savedSearchId) async {
    try {
      await _firestore.collection('savedSearches').doc(savedSearchId).update({
        'matchCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error updating match count: $e');
    }
  }

  // Calculate distance between two points
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
}