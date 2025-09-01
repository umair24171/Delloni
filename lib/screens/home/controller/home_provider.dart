// providers/home_provider.dart
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class HomeProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // State variables
  bool _isLoading = true;
  String? _error;
  
  // OPTIMIZED: Separate loading states for better UX
  bool _isCategoriesLoading = false;
  bool _isProductsLoading = false;
  bool _isBannersLoading = false;
  
  // Data lists - OPTIMIZED: Using final for better memory management
  final List<Map<String, dynamic>> _categories = [];
  final List<Map<String, dynamic>> _featuredProducts = [];
  final List<Map<String, dynamic>> _personalizedProducts = [];
  final List<Map<String, dynamic>> _mostViewedProducts = [];
  final List<Map<String, dynamic>> _mobilePhones = [];
  final List<Map<String, dynamic>> _computers = [];
  final List<Map<String, dynamic>> _computerAccessories = [];
  final List<Map<String, dynamic>> _adBanners = [];
  final List<Map<String, dynamic>> _allProducts = [];
  
  // OPTIMIZED: Cache for expensive computations
  final Map<String, List<Map<String, dynamic>>> _categoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, List<Map<String, dynamic>>> _searchCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // OPTIMIZED: Pagination support
  DocumentSnapshot? _lastProductDoc;
  DocumentSnapshot? _lastCategoryDoc;
  bool _hasMoreProducts = true;
  bool _hasMoreCategories = true;
  static const int _pageSize = 20;
  static const int _maxProducts = 100; // Limit total products in memory
  
  // User location for personalization
  double? _userLatitude;
  double? _userLongitude;
  String? _userLocationAddress;
  
  // OPTIMIZED: Debouncing and throttling
  Timer? _debounceTimer;
  Timer? _locationDebounceTimer;
  DateTime? _lastUpdateTime;
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  static const Duration _minUpdateInterval = Duration(seconds: 2);
  
  // Streams for real-time updates
  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _productsSubscription;
  StreamSubscription? _bannersSubscription;
  
  // OPTIMIZED: Connection state tracking
  bool _isOnline = true;
  
  // OPTIMIZED: Performance monitoring
  final Stopwatch _performanceStopwatch = Stopwatch();

  // Getters - OPTIMIZED: Using unmodifiable lists
  bool get isLoading => _isLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  bool get isProductsLoading => _isProductsLoading;
  bool get isBannersLoading => _isBannersLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get categories => List.unmodifiable(_categories);
  List<Map<String, dynamic>> get featuredProducts => List.unmodifiable(_featuredProducts);
  List<Map<String, dynamic>> get personalizedProducts => List.unmodifiable(_personalizedProducts);
  List<Map<String, dynamic>> get mostViewedProducts => List.unmodifiable(_mostViewedProducts);
  List<Map<String, dynamic>> get mobilePhones => List.unmodifiable(_mobilePhones);
  List<Map<String, dynamic>> get computers => List.unmodifiable(_computers);
  List<Map<String, dynamic>> get computerAccessories => List.unmodifiable(_computerAccessories);
  List<Map<String, dynamic>> get adBanners => List.unmodifiable(_adBanners);
  List<Map<String, dynamic>> get allProducts => List.unmodifiable(_allProducts);
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  String? get userLocationAddress => _userLocationAddress;
  bool get hasMoreProducts => _hasMoreProducts;
  bool get hasMoreCategories => _hasMoreCategories;

  HomeProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _performanceStopwatch.start();
      _setLoading(true);
      
      // OPTIMIZED: Parallel initialization with timeout
      await Future.any([
        _performInitialization(),
        Future.delayed(Duration(seconds: 15), () => throw TimeoutException('Initialization timeout')),
      ]);
      
      _setLoading(false);
      _performanceStopwatch.stop();
      log('HomeProvider initialized in ${_performanceStopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      _setError('Failed to initialize data: $e');
      log('HomeProvider initialization error: $e');
      _performanceStopwatch.stop();
    }
  }

  Future<void> _performInitialization() async {
    // OPTIMIZED: Get location first as it's needed for personalization
    await _getUserLocation();
    
    // OPTIMIZED: Load critical data first, then set up listeners
    await _loadCriticalData();
    _setupOptimizedRealTimeListeners();
    
    // OPTIMIZED: Load remaining data in background
    unawaited(_loadRemainingData());
  }

  Future<void> _loadCriticalData() async {
    // Load only essential data for immediate display
    await Future.wait([
      _loadParentCategories(limit: 8), // Only load first 8 categories
      _loadFeaturedProducts(), // Load featured products first
      _loadActiveAdBanners(),
    ]);
  }

  Future<void> _loadRemainingData() async {
    // Load remaining data in background
    await Future.wait([
      _loadMoreProducts(),
      _loadMoreCategories(),
    ]);
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _scheduleNotification();
    }
  }

  void _setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  // OPTIMIZED: Debounced notifications to prevent excessive rebuilds
  void _scheduleNotification() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (!_shouldThrottleUpdate()) {
        notifyListeners();
        _lastUpdateTime = DateTime.now();
      }
    });
  }

  bool _shouldThrottleUpdate() {
    if (_lastUpdateTime == null) return false;
    return DateTime.now().difference(_lastUpdateTime!) < _minUpdateInterval;
  }

  // OPTIMIZED: Efficient location handling with debouncing
  Future<void> _getUserLocation() async {
    try {
      if (!await _isLocationServiceAvailable()) return;

      final position = await _getCurrentPositionWithTimeout();
      if (position == null) return;

      _userLatitude = position.latitude;
      _userLongitude = position.longitude;

      // OPTIMIZED: Debounce reverse geocoding
      _locationDebounceTimer?.cancel();
      _locationDebounceTimer = Timer(Duration(seconds: 1), () async {
        await _performReverseGeocoding();
      });
      
      log('User location obtained: $_userLatitude, $_userLongitude');
    } catch (e) {
      log('Error getting user location: $e');
    }
  }

  Future<bool> _isLocationServiceAvailable() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    return permission != LocationPermission.deniedForever;
  }

  Future<Position?> _getCurrentPositionWithTimeout() async {
    try {
      return await Future.any([
        Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium),
        Future.delayed(Duration(seconds: 5), () => throw TimeoutException('Location timeout')),
      ]);
    } catch (e) {
      log('Location timeout or error: $e');
      return null;
    }
  }

  Future<void> _performReverseGeocoding() async {
    try {
      if (_userLatitude == null || _userLongitude == null) return;
      
      final placemarks = await placemarkFromCoordinates(_userLatitude!, _userLongitude!);
      if (placemarks.isNotEmpty) {
        _userLocationAddress = placemarks.first.locality ?? 
                              placemarks.first.subAdministrativeArea ?? 
                              placemarks.first.administrativeArea ?? 
                              'Unknown location';
      } else {
        _userLocationAddress = 'Unknown location';
      }
      _scheduleNotification();
    } catch (e) {
      _userLocationAddress = 'Unknown location';
      log('Reverse geocoding error: $e');
    }
  }

  // OPTIMIZED: More efficient real-time listeners with error handling
  // ✅ ENHANCED: Better real-time listener setup with immediate data fetching
  void _setupOptimizedRealTimeListeners() {
    // Categories listener with pagination
    _categoriesSubscription = _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .where('level', isEqualTo: 0)
        .orderBy('order')
        .limit(_pageSize)
        .snapshots()
        .listen(_onCategoriesChanged, 
                onError: _handleStreamError,
                onDone: () => log('Categories stream completed'));

    // ✅ ENHANCED: Products listener with better filtering for recent items
    _productsSubscription = _firestore
        .collection('items')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize * 2) // Increased limit to catch more recent items
        .snapshots()
        .listen(_onProductsChanged,
                onError: _handleStreamError,
                onDone: () => log('Products stream completed'));

    // Banners listener
    _bannersSubscription = _firestore
        .collection('adBanners')
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .snapshots()
        .listen(_onBannersChanged,
                onError: _handleStreamError,
                onDone: () => log('Banners stream completed'));
  }

  void _handleStreamError(dynamic error) {
    log('Stream error: $error');
    _isOnline = false;
    // Don't set error state for stream errors - keep showing cached data
  }

  void _onCategoriesChanged(QuerySnapshot snapshot) {
    try {
      _isCategoriesLoading = true;
      
      final newCategories = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // OPTIMIZED: Update only if data actually changed
      if (!_listsEqual(_categories, newCategories)) {
        _categories.clear();
        _categories.addAll(_sortCategories(newCategories));
        
        if (snapshot.docs.isNotEmpty) {
          _lastCategoryDoc = snapshot.docs.last;
        }
        
        log('Updated ${_categories.length} categories');
        _scheduleNotification();
      }
      
      _isCategoriesLoading = false;
      _isOnline = true;
    } catch (e) {
      log('Error processing categories: $e');
      _isCategoriesLoading = false;
    }
  }

 // ✅ ENHANCED: Better product change handling with immediate updates
  void _onProductsChanged(QuerySnapshot snapshot) {
    try {
      _isProductsLoading = true;
      
      final newProducts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      log('📱 Real-time update: ${newProducts.length} products received');
      
      // ✅ ENHANCED: Force immediate update instead of checking for changes
      _updateProductsImmediately(newProducts);
      
      if (snapshot.docs.isNotEmpty) {
        _lastProductDoc = snapshot.docs.last;
      }
      
      _isProductsLoading = false;
      _isOnline = true;
      
      log('✅ Products updated via real-time listener');
    } catch (e) {
      log('❌ Error processing real-time product changes: $e');
      _isProductsLoading = false;
    }
  }
 // ✅ NEW: Force immediate product update without change checking
  void _updateProductsImmediately(List<Map<String, dynamic>> newProducts) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Remove duplicates from new products
      final uniqueNewProducts = _removeDuplicatesById(newProducts);
      
      // Replace current products with new ones (for real-time updates)
      _allProducts.clear();
      _allProducts.addAll(uniqueNewProducts.take(_maxProducts));
      
      // Force immediate recategorization
      _categorizeProductsOptimized(_allProducts);
      
      stopwatch.stop();
      log('✅ Immediate product update completed in ${stopwatch.elapsedMilliseconds}ms');
      _scheduleNotification();
      
    } catch (e) {
      log('❌ Error in immediate product update: $e');
    }
  }

  void _onBannersChanged(QuerySnapshot snapshot) {
    try {
      _isBannersLoading = true;
      
      final now = DateTime.now();
      final newBanners = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).where((banner) => _isBannerActive(banner, now)).toList();
      
      if (!_listsEqual(_adBanners, newBanners)) {
        _adBanners.clear();
        _adBanners.addAll(_sortBanners(newBanners));
        
        log('Updated ${_adBanners.length} active banners');
        _scheduleNotification();
      }
      
      _isBannersLoading = false;
      _isOnline = true;
    } catch (e) {
      log('Error processing banners: $e');
      _isBannersLoading = false;
    }
  }

  // OPTIMIZED: Efficient product updating with minimal recomputation
 void _updateProductsEfficiently(List<Map<String, dynamic>> newProducts) {
  // Check if we need to update
  if (_listsEqual(_allProducts, newProducts)) return;
  
  final stopwatch = Stopwatch()..start();
  
  // FIXED: Remove duplicates from new products first
  final uniqueNewProducts = _removeDuplicatesById(newProducts);
  
  // OPTIMIZED: Limit total products in memory
  if (_allProducts.length + uniqueNewProducts.length > _maxProducts) {
    final overflow = _allProducts.length + uniqueNewProducts.length - _maxProducts;
    if (overflow > 0 && _allProducts.length > overflow) {
      _allProducts.removeRange(_allProducts.length - overflow, _allProducts.length);
    }
  }
  
  // FIXED: Add only unique products to avoid duplicates
  final existingIds = _allProducts.map((p) => p['id']).toSet();
  final productsToAdd = uniqueNewProducts.where((p) => !existingIds.contains(p['id'])).toList();
  
  // Add new unique products
  _allProducts.addAll(productsToAdd);
  
  // FIXED: Remove any duplicates that might have slipped through
  final uniqueAllProducts = _removeDuplicatesById(_allProducts);
  _allProducts.clear();
  _allProducts.addAll(uniqueAllProducts);
  
  // OPTIMIZED: Only recategorize if we have significant changes
  if (productsToAdd.length > 3 || _shouldRecategorize()) {
    _categorizeProductsOptimized(_allProducts);
  }
  
  stopwatch.stop();
  log('Product update completed in ${stopwatch.elapsedMilliseconds}ms. Added ${productsToAdd.length} unique products.');
  _scheduleNotification();
}

  bool _shouldRecategorize() {
    // Recategorize every 5 minutes or if categories are empty
    return _featuredProducts.isEmpty || 
           (_lastUpdateTime != null && 
            DateTime.now().difference(_lastUpdateTime!) > Duration(minutes: 5));
  }

  // OPTIMIZED: Efficient initial data loading with pagination
  Future<void> _loadParentCategories({int limit = 20}) async {
    try {
      log('Loading parent categories (limit: $limit)...');
      _isCategoriesLoading = true;
      
      Query query = _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .where('level', isEqualTo: 0)
          .orderBy('order')
          .limit(limit);

      final snapshot = await query.get();

      final categories = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      _categories.clear();
      _categories.addAll(_sortCategories(categories));
      
      if (snapshot.docs.isNotEmpty) {
        _lastCategoryDoc = snapshot.docs.last;
        _hasMoreCategories = snapshot.docs.length == limit;
      }
      
      log('Loaded ${_categories.length} parent categories');
      _isCategoriesLoading = false;
    } catch (e) {
      log('Error loading parent categories: $e');
      _isCategoriesLoading = false;
    }
  }

  Future<void> _loadMoreCategories() async {
    if (!_hasMoreCategories || _isCategoriesLoading) return;
    
    try {
      _isCategoriesLoading = true;
      
      Query query = _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .where('level', isEqualTo: 0)
          .orderBy('order')
          .limit(_pageSize);
          
      if (_lastCategoryDoc != null) {
        query = query.startAfterDocument(_lastCategoryDoc!);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        final newCategories = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        
        _categories.addAll(_sortCategories(newCategories));
        _lastCategoryDoc = snapshot.docs.last;
        _hasMoreCategories = snapshot.docs.length == _pageSize;
        
        _scheduleNotification();
      } else {
        _hasMoreCategories = false;
      }
      
      _isCategoriesLoading = false;
    } catch (e) {
      log('Error loading more categories: $e');
      _isCategoriesLoading = false;
    }
  }

 Future<void> _loadFeaturedProducts() async {
  try {
    log('Loading featured products...');
    
    final snapshot = await _firestore
        .collection('items')
        .where('status', isEqualTo: 'active')
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(20) // FIXED: Increased limit to account for potential duplicates
        .get();

    final featured = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    
    _featuredProducts.clear();
    // FIXED: Remove duplicates and limit to 10
    _featuredProducts.addAll(_removeDuplicatesById(featured).take(10));
    
    log('Loaded ${_featuredProducts.length} unique featured products');
  } catch (e) {
    log('Error loading featured products: $e');
  }
}

  Future<void> _loadMoreProducts() async {
    if (!_hasMoreProducts || _isProductsLoading) return;
    
    try {
      _isProductsLoading = true;
      
      Query query = _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);
          
      if (_lastProductDoc != null) {
        query = query.startAfterDocument(_lastProductDoc!);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        final newProducts = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        
        _updateProductsEfficiently(newProducts);
        _lastProductDoc = snapshot.docs.last;
        _hasMoreProducts = snapshot.docs.length == _pageSize;
      } else {
        _hasMoreProducts = false;
      }
      
      _isProductsLoading = false;
    } catch (e) {
      log('Error loading more products: $e');
      _isProductsLoading = false;
    }
  }

  Future<void> _loadActiveAdBanners() async {
    try {
      log('Loading ad banners...');
      _isBannersLoading = true;
      
      // OPTIMIZED: Simplified banner query
      final snapshot = await _firestore
          .collection('adBanners')
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .limit(10)
          .get();

      final now = DateTime.now();
      final banners = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((banner) => _isBannerActive(banner, now)).toList();
      
      _adBanners.clear();
      _adBanners.addAll(banners);
      
      log('Loaded ${_adBanners.length} active banners');
      _isBannersLoading = false;
    } catch (e) {
      log('Error loading ad banners: $e');
      _isBannersLoading = false;
    }
  }

  bool _isBannerActive(Map<String, dynamic> banner, DateTime now) {
    try {
      final startDate = (banner['startDate'] as Timestamp?)?.toDate();
      final endDate = (banner['endDate'] as Timestamp?)?.toDate();
      
      if (startDate == null || endDate == null) return false;
      return now.isAfter(startDate) && now.isBefore(endDate);
    } catch (e) {
      return false;
    }
  }

  // OPTIMIZED: More efficient product categorization with caching
  void _categorizeProductsOptimized(List<Map<String, dynamic>> allProducts) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // OPTIMIZED: Clear previous data efficiently
      _mostViewedProducts.clear();
      _personalizedProducts.clear();
      _mobilePhones.clear();
      _computers.clear();
      _computerAccessories.clear();
      
      // OPTIMIZED: Use single pass for multiple categorizations
      final viewedProducts = <Map<String, dynamic>>[];
      final mobileProducts = <Map<String, dynamic>>[];
      final computerProducts = <Map<String, dynamic>>[];
      final accessoryProducts = <Map<String, dynamic>>[];
      
      for (final product in allProducts) {
        // Collect viewed products
        if ((product['viewCount'] ?? 0) > 0) {
          viewedProducts.add(product);
        }
        
        // Categorize by type
        final category = product['category']?.toString() ?? '';
        if (_isMobileCategory(category)) {
          mobileProducts.add(product);
        } else if (_isComputerCategory(category)) {
          computerProducts.add(product);
        } else if (_isComputerAccessoryCategory(category)) {
          accessoryProducts.add(product);
        }
      }
      
      // OPTIMIZED: Sort once and take needed amount
      _mostViewedProducts.addAll(_sortByViewCount(viewedProducts).take(10));
      
      // OPTIMIZED: Location-based filtering with caching
      if (_userLatitude != null && _userLongitude != null) {
        _personalizedProducts.addAll(_getLocationBasedProductsOptimized(allProducts, 10));
        _mobilePhones.addAll(_getLocationBasedProductsOptimized(mobileProducts, 10));
        _computers.addAll(_getLocationBasedProductsOptimized(computerProducts, 10));
        _computerAccessories.addAll(_getLocationBasedProductsOptimized(accessoryProducts, 10));
      } else {
        _personalizedProducts.addAll(_sortByDate(allProducts).take(10));
        _mobilePhones.addAll(mobileProducts.take(10));
        _computers.addAll(computerProducts.take(10));
        _computerAccessories.addAll(accessoryProducts.take(10));
      }

      stopwatch.stop();
      log('Product categorization completed in ${stopwatch.elapsedMilliseconds}ms');
      log('Categorized: Featured(${_featuredProducts.length}), '
          'Viewed(${_mostViewedProducts.length}), '
          'Personalized(${_personalizedProducts.length}), '
          'Mobiles(${_mobilePhones.length}), '
          'Computers(${_computers.length}), '
          'Accessories(${_computerAccessories.length})');
        
    } catch (e) {
      log('Error categorizing products: $e');
    }
  }

  // OPTIMIZED: Efficient location-based filtering with distance calculation caching
  List<Map<String, dynamic>> _getLocationBasedProductsOptimized(
    List<Map<String, dynamic>> products, 
    int limit
  ) {
    if (_userLatitude == null || _userLongitude == null) {
      return products.take(limit).toList();
    }

    const double radiusInKm = 50.0;
    final userLat = _userLatitude!;
    final userLng = _userLongitude!;
    
    final List<MapEntry<Map<String, dynamic>, double>> productsWithDistance = [];
    
    for (final product in products) {
      final lat = product['latitude'] as double?;
      final lng = product['longitude'] as double?;
      
      if (lat != null && lng != null) {
        final distance = Geolocator.distanceBetween(userLat, userLng, lat, lng);
        if (distance <= radiusInKm * 1000) {
          productsWithDistance.add(MapEntry(product, distance));
        }
      }
    }

    if (productsWithDistance.isNotEmpty) {
      // Sort by distance and return
      productsWithDistance.sort((a, b) => a.value.compareTo(b.value));
      return productsWithDistance.take(limit).map((e) => e.key).toList();
    } else {
      // Fallback to city-based or recent products
      return _getCityBasedProductsOptimized(products, limit);
    }
  }

  List<Map<String, dynamic>> _getCityBasedProductsOptimized(
    List<Map<String, dynamic>> products, 
    int limit
  ) {
    if (_userLocationAddress == null) {
      return _sortByDate(products).take(limit).toList();
    }

    final userCity = _getCityFromAddress(_userLocationAddress!).toLowerCase();
    
    final cityProducts = products.where((product) {
      final productLocation = product['locationAddress']?.toString() ?? '';
      final productCity = (product['cityName']?.toString() ?? 
                          _getCityFromAddress(productLocation)).toLowerCase();
      
      return productCity.contains(userCity) || userCity.contains(productCity);
    }).toList();

    return cityProducts.isNotEmpty 
        ? cityProducts.take(limit).toList()
        : _sortByDate(products).take(limit).toList();
  }

  // OPTIMIZED: Efficient sorting methods
  List<Map<String, dynamic>> _sortCategories(List<Map<String, dynamic>> categories) {
    categories.sort((a, b) {
      final orderA = a['order'] ?? 0;
      final orderB = b['order'] ?? 0;
      if (orderA != orderB) return orderA.compareTo(orderB);
      
      final priorityA = a['priority'] ?? 0;
      final priorityB = b['priority'] ?? 0;
      return priorityB.compareTo(priorityA);
    });
    return categories;
  }

  List<Map<String, dynamic>> _sortBanners(List<Map<String, dynamic>> banners) {
    banners.sort((a, b) {
      final priorityA = a['priority'] ?? 0;
      final priorityB = b['priority'] ?? 0;
      return priorityB.compareTo(priorityA);
    });
    return banners;
  }

  List<Map<String, dynamic>> _sortByViewCount(List<Map<String, dynamic>> products) {
    products.sort((a, b) => (b['viewCount'] ?? 0).compareTo(a['viewCount'] ?? 0));
    return products;
  }

  List<Map<String, dynamic>> _sortByDate(List<Map<String, dynamic>> products) {
    products.sort((a, b) {
      try {
        DateTime aDate = a['createdAt'] is Timestamp 
            ? (a['createdAt'] as Timestamp).toDate()
            : DateTime.parse(a['createdAt'].toString());
        DateTime bDate = b['createdAt'] is Timestamp 
            ? (b['createdAt'] as Timestamp).toDate()
            : DateTime.parse(b['createdAt'].toString());
        return bDate.compareTo(aDate);
      } catch (e) {
        return 0;
      }
    });
    return products;
  }

  // OPTIMIZED: Efficient list comparison
  bool _listsEqual(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i]['id'] != list2[i]['id']) return false;
    }
    return true;
  }

  // Helper methods remain the same but optimized
  bool _isMobileCategory(String category) {
    final lowerCategory = category.toLowerCase();
    return lowerCategory.contains('mobile') || 
           lowerCategory.contains('phone') || 
           lowerCategory.contains('smartphone');
  }

  bool _isComputerCategory(String category) {
    final lowerCategory = category.toLowerCase();
    return lowerCategory.contains('computer') || 
           lowerCategory.contains('laptop') || 
           lowerCategory.contains('desktop') || 
           lowerCategory.contains('pc');
  }

  bool _isComputerAccessoryCategory(String category) {
    final lowerCategory = category.toLowerCase();
    return lowerCategory.contains('accessories') || 
           lowerCategory.contains('cable') || 
           lowerCategory.contains('keyboard') || 
           lowerCategory.contains('mouse') || 
           lowerCategory.contains('headphone') || 
           lowerCategory.contains('monitor') || 
           lowerCategory.contains('speaker');
  }

  String _getCityFromAddress(String address) {
    final parts = address.split(',');
    return parts.isNotEmpty ? parts.first.trim() : address;
  }

  // OPTIMIZED: Public methods with caching and error handling
   // ✅ ENHANCED: Enhanced refresh method with better error handling and logging
  Future<void> refreshData() async {
    try {
      log('🔄 Starting HomeProvider data refresh...');
      _setError(null);
      
      // Clear caches first
      _clearCaches();
      
      // Reset pagination
      _lastProductDoc = null;
      _lastCategoryDoc = null;
      _hasMoreProducts = true;
      _hasMoreCategories = true;
      
      // Clear existing data
      _categories.clear();
      _featuredProducts.clear();
      _personalizedProducts.clear();
      _mostViewedProducts.clear();
      _mobilePhones.clear();
      _computers.clear();
      _computerAccessories.clear();
      _adBanners.clear();
      _allProducts.clear();
      
      // Load critical data first
      await _loadCriticalData();
      
      // Load remaining data in background
      unawaited(_loadRemainingData());
      
      log('✅ HomeProvider data refresh completed');
    } catch (e) {
      log('❌ HomeProvider refresh failed: $e');
      _setError('Failed to refresh data: $e');
    }
  }

  void _clearCaches() {
    _categoryCache.clear();
    _cacheTimestamps.clear();
    _searchCache.clear();
  }

  // OPTIMIZED: Batch operations for better performance
  Future<void> incrementProductView(String productId) async {
    try {
      // OPTIMIZED: Use batch write for better performance
      final batch = _firestore.batch();
      final docRef = _firestore.collection('items').doc(productId);
      
      batch.update(docRef, {
        'viewCount': FieldValue.increment(1),
        'views': FieldValue.increment(1),
      });
      
      await batch.commit();
    } catch (e) {
      log('Error incrementing view count: $e');
    }
  }

  Future<void> toggleProductFavorite(String productId, bool isFavorite) async {
    try {
      // OPTIMIZED: Use batch write
      final batch = _firestore.batch();
      final docRef = _firestore.collection('items').doc(productId);
      
      batch.update(docRef, {
        'favoriteCount': FieldValue.increment(isFavorite ? 1 : -1),
        'likes': FieldValue.increment(isFavorite ? 1 : -1),
      });
      
      await batch.commit();
    } catch (e) {
      log('Error toggling favorite: $e');
    }
  }

  // OPTIMIZED: Cached category products
  Future<List<Map<String, dynamic>>> getProductsByCategory(String categoryId) async {
    final cacheKey = 'category_$categoryId';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return _categoryCache[cacheKey]!;
    }
    
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .where('category', isEqualTo: categoryId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final products = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Cache the result
      _categoryCache[cacheKey] = products;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      return products;
    } catch (e) {
      log('Error getting products by category: $e');
      return _categoryCache[cacheKey] ?? [];
    }
  }

  // OPTIMIZED: Cached search with debouncing
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    
    final normalizedQuery = query.toLowerCase().trim();
    
    // Check cache first
    if (_searchCache.containsKey(normalizedQuery)) {
      return _searchCache[normalizedQuery]!;
    }
    
    try {
      // OPTIMIZED: Search in memory first for better performance
      final memoryResults = _searchInMemory(normalizedQuery);
      
      if (memoryResults.isNotEmpty) {
        _searchCache[normalizedQuery] = memoryResults;
        return memoryResults;
      }
      
      // Fallback to Firestore if memory search doesn't yield results
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
        
        return title.contains(normalizedQuery) || 
               description.contains(normalizedQuery) || 
               brand.contains(normalizedQuery);
      }).toList();

      // Cache the result
      _searchCache[normalizedQuery] = results;
      
      return results;
    } catch (e) {
      log('Error searching products: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _searchInMemory(String query) {
    return _allProducts.where((product) {
      final title = (product['itemTitle'] ?? '').toString().toLowerCase();
      final description = (product['description'] ?? '').toString().toLowerCase();
      final brand = (product['brand'] ?? '').toString().toLowerCase();
      
      return title.contains(query) || 
             description.contains(query) || 
             brand.contains(query);
    }).toList();
  }

  bool _isCacheValid(String key) {
    if (!_categoryCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[key]!;
    return DateTime.now().difference(cacheTime) < _cacheExpiry;
  }

  // Optimized getters with null safety
  Map<String, dynamic>? getBannerById(String bannerId) {
    try {
      return _adBanners.firstWhere((banner) => banner['id'] == bannerId);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((category) => category['id'] == categoryId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSubCategories(String parentCategoryId) async {
    final cacheKey = 'subcategories_$parentCategoryId';
    
    if (_isCacheValid(cacheKey)) {
      return _categoryCache[cacheKey]!;
    }
    
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .where('parentId', isEqualTo: parentCategoryId)
          .orderBy('order')
          .get();

      final subcategories = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      _categoryCache[cacheKey] = subcategories;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      return subcategories;
    } catch (e) {
      log('Error getting subcategories: $e');
      return _categoryCache[cacheKey] ?? [];
    }
  }

  void setUserLocation(double latitude, double longitude, String address) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _userLocationAddress = address;
    
    // OPTIMIZED: Recategorize products when location changes
    if (_allProducts.isNotEmpty) {
      _categorizeProductsOptimized(_allProducts);
    }
    
    _scheduleNotification();
  }

  // OPTIMIZED: Load more data methods for pagination
  Future<void> loadMoreProducts() async {
    if (_hasMoreProducts && !_isProductsLoading) {
      await _loadMoreProducts();
    }
  }

  Future<void> loadMoreCategories() async {
    if (_hasMoreCategories && !_isCategoriesLoading) {
      await _loadMoreCategories();
    }
  }

  // OPTIMIZED: Performance monitoring methods
  Map<String, dynamic> getPerformanceStats() {
    return {
      'totalProducts': _allProducts.length,
      'totalCategories': _categories.length,
      'cacheSize': _categoryCache.length,
      'searchCacheSize': _searchCache.length,
      'isOnline': _isOnline,
      'hasMoreProducts': _hasMoreProducts,
      'hasMoreCategories': _hasMoreCategories,
    };
  }
  // FIXED: Helper method to remove duplicates based on product ID
List<Map<String, dynamic>> _removeDuplicatesById(List<Map<String, dynamic>> products) {
  final seen = <String>{};
  final result = <Map<String, dynamic>>[];
  
  for (final product in products) {
    final id = product['id'] ?? '';
    if (id.isNotEmpty && !seen.contains(id)) {
      seen.add(id);
      result.add(product);
    }
  }
  
  return result;
}
// ✅ NEW: Method to add optimistic item update for immediate visibility
  void addOptimisticItem(Map<String, dynamic> itemData) {
    try {
      // Add to the beginning of allProducts for immediate visibility
      _allProducts.insert(0, itemData);
      
      // Also add to appropriate category lists for immediate visibility
      final category = itemData['category']?.toString() ?? '';
      final categoryName = itemData['categoryName']?.toString() ?? '';
      
      // Add to featured if applicable
      if (itemData['isFeatured'] == true) {
        _featuredProducts.insert(0, itemData);
      }
      
      // Add to category-specific lists
      if (_isMobileCategory(categoryName)) {
        _mobilePhones.insert(0, itemData);
      } else if (_isComputerCategory(categoryName)) {
        _computers.insert(0, itemData);
      } else if (_isComputerAccessoryCategory(categoryName)) {
        _computerAccessories.insert(0, itemData);
      }
      
      // Add to personalized products (recent items)
      _personalizedProducts.insert(0, itemData);
      
      // Limit list sizes to prevent memory issues
      _limitListSizes();
      
      log('✅ Optimistic item added: ${itemData['itemTitle']}');
      _scheduleNotification();
    } catch (e) {
      log('❌ Error adding optimistic item: $e');
    }
  }

  // ✅ NEW: Method to limit list sizes after optimistic updates
  void _limitListSizes() {
    const maxOptimisticItems = 50;
    
    if (_allProducts.length > _maxProducts) {
      _allProducts.removeRange(_maxProducts, _allProducts.length);
    }
    
    if (_featuredProducts.length > maxOptimisticItems) {
      _featuredProducts.removeRange(maxOptimisticItems, _featuredProducts.length);
    }
    
    if (_personalizedProducts.length > maxOptimisticItems) {
      _personalizedProducts.removeRange(maxOptimisticItems, _personalizedProducts.length);
    }
    
    if (_mobilePhones.length > maxOptimisticItems) {
      _mobilePhones.removeRange(maxOptimisticItems, _mobilePhones.length);
    }
    
    if (_computers.length > maxOptimisticItems) {
      _computers.removeRange(maxOptimisticItems, _computers.length);
    }
    
    if (_computerAccessories.length > maxOptimisticItems) {
      _computerAccessories.removeRange(maxOptimisticItems, _computerAccessories.length);
    }
  }

  // ✅ ENHANCED: Public method to clear caches (called from ItemProvider)
  void clearCaches() {
    _clearCaches();
    log('✅ HomeProvider caches cleared from external call');
  }


  @override
  void dispose() {
    _debounceTimer?.cancel();
    _locationDebounceTimer?.cancel();
    _categoriesSubscription?.cancel();
    _productsSubscription?.cancel();
    _bannersSubscription?.cancel();
    _clearCaches();
    super.dispose();
  }
}