// providers/search_provider.dart
import 'dart:async';
import 'dart:developer';
import 'package:arabicmarketplace/screens/notifications/controller/saved_search_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';

// Add this import at the top
import 'dart:math' as math;
// Updated SearchProvider with city/district support
// providers/search_provider.dart
// Add this import at the top
import 'dart:math' as math;

import '../../notifications/view/notification_saved_search_page.dart';

// Enhanced SearchProvider with saved search integration
class SearchProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Search state
  String _searchQuery = '';
  bool _isSearching = false;
  String? _error;
  
  // Search results
  List<ProductModel> _searchResults = [];
  List<CategoryModel> _categoryResults = [];
  List<String> _searchSuggestions = [];
  List<String> _recentSearches = [];
  
  // Filters with city/district support
  SearchFilters _filters = SearchFilters();
  
  // Debounce timer for search
  Timer? _debounceTimer;
  
  // Constants
  static const int searchResultsLimit = 20;
  static const int maxRecentSearches = 10;
  static const Duration debounceDelay = Duration(milliseconds: 500);

  // Getters
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  String? get error => _error;
  List<ProductModel> get searchResults => _searchResults;
  List<CategoryModel> get categoryResults => _categoryResults;
  List<String> get searchSuggestions => _searchSuggestions;
  List<String> get recentSearches => _recentSearches;
  SearchFilters get filters => _filters;
  bool get hasResults => _searchResults.isNotEmpty || _categoryResults.isNotEmpty;
  bool get hasFilters => _filters.hasActiveFilters;

  // NEW: Check if current search can be saved
  bool get canSaveSearch => _searchQuery.isNotEmpty || _filters.hasActiveFilters;

  SearchProvider() {
    _loadRecentSearches();
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Update search query with debouncing
  void updateSearchQuery(String query) {
    _searchQuery = query.trim();
    _setError(null);
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (_searchQuery.isEmpty) {
      _clearSearchResults();
      _generateSearchSuggestions();
      return;
    }
    
    // Set debounce timer
    _debounceTimer = Timer(debounceDelay, () {
      _performSearch();
    });
    
    notifyListeners();
  }

  // Perform immediate search (for search button press)
  Future<void> performImmediateSearch([String? query]) async {
    _debounceTimer?.cancel();
    if (query != null) {
      _searchQuery = query.trim();
    }
    
    if (_searchQuery.isNotEmpty) {
      await _performSearch();
      _addToRecentSearches(_searchQuery);
    }
  }

  // Main search function with enhanced city/district filtering
  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) return;
    
    try {
      _setSearching(true);
      _setError(null);
      
      // Perform parallel searches
      final results = await Future.wait([
        _searchProducts(),
        _searchCategories(),
      ]);
      
      _searchResults = results[0] as List<ProductModel>;
      _categoryResults = results[1] as List<CategoryModel>;
      
      _setSearching(false);
      notifyListeners();
      
    } catch (e) {
      _setError('Search failed: ${e.toString()}');
      _setSearching(false);
      log('Search error: $e');
    }
  }

  // Enhanced search products with city/district filters
  Future<List<ProductModel>> _searchProducts() async {
    try {
      Query query = _firestore
          .collection('items')
          .where('status', isEqualTo: 'active');

      // Apply text search - search in multiple fields
      final searchTerms = _searchQuery.toLowerCase().split(' ');
      
      // Apply category filter first if specified
      if (_filters.selectedCategory != null && _filters.selectedCategory != 'Any') {
        query = query.where('category', isEqualTo: _filters.selectedCategory);
      }
      
      // Apply price range filter
      if (_filters.minPrice != null && _filters.minPrice! > 0) {
        query = query.where('price', isGreaterThanOrEqualTo: _filters.minPrice);
      }
      if (_filters.maxPrice != null && _filters.maxPrice! > 0) {
        query = query.where('price', isLessThanOrEqualTo: _filters.maxPrice);
      }
      
      // Apply ad type filter
      if (_filters.adType != null && _filters.adType != 'All') {
        final sellerType = _filters.adType == 'Individual' ? 'individual' : 'company';
        query = query.where('sellerType', isEqualTo: sellerType);
      }
      
      // Apply city filter
      if (_filters.cityId != null) {
        query = query.where('cityId', isEqualTo: _filters.cityId);
      }
      
      // Apply district filter (only if city is also specified)
      if (_filters.districtId != null && _filters.cityId != null) {
        query = query.where('districtId', isEqualTo: _filters.districtId);
      }
      
      // Order by creation date
      query = query.orderBy('createdAt', descending: true)
                  .limit(searchResultsLimit);
      
      final snapshot = await query.get();
      
      List<ProductModel> products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
      
      // Apply text search filtering (since Firestore has limited text search)
      products = products.where((product) {
        final searchableText = '${product.title} ${product.description} ${product.brand ?? ''} ${product.category} ${product.color ?? ''}'.toLowerCase();
        return searchTerms.any((term) => searchableText.contains(term));
      }).toList();
      
      // Apply location filter if needed (for current location searches)
      if (_filters.latitude != null && _filters.longitude != null && 
          _filters.radiusKm != null && _filters.cityId == null) {
        products = _filterByLocation(products);
      }
      
      return products;
      
    } catch (e) {
      log('Error searching products: $e');
      return [];
    }
  }

  // Search categories
  Future<List<CategoryModel>> _searchCategories() async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .get();
      
      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .where((category) => 
              category.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (category.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
      
      return categories;
      
    } catch (e) {
      log('Error searching categories: $e');
      return [];
    }
  }

  // Filter products by location (for current location searches)
  List<ProductModel> _filterByLocation(List<ProductModel> products) {
    if (_filters.latitude == null || _filters.longitude == null || _filters.radiusKm == null) {
      return products;
    }
    
    return products.where((product) {
      if (product.latitude == null || product.longitude == null) {
        return false;
      }
      
      final distance = _calculateDistance(
        _filters.latitude!,
        _filters.longitude!,
        product.latitude!,
        product.longitude!,
      );
      
      return distance <= _filters.radiusKm!;
    }).toList();
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

  // Enhanced generate search suggestions with city data
  Future<void> _generateSearchSuggestions() async {
    try {
      // Get popular categories
      final categoriesSnapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .limit(5)
          .get();
      
      final suggestions = categoriesSnapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();
      
      // Add popular cities to suggestions
      try {
        final citiesSnapshot = await _firestore
            .collection('cities')
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .limit(3)
            .get();
        
        suggestions.addAll(citiesSnapshot.docs
            .map((doc) => doc['name'] as String));
      } catch (e) {
        log('Error loading cities for suggestions: $e');
      }
      
      // Add some common search terms
      suggestions.addAll([
        'iPhone',
        'Samsung',
        'Laptop',
        'Car',
        'House',
        'Mobile',
        'Computer',
      ]);
      
      _searchSuggestions = suggestions.take(8).toList();
      notifyListeners();
      
    } catch (e) {
      log('Error generating suggestions: $e');
    }
  }

  // Recent searches management
  void _addToRecentSearches(String query) {
    if (query.isEmpty) return;
    
    _recentSearches.remove(query); // Remove if already exists
    _recentSearches.insert(0, query); // Add to beginning
    
    if (_recentSearches.length > maxRecentSearches) {
      _recentSearches = _recentSearches.take(maxRecentSearches).toList();
    }
    
    _saveRecentSearches();
    notifyListeners();
  }

  void removeFromRecentSearches(String query) {
    _recentSearches.remove(query);
    _saveRecentSearches();
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    _saveRecentSearches();
    notifyListeners();
  }

  // Enhanced filter management with city/district support
  void updateFilters(SearchFilters newFilters) {
    _filters = newFilters;
    notifyListeners();
    
    // Re-search with new filters if there's an active query
    if (_searchQuery.isNotEmpty) {
      _performSearch();
    }
  }

  void clearFilters() {
    _filters = SearchFilters();
    notifyListeners();
    
    // Re-search without filters
    if (_searchQuery.isNotEmpty) {
      _performSearch();
    }
  }

  // Enhanced search by location (city/district)
  Future<void> searchByLocation(String? cityId, String? districtId, String locationName) async {
    _filters = _filters.copyWith(
      cityId: cityId,
      districtId: districtId,
      location: locationName,
    );
    _searchQuery = locationName;
    await _performSearch();
    _addToRecentSearches(locationName);
  }

  // Get products by city
  Future<List<ProductModel>> getProductsByCity(String cityId) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .where('cityId', isEqualTo: cityId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting products by city: $e');
      return [];
    }
  }

  // Get products by district
  Future<List<ProductModel>> getProductsByDistrict(String districtId) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .where('districtId', isEqualTo: districtId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting products by district: $e');
      return [];
    }
  }

  // NEW: Saved search functionality
  
  // Show save search dialog
  Future<void> showSaveSearchDialog(BuildContext context) async {
    if (!canSaveSearch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a search query or apply filters first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SaveSearchDialog(
        currentQuery: _searchQuery,
        currentFilters: _filters,
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search saved! You\'ll get notified of new matches.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Build save search button widget
  Widget buildSaveSearchButton(BuildContext context) {
    if (!canSaveSearch) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => showSaveSearchDialog(context),
          icon: const Icon(Icons.bookmark_add, size: 18),
          label: const Text('Save This Search'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xff014700),
            side: const BorderSide(color: Color(0xff014700)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  // Build search results header with save option
  Widget buildSearchResultsHeader(BuildContext context) {
    if (!hasResults) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_searchResults.length} results found',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          if (canSaveSearch)
            TextButton.icon(
              onPressed: () => showSaveSearchDialog(context),
              icon: const Icon(Icons.bookmark_add, size: 18),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xff014700),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
        ],
      ),
    );
  }

  // Execute saved search
  Future<void> executeSearchFromSavedSearch(SavedSearchModel savedSearch) async {
    try {
      _setSearching(true);
      _setError(null);
      
      // Set search query and filters from saved search
      _searchQuery = savedSearch.query;
      _filters = SearchFilters(
        selectedCategory: savedSearch.categoryId,
        minPrice: savedSearch.minPrice,
        maxPrice: savedSearch.maxPrice,
        adType: savedSearch.adType,
        cityId: savedSearch.cityId,
        cityName: savedSearch.cityName,
        districtId: savedSearch.districtId,
        districtName: savedSearch.districtName,
        latitude: savedSearch.latitude,
        longitude: savedSearch.longitude,
        radiusKm: savedSearch.radiusKm,
        location: savedSearch.cityName,
      );
      
      // Perform search
      await _performSearch();
      
      // Add to recent searches
      if (_searchQuery.isNotEmpty) {
        _addToRecentSearches(_searchQuery);
      }
      
      _setSearching(false);
      notifyListeners();
      
    } catch (e) {
      _setError('Failed to execute saved search: ${e.toString()}');
      _setSearching(false);
      log('Error executing saved search: $e');
    }
  }

  // Get search summary for display
  String getSearchSummary() {
    List<String> parts = [];
    
    if (_searchQuery.isNotEmpty) {
      parts.add('"$_searchQuery"');
    }
    
    if (_filters.selectedCategory != null) {
      parts.add('in ${_filters.selectedCategory}');
    }
    
    if (_filters.minPrice != null || _filters.maxPrice != null) {
      if (_filters.minPrice != null && _filters.maxPrice != null) {
        parts.add('Rs ${_filters.minPrice!.toStringAsFixed(0)} - Rs ${_filters.maxPrice!.toStringAsFixed(0)}');
      } else if (_filters.minPrice != null) {
        parts.add('above Rs ${_filters.minPrice!.toStringAsFixed(0)}');
      } else if (_filters.maxPrice != null) {
        parts.add('below Rs ${_filters.maxPrice!.toStringAsFixed(0)}');
      }
    }
    
    if (_filters.cityName != null) {
      parts.add('in ${_filters.cityName}');
      if (_filters.districtName != null) {
        parts.add('(${_filters.districtName})');
      }
    }
    
    if (_filters.adType != null && _filters.adType != 'All') {
      parts.add('${_filters.adType} ads');
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : 'All items';
  }

  // Persistence for recent searches
  void _loadRecentSearches() {
    // TODO: Load from SharedPreferences
    // For now, using mock data
    _recentSearches = ['iPhone 12 pro max', 'Samsung Galaxy', 'MacBook'];
  }

  void _saveRecentSearches() {
    // TODO: Save to SharedPreferences
  }

  // Clear search results
  void _clearSearchResults() {
    _searchResults.clear();
    _categoryResults.clear();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _clearSearchResults();
    _setError(null);
    _debounceTimer?.cancel();
    notifyListeners();
  }

  // Search by category
  Future<void> searchByCategory(String categoryName) async {
    _filters = _filters.copyWith(selectedCategory: categoryName);
    _searchQuery = categoryName;
    await _performSearch();
    _addToRecentSearches(categoryName);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Enhanced SearchFilters class with city/district fields
class SearchFilters {
  final String? selectedCategory;
  final double? minPrice;
  final double? maxPrice;
  final double? minRadius;
  final double? maxRadius;
  final String? adType;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final String? location;
  final String? cityId;
  final String? cityName;
  final String? districtId;
  final String? districtName;

  const SearchFilters({
    this.selectedCategory,
    this.minPrice,
    this.maxPrice,
    this.minRadius,
    this.maxRadius,
    this.adType,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.location,
    this.cityId,
    this.cityName,
    this.districtId,
    this.districtName,
  });

  bool get hasActiveFilters {
    return selectedCategory != null ||
           minPrice != null ||
           maxPrice != null ||
           minRadius != null ||
           maxRadius != null ||
           (adType != null && adType != 'All') ||
           latitude != null ||
           cityId != null ||
           districtId != null;
  }

  SearchFilters copyWith({
    String? selectedCategory,
    double? minPrice,
    double? maxPrice,
    double? minRadius,
    double? maxRadius,
    String? adType,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? location,
    String? cityId,
    String? cityName,
    String? districtId,
    String? districtName,
  }) {
    return SearchFilters(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRadius: minRadius ?? this.minRadius,
      maxRadius: maxRadius ?? this.maxRadius,
      adType: adType ?? this.adType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      location: location ?? this.location,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
    );
  }

  // Convert to SavedSearchModel compatible format
  Map<String, dynamic> toSavedSearchData() {
    return {
      'selectedCategory': selectedCategory,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'adType': adType,
      'cityId': cityId,
      'cityName': cityName,
      'districtId': districtId,
      'districtName': districtName,
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'location': location,
    };
  }
}