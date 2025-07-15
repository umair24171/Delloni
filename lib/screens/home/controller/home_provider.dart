// providers/home_provider.dart
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // State variables
  bool _isLoading = true;
  String? _error;
  
  // Data lists
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _featuredProducts = [];
  List<Map<String, dynamic>> _personalizedProducts = [];
  List<Map<String, dynamic>> _mostViewedProducts = [];
  List<Map<String, dynamic>> _mobilePhones = [];
  List<Map<String, dynamic>> _computers = [];
  List<Map<String, dynamic>> _computerAccessories = [];
  List<Map<String, dynamic>> _adBanners = [];
  List<Map<String, dynamic>> _allProducts = [];
  
  // User location for personalization
  double? _userLatitude;
  double? _userLongitude;
  String? _userLocationAddress;
  
  // Streams for real-time updates
  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _productsSubscription;
  StreamSubscription? _bannersSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get featuredProducts => _featuredProducts;
  List<Map<String, dynamic>> get personalizedProducts => _personalizedProducts;
  List<Map<String, dynamic>> get mostViewedProducts => _mostViewedProducts;
  List<Map<String, dynamic>> get mobilePhones => _mobilePhones;
  List<Map<String, dynamic>> get computers => _computers;
  List<Map<String, dynamic>> get computerAccessories => _computerAccessories;
  List<Map<String, dynamic>> get adBanners => _adBanners;
  List<Map<String, dynamic>> get allProducts => _allProducts;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  String? get userLocationAddress => _userLocationAddress;

  HomeProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _setLoading(true);
      await _getUserLocation();
      _setupRealTimeListeners();
      await _loadInitialData();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize data: $e');
      log('HomeProvider initialization error: $e');
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

  // Get user location for personalized content
  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      _userLatitude = position.latitude;
      _userLongitude = position.longitude;

      // Reverse geocode to get city name
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(_userLatitude!, _userLongitude!);
        if (placemarks.isNotEmpty) {
          _userLocationAddress = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? placemarks.first.administrativeArea ?? 'Unknown location';
        } else {
          _userLocationAddress = 'Unknown location';
        }
      } catch (e) {
        _userLocationAddress = 'Unknown location';
      }
      
      log('User location obtained: $_userLatitude, $_userLongitude, address: $_userLocationAddress');
      notifyListeners();
    } catch (e) {
      log('Error getting user location: $e');
    }
  }

  // Setup real-time listeners
  void _setupRealTimeListeners() {
    // Categories listener - Get parent categories only
    _categoriesSubscription = _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .where('level', isEqualTo: 0) // Parent categories only
        .snapshots()
        .listen(_onCategoriesChanged, onError: (e) => log('Categories stream error: $e'));

    // Products listener
    _productsSubscription = _firestore
        .collection('items')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen(_onProductsChanged, onError: (e) => log('Products stream error: $e'));

    // Ad banners listener
    _bannersSubscription = _firestore
        .collection('adBanners')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen(_onBannersChanged, onError: (e) => log('Banners stream error: $e'));
  }

  void _onCategoriesChanged(QuerySnapshot snapshot) {
    try {
      _categories = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by order and priority
      _categories.sort((a, b) {
        final orderA = a['order'] ?? 0;
        final orderB = b['order'] ?? 0;
        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }
        final priorityA = a['priority'] ?? 0;
        final priorityB = b['priority'] ?? 0;
        return priorityB.compareTo(priorityA);
      });
      
      log('Loaded ${_categories.length} parent categories');
      notifyListeners();
    } catch (e) {
      log('Error processing categories: $e');
    }
  }

  void _onProductsChanged(QuerySnapshot snapshot) {
    try {
      _allProducts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      _categorizeProducts(_allProducts);
      log('Loaded ${_allProducts.length} products');
      notifyListeners();
    } catch (e) {
      log('Error processing products: $e');
    }
  }

  void _onBannersChanged(QuerySnapshot snapshot) {
    try {
      final now = DateTime.now();
      
      _adBanners = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).where((banner) {
        // Check if banner is currently active
        final startDate = (banner['startDate'] as Timestamp?)?.toDate();
        final endDate = (banner['endDate'] as Timestamp?)?.toDate();
        
        if (startDate == null || endDate == null) return false;
        
        return now.isAfter(startDate) && now.isBefore(endDate);
      }).toList();
      
      // Sort by priority
      _adBanners.sort((a, b) {
        final priorityA = a['priority'] ?? 0;
        final priorityB = b['priority'] ?? 0;
        return priorityB.compareTo(priorityA);
      });
      
      log('Loaded ${_adBanners.length} active banners');
      notifyListeners();
    } catch (e) {
      log('Error processing banners: $e');
    }
  }

  // Load initial data
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadParentCategories(),
      _loadProducts(),
      _loadAdBanners(),
    ]);
  }

  // Load parent categories only
  Future<void> _loadParentCategories() async {
    try {
      log('Loading parent categories...');
      
      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .where('level', isEqualTo: 0) // Parent categories only
          .get();

      _categories = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort categories
      _categories.sort((a, b) {
        final orderA = a['order'] ?? 0;
        final orderB = b['order'] ?? 0;
        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }
        final priorityA = a['priority'] ?? 0;
        final priorityB = b['priority'] ?? 0;
        return priorityB.compareTo(priorityA);
      });
      
      log('Loaded ${_categories.length} parent categories');
    } catch (e) {
      log('Error loading parent categories: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      log('Loading products...');
      
      final snapshot = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      _allProducts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      _categorizeProducts(_allProducts);
      log('Loaded ${_allProducts.length} products');
    } catch (e) {
      log('Error loading products: $e');
    }
  }

  Future<void> _loadAdBanners() async {
    try {
      log('Loading ad banners...');
      
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection('adBanners')
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThan: now)
          .get();

      _adBanners = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by priority
      _adBanners.sort((a, b) {
        final priorityA = a['priority'] ?? 0;
        final priorityB = b['priority'] ?? 0;
        return priorityB.compareTo(priorityA);
      });
      
      log('Loaded ${_adBanners.length} active banners');
    } catch (e) {
      log('Error loading ad banners: $e');
      
      // Fallback: load all banners if date query fails
      try {
        final fallbackSnapshot = await _firestore
            .collection('adBanners')
            .where('isActive', isEqualTo: true)
            .get();
            
        final now = DateTime.now();
        _adBanners = fallbackSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).where((banner) {
          final startDate = (banner['startDate'] as Timestamp?)?.toDate();
          final endDate = (banner['endDate'] as Timestamp?)?.toDate();
          
          if (startDate == null || endDate == null) return false;
          return now.isAfter(startDate) && now.isBefore(endDate);
        }).toList();
        
        log('Loaded ${_adBanners.length} banners using fallback method');
      } catch (fallbackError) {
        log('Fallback banner loading also failed: $fallbackError');
      }
    }
  }

  // Categorize products into different sections
  void _categorizeProducts(List<Map<String, dynamic>> allProducts) {
    try {
      // Featured products
      _featuredProducts = allProducts
          .where((p) => p['isFeatured'] == true || p['isPromoted'] == true)
          .take(10)
          .toList();

      // Most viewed products
      final viewedProducts = allProducts
          .where((p) => (p['viewCount'] ?? 0) > 0)
          .toList();
      viewedProducts.sort((a, b) => (b['viewCount'] ?? 0).compareTo(a['viewCount'] ?? 0));
      _mostViewedProducts = viewedProducts.take(10).toList();

      // Personalized products
      if (_userLatitude != null && _userLongitude != null) {
        _personalizedProducts = _getLocationBasedProducts(allProducts);
      } else {
        _personalizedProducts = allProducts
            .where((p) => p['isFeatured'] != true && p['isPromoted'] != true)
            .take(10)
            .toList();
      }

      // Category-specific products
      _mobilePhones = allProducts
          .where((p) => _isMobileCategory(p['category']?.toString() ?? ''))
          .take(10)
          .toList();

      _computers = allProducts
          .where((p) => _isComputerCategory(p['category']?.toString() ?? ''))
          .take(10)
          .toList();

      _computerAccessories = allProducts
          .where((p) => _isComputerAccessoryCategory(p['category']?.toString() ?? ''))
          .take(10)
          .toList();
          
      log('Categorized products: Featured(${_featuredProducts.length}), Viewed(${_mostViewedProducts.length}), Personalized(${_personalizedProducts.length})');
    } catch (e) {
      log('Error categorizing products: $e');
    }
  }

  // Get products based on user location
  List<Map<String, dynamic>> _getLocationBasedProducts(List<Map<String, dynamic>> products) {
    if (_userLatitude == null || _userLongitude == null) {
      return products.take(10).toList();
    }

    const double radiusInKm = 50.0;

    final localProducts = products.where((product) {
      final lat = product['latitude'] as double?;
      final lng = product['longitude'] as double?;
      
      if (lat == null || lng == null) return false;

      final distance = Geolocator.distanceBetween(
        _userLatitude!,
        _userLongitude!,
        lat,
        lng,
      );

      return distance <= radiusInKm * 1000;
    }).toList();

    // Sort by distance
    localProducts.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        _userLatitude!,
        _userLongitude!,
        a['latitude'] as double,
        a['longitude'] as double,
      );
      final distanceB = Geolocator.distanceBetween(
        _userLatitude!,
        _userLongitude!,
        b['latitude'] as double,
        b['longitude'] as double,
      );
      return distanceA.compareTo(distanceB);
    });

    return localProducts.take(10).toList();
  }

  // Category helper methods
  bool _isMobileCategory(String category) {
    final mobileCategories = [
      'mobiles',
      'mobile phones',
      'smartphones',
      'cell phones',
      'phone',
    ];
    return mobileCategories.any((cat) => 
        category.toLowerCase().contains(cat));
  }

  bool _isComputerCategory(String category) {
    final computerCategories = [
      'computers',
      'laptops',
      'computer',
      'laptop',
      'desktop',
      'pc',
    ];
    return computerCategories.any((cat) => 
        category.toLowerCase().contains(cat));
  }

  bool _isComputerAccessoryCategory(String category) {
    final accessoryCategories = [
      'computer accessories',
      'accessories',
      'cables',
      'keyboards',
      'mouse',
      'headphones',
      'monitor',
      'speaker',
    ];
    return accessoryCategories.any((cat) => 
        category.toLowerCase().contains(cat));
  }

  // Public methods for UI interaction
  Future<void> refreshData() async {
    try {
      _setError(null);
      await _loadInitialData();
    } catch (e) {
      _setError('Failed to refresh data: $e');
    }
  }

  Future<void> incrementProductView(String productId) async {
    try {
      await _firestore.collection('items').doc(productId).update({
        'viewCount': FieldValue.increment(1),
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      log('Error incrementing view count: $e');
    }
  }

  Future<void> toggleProductFavorite(String productId, bool isFavorite) async {
    try {
      await _firestore.collection('items').doc(productId).update({
        'favoriteCount': FieldValue.increment(isFavorite ? 1 : -1),
        'likes': FieldValue.increment(isFavorite ? 1 : -1),
      });
    } catch (e) {
      log('Error toggling favorite: $e');
    }
  }

  // Get products by category ID
  Future<List<Map<String, dynamic>>> getProductsByCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .where('category', isEqualTo: categoryId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      log('Error getting products by category: $e');
      return [];
    }
  }

  // Get subcategories for a parent category
  Future<List<Map<String, dynamic>>> getSubCategories(String parentCategoryId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .where('parentId', isEqualTo: parentCategoryId)
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      log('Error getting subcategories: $e');
      return [];
    }
  }

  // Search products
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      final snapshot = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .get();

      final results = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((product) {
        final title = (product['itemTitle'] ?? '').toString().toLowerCase();
        final description = (product['description'] ?? '').toString().toLowerCase();
        final brand = (product['brand'] ?? '').toString().toLowerCase();
        final searchQuery = query.toLowerCase();
        
        return title.contains(searchQuery) || 
               description.contains(searchQuery) || 
               brand.contains(searchQuery);
      }).toList();

      return results;
    } catch (e) {
      log('Error searching products: $e');
      return [];
    }
  }

  // Get banner by ID
  Map<String, dynamic>? getBannerById(String bannerId) {
    try {
      return _adBanners.firstWhere((banner) => banner['id'] == bannerId);
    } catch (e) {
      return null;
    }
  }

  // Get category by ID
  Map<String, dynamic>? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((category) => category['id'] == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Public method to set user location from UI
  void setUserLocation(double latitude, double longitude, String address) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _userLocationAddress = address;
    notifyListeners();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _productsSubscription?.cancel();
    _bannersSubscription?.cancel();
    super.dispose();
  }
}