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

// FIXED: Enhanced SearchProvider with flexible location matching
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
  
  // Filters with enhanced location and category support
  SearchFilters _filters = SearchFilters();
  
  // Debounce timer for search
  Timer? _debounceTimer;
  
  // Constants
  static const int searchResultsLimit = 50;
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

  // Perform immediate search
  Future<void> performImmediateSearch([String? query]) async {
    print('🔍 performImmediateSearch called with query: "$query"');
    print('🔍 Current filters: ${_filters.selectedCategory}, ${_filters.cityId}, ${_filters.minPrice}-${_filters.maxPrice}');
    
    _debounceTimer?.cancel();
    if (query != null) {
      _searchQuery = query.trim();
    }
    
    print('🔍 Final search query: "$_searchQuery"');
    print('🔍 Has filters: ${_filters.hasActiveFilters}');
    
    // Always perform search, even with empty query if we have filters
    await _performSearch();
    
    if (_searchQuery.isNotEmpty) {
      _addToRecentSearches(_searchQuery);
    }
  }

  // FIXED: Main search function with flexible location handling
  Future<void> _performSearch() async {
    print('🚀 _performSearch started');
    print('🚀 Search query: "$_searchQuery"');
    print('🚀 Has active filters: ${_filters.hasActiveFilters}');
    
    // Don't skip search if we have filters but no query
    if (_searchQuery.isEmpty && !_filters.hasActiveFilters) {
      print('❌ Skipping search - no query and no filters');
      return;
    }
    
    try {
      _setSearching(true);
      _setError(null);
      
      print('🎯 Starting enhanced product search...');
      
      // FIXED: Use flexible search strategy
      final products = await _searchProductsFlexible();
      
      // Search categories only if we have a text query
      final categories = _searchQuery.isNotEmpty ? await _searchCategories() : <CategoryModel>[];
      
      _searchResults = products;
      _categoryResults = categories;
      
      print('✅ Search completed:');
      print('✅ - Products found: ${_searchResults.length}');
      print('✅ - Categories found: ${_categoryResults.length}');
      
      _setSearching(false);
      notifyListeners();
      
    } catch (e) {
      print('❌ Search error: $e');
      _setError('Search failed: ${e.toString()}');
      _setSearching(false);
      log('Search error: $e');
    }
  }

  // FIXED: Flexible search strategy that handles missing location data
  Future<List<ProductModel>> _searchProductsFlexible() async {
    try {
      print('🎯 Starting flexible product search...');
      print('🎯 Filters: Category=${_filters.selectedCategory}, City=${_filters.cityId}, District=${_filters.districtId}');
      
      List<ProductModel> results = [];
      
      // Strategy 1: Try category-based search first (most reliable)
      if (_filters.selectedCategory != null && _filters.selectedCategory!.isNotEmpty) {
        print('📂 Trying category-based search...');
        results = await _searchByCategory();
        print('📂 Category search found: ${results.length} products');
      }
      
      // Strategy 2: If no results or no category filter, try general search
      if (results.isEmpty) {
        print('🔤 Trying general search...');
        results = await _searchAllProducts();
        print('🔤 General search found: ${results.length} products');
      }
      
      // Apply all filters in memory (this is more flexible)
      results = _applyFlexibleFilters(results);
      
      print('✅ Final results after flexible filtering: ${results.length} products');
      return results;
      
    } catch (e) {
      print('❌ Error in flexible product search: $e');
      return [];
    }
  }

  // Search by category (reliable anchor point)
  Future<List<ProductModel>> _searchByCategory() async {
    try {
      print('📂 Searching by category: ${_filters.selectedCategory}');
      
      Query query = _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .where('category', isEqualTo: _filters.selectedCategory);

      query = query.orderBy('createdAt', descending: true).limit(searchResultsLimit * 2);
      
      final snapshot = await query.get();
      print('📂 Firestore returned: ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        print('❌ No products found for category: ${_filters.selectedCategory}');
        return [];
      }

      List<ProductModel> products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
      
      print('📂 Converted to ${products.length} products');
      return products;
      
    } catch (e) {
      print('❌ Error in category-based search: $e');
      return [];
    }
  }

  // Search all products (fallback)
  Future<List<ProductModel>> _searchAllProducts() async {
    try {
      print('🔤 Searching all active products...');
      
      Query query = _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(searchResultsLimit * 2);
      
      final snapshot = await query.get();
      print('🔤 Firestore returned: ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        return [];
      }

      List<ProductModel> products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
      
      print('🔤 Converted to ${products.length} products');
      return products;
      
    } catch (e) {
      print('❌ Error in general search: $e');
      return [];
    }
  }

  // FIXED: Flexible filtering that handles missing location data
  List<ProductModel> _applyFlexibleFilters(List<ProductModel> products) {
    print('🧹 Applying flexible filters to ${products.length} products');
    
    // Text search filtering
    if (_searchQuery.isNotEmpty) {
      print('🔍 Applying text search: "$_searchQuery"');
      final searchTerms = _searchQuery.toLowerCase().split(' ');
      products = products.where((product) {
        final searchableText = '${product.title ?? ''} ${product.description ?? ''} ${product.brand ?? ''} ${product.categoryName ?? ''} ${product.color ?? ''}'.toLowerCase();
        return searchTerms.any((term) => searchableText.contains(term));
      }).toList();
      print('🔍 After text search: ${products.length} products');
    }

    // FIXED: Flexible location filtering
    if (_filters.cityId != null || _filters.districtId != null || _filters.cityName != null) {
      print('🌍 Applying flexible location filter...');
      products = _applyFlexibleLocationFilter(products);
      print('🌍 After location filter: ${products.length} products');
    }

    // Price range filtering
    if (_filters.minPrice != null && _filters.minPrice! > 0) {
      print('💰 Applying min price filter: ${_filters.minPrice}');
      products = products.where((product) {
        return product.price != null && product.price! >= _filters.minPrice!;
      }).toList();
      print('💰 After min price filter: ${products.length} products');
    }

    if (_filters.maxPrice != null && _filters.maxPrice! > 0 && _filters.maxPrice! < 1000000) {
      print('💰 Applying max price filter: ${_filters.maxPrice}');
      products = products.where((product) {
        return product.price != null && product.price! <= _filters.maxPrice!;
      }).toList();
      print('💰 After max price filter: ${products.length} products');
    }

    // Ad type filtering
    if (_filters.adType != null && _filters.adType != 'All') {
      print('👤 Applying ad type filter: ${_filters.adType}');
      final sellerType = _filters.adType == 'Individual' ? 'individual' : 'company';
      products = products.where((product) {
        return product.sellerType == sellerType;
      }).toList();
      print('👤 After ad type filter: ${products.length} products');
    }

    // FIXED: Category-specific filters with better field matching
    if (_filters.categorySpecificFilters != null && _filters.categorySpecificFilters!.isNotEmpty) {
      print('🎯 Applying category-specific filters: ${_filters.categorySpecificFilters}');
      products = _applyCategorySpecificFiltersEnhanced(products, _filters.categorySpecificFilters!);
      print('🎯 After category-specific filters: ${products.length} products');
    }

    print('✅ Final filtered results: ${products.length} products');
    return products;
  }

  // FIXED: Flexible location filter that handles missing IDs
  List<ProductModel> _applyFlexibleLocationFilter(List<ProductModel> products) {
    print('🌍 Starting flexible location filtering...');
    print('🌍 Target - City: ${_filters.cityName} (${_filters.cityId}), District: ${_filters.districtName} (${_filters.districtId})');
    
    return products.where((product) {
      print('🌍 Checking product: ${product.title}');
      print('🌍 Product location - cityId: ${product.cityId}, districtId: ${product.districtId}');
      print('🌍 Product location - address: ${product.locationAddress}');
      
      // Method 1: Exact ID matching (preferred)
      if (product.cityId != null && _filters.cityId != null) {
        bool cityMatch = product.cityId == _filters.cityId;
        bool districtMatch = true; // Default to true if no district filter
        
        if (_filters.districtId != null && product.districtId != null) {
          districtMatch = product.districtId == _filters.districtId;
        }
        
        bool exactMatch = cityMatch && districtMatch;
        print('🌍 Exact ID match: city=$cityMatch, district=$districtMatch, overall=$exactMatch');
        
        if (exactMatch) {
          print('✅ Product matches by exact IDs');
          return true;
        }
      }
      
      // Method 2: Fallback to text-based location matching
      if (product.locationAddress != null && product.locationAddress!.isNotEmpty) {
        String productLocation = product.locationAddress!.toLowerCase();
        
        bool cityNameMatch = _filters.cityName != null && 
                           productLocation.contains(_filters.cityName!.toLowerCase());
        
        bool districtNameMatch = _filters.districtName != null && 
                               productLocation.contains(_filters.districtName!.toLowerCase());
        
        // If we have both city and district filters, both should match
        // If we only have city filter, only city should match
        bool textMatch = false;
        if (_filters.districtName != null && _filters.cityName != null) {
          textMatch = cityNameMatch && districtNameMatch;
        } else if (_filters.cityName != null) {
          textMatch = cityNameMatch;
        }
        
        print('🌍 Text-based match: city=$cityNameMatch, district=$districtNameMatch, overall=$textMatch');
        
        if (textMatch) {
          print('✅ Product matches by text location');
          return true;
        }
      }
      
      print('❌ Product does not match location filters');
      return false;
      
    }).toList();
  }

  // ENHANCED: Better category-specific filter matching
  List<ProductModel> _applyCategorySpecificFiltersEnhanced(
    List<ProductModel> products, 
    Map<String, dynamic> categoryFilters
  ) {
    print('🎯 Enhanced category filtering with ${categoryFilters.length} filters');
    
    return products.where((product) {
      print('🎯 Checking product: ${product.title}');
      print('🎯 Product categorySpecificFields: ${product.categorySpecificFields}');
      
      for (final entry in categoryFilters.entries) {
        final filterKey = entry.key;
        final filterValue = entry.value;
        
        print('🎯 Checking filter: $filterKey = $filterValue');
        
        // Check in categorySpecificFields
        dynamic productValue = product.categorySpecificFields?[filterKey];
        
        print('🎯 Product value found: $productValue');
        
        // Handle different value types and comparisons
        if (!_matchesFilterValue(productValue, filterValue, filterKey)) {
          print('🎯 Product ${product.title} filtered out by $filterKey');
          return false;
        }
      }
      
      print('🎯 Product ${product.title} passed all category filters');
      return true;
    }).toList();
  }

  // Helper method to match filter values with better type handling
  bool _matchesFilterValue(dynamic productValue, dynamic filterValue, String filterKey) {
    if (productValue == null) {
      print('🎯 Product value is null for filter $filterKey');
      return false;
    }
    
    // Handle range filters (min/max)
    if (filterKey.contains('_min')) {
      final numValue = _toNumber(productValue);
      final filterNum = _toNumber(filterValue);
      bool result = numValue != null && filterNum != null && numValue >= filterNum;
      print('🎯 Range min check: $numValue >= $filterNum = $result');
      return result;
    }
    
    if (filterKey.contains('_max')) {
      final numValue = _toNumber(productValue);
      final filterNum = _toNumber(filterValue);
      bool result = numValue != null && filterNum != null && numValue <= filterNum;
      print('🎯 Range max check: $numValue <= $filterNum = $result');
      return result;
    }
    
    // Handle boolean values
    if (filterValue is bool) {
      bool result = productValue == filterValue;
      print('🎯 Boolean check: $productValue == $filterValue = $result');
      return result;
    }
    
    // Handle string comparisons (case-insensitive)
    bool result = productValue.toString().toLowerCase() == filterValue.toString().toLowerCase();
    print('🎯 String check: "${productValue.toString().toLowerCase()}" == "${filterValue.toString().toLowerCase()}" = $result');
    return result;
  }

  // Helper to convert values to numbers
  double? _toNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Search categories (unchanged)
  Future<List<CategoryModel>> _searchCategories() async {
    try {
      if (_searchQuery.isEmpty) {
        return [];
      }
      
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

  // Enhanced filter management
  void updateFilters(SearchFilters newFilters) {
    print('🔧 updateFilters called:');
    print('🔧 - Category: ${newFilters.selectedCategory}');
    print('🔧 - Price range: ${newFilters.minPrice} - ${newFilters.maxPrice}');
    print('🔧 - Location: ${newFilters.cityName} (${newFilters.cityId})');
    print('🔧 - District: ${newFilters.districtName} (${newFilters.districtId})');
    print('🔧 - Coordinates: ${newFilters.latitude}, ${newFilters.longitude}');
    print('🔧 - Category specific: ${newFilters.categorySpecificFilters}');
    
    _filters = newFilters;
    notifyListeners();
    
    print('🔧 Filters updated successfully');
  }

  void clearFilters() {
    _filters = SearchFilters();
    notifyListeners();
    
    // Re-search without filters
    if (_searchQuery.isNotEmpty) {
      _performSearch();
    }
  }

  // Rest of the methods remain the same...
  Future<void> _generateSearchSuggestions() async {
    try {
      final categoriesSnapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .limit(5)
          .get();
      
      final suggestions = categoriesSnapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();
      
      _searchSuggestions = suggestions.take(8).toList();
      notifyListeners();
      
    } catch (e) {
      log('Error generating suggestions: $e');
    }
  }

  void _addToRecentSearches(String query) {
    if (query.isEmpty) return;
    
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    
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
        parts.add('\$${_filters.minPrice!.toStringAsFixed(0)} - \$${_filters.maxPrice!.toStringAsFixed(0)}');
      } else if (_filters.minPrice != null) {
        parts.add('above \$${_filters.minPrice!.toStringAsFixed(0)}');
      } else if (_filters.maxPrice != null) {
        parts.add('below \$${_filters.maxPrice!.toStringAsFixed(0)}');
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

  void _loadRecentSearches() {
    _recentSearches = ['iPhone 12 pro max', 'Samsung Galaxy', 'MacBook'];
  }

  void _saveRecentSearches() {
    // TODO: Save to SharedPreferences
  }

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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Enhanced SearchFilters class (unchanged from previous version)
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
  final Map<String, dynamic>? categorySpecificFilters;

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
    this.categorySpecificFilters,
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
           districtId != null ||
           (categorySpecificFilters != null && categorySpecificFilters!.isNotEmpty);
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
    Map<String, dynamic>? categorySpecificFilters,
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
      categorySpecificFilters: categorySpecificFilters ?? this.categorySpecificFilters,
    );
  }

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
      'categorySpecificFilters': categorySpecificFilters,
    };
  }

  factory SearchFilters.fromMap(Map<String, dynamic> map) {
    return SearchFilters(
      selectedCategory: map['selectedCategory'],
      minPrice: map['minPrice']?.toDouble(),
      maxPrice: map['maxPrice']?.toDouble(),
      minRadius: map['minRadius']?.toDouble(),
      maxRadius: map['maxRadius']?.toDouble(),
      adType: map['adType'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      radiusKm: map['radiusKm']?.toDouble(),
      location: map['location'],
      cityId: map['cityId'],
      cityName: map['cityName'],
      districtId: map['districtId'],
      districtName: map['districtName'],
      categorySpecificFilters: map['categorySpecificFilters'] != null 
          ? Map<String, dynamic>.from(map['categorySpecificFilters'])
          : null,
    );
  }
}