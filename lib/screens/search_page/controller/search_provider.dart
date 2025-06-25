// providers/search_provider.dart
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';

// Add this import at the top
import 'dart:math' as math;
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
  
  // Filters
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

  // Main search function
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

  // Search products with filters
  Future<List<ProductModel>> _searchProducts() async {
    try {
      Query query = _firestore
          .collection('items')
          .where('status', isEqualTo: 'active');

      // Apply text search - search in multiple fields
      final searchTerms = _searchQuery.toLowerCase().split(' ');
      
      // For now, we'll use basic field searching
      // In production, consider using Algolia or ElasticSearch for better full-text search
      
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
      
      // Apply location filter if specified
      if (_filters.latitude != null && _filters.longitude != null && _filters.radiusKm != null) {
        // Note: Firestore doesn't support radius queries natively
        // You might want to use a geohashing library or filter results after fetching
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
        final searchableText = '${product.title} ${product.description} ${product.brand} ${product.category} ${product.color}'.toLowerCase();
        return searchTerms.any((term) => searchableText.contains(term));
      }).toList();
      
      // Apply location filter if needed (post-query filtering)
      if (_filters.latitude != null && _filters.longitude != null && _filters.radiusKm != null) {
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
              category.name?.toLowerCase().contains(_searchQuery.toLowerCase()) == true)
          .toList();
      
      return categories;
      
    } catch (e) {
      log('Error searching categories: $e');
      return [];
    }
  }

  // Filter products by location
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

  // Generate search suggestions
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

  // Persistence for recent searches (you can use SharedPreferences)
  void _loadRecentSearches() {
    // TODO: Load from SharedPreferences
    // For now, using mock data
    _recentSearches = ['iPhone 12 pro max', 'Samsung Galaxy', 'MacBook'];
  }

  void _saveRecentSearches() {
    // TODO: Save to SharedPreferences
  }

  // Filter management
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

// Search filters model
class SearchFilters {
  final String? selectedCategory;
  final double? minPrice;
  final double? maxPrice;
  final double? minRadius;
  final double? maxRadius;
  final String? adType; // 'Individual', 'Company', 'All'
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final String? location;

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
  });

  bool get hasActiveFilters {
    return selectedCategory != null ||
           minPrice != null ||
           maxPrice != null ||
           minRadius != null ||
           maxRadius != null ||
           (adType != null && adType != 'All') ||
           latitude != null;
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
    );
  }
}
