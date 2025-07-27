
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/account/controller/favorite_provider.dart';
import 'package:arabicmarketplace/screens/notifications/view/notifications_page.dart';
import 'package:arabicmarketplace/screens/home/controller/home_provider.dart';
import 'package:arabicmarketplace/screens/home/view/all_categories_page.dart';
import 'package:arabicmarketplace/screens/home/view/location_selection_page.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_page.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:arabicmarketplace/widgets/image_optimise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// How to integrate the backend with your existing MarketplaceHomePage

class MarketplaceHomePage extends StatefulWidget {
  @override
  _MarketplaceHomePageState createState() => _MarketplaceHomePageState();
}

class _MarketplaceHomePageState extends State<MarketplaceHomePage> 
    with AutomaticKeepAliveClientMixin {
  
  // Keep alive to prevent rebuilding
  @override
  bool get wantKeepAlive => true;

  // Currency management - optimized with caching
  String _selectedCurrency = 'SYP';
  bool _isLoadingRates = false;
  Map<String, double> _exchangeRates = {
    'USD': 0.000077,
    'EUR': 0.000070,
    'SYP': 1.0,
  };

  // Cache for exchange rates
  static const String _ratesCacheKey = 'exchange_rates';
  static const String _ratesTimestampKey = 'rates_timestamp';
  static const Duration _ratesCacheDuration = Duration(hours: 6);

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'SYP', 'name': 'Syrian Pound', 'symbol': 'SYP', 'flag': '🇸🇾'},
  ];

  // Add debouncing for expensive operations
  Timer? _refreshTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePageData();
  }

  // OPTIMIZED: Initialize data with prioritized loading
  Future<void> _initializePageData() async {
    if (_isInitialized) return;
    
    // Load critical data first (currency preference)
    await _loadUserCurrencyPreference();
    
    // Load cached exchange rates immediately
    await _loadCachedRates();
    
    // Initialize home data in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHomeData();
    });
    
    _isInitialized = true;
  }

  // OPTIMIZED: Separate home data initialization
  Future<void> _initializeHomeData() async {
    final homeProvider = context.read<HomeProvider>();
    
    // Only refresh if data is stale or empty
    if (homeProvider.categories.isEmpty || 
        homeProvider.allProducts.isEmpty ||
        _shouldRefreshData(homeProvider)) {
      await homeProvider.refreshData();
    }
    
    // Load exchange rates in background (non-blocking)
    _loadExchangeRatesInBackground();
  }

  // OPTIMIZED: Check if data needs refreshing
  bool _shouldRefreshData(HomeProvider homeProvider) {
    // Add timestamp check logic here
    // For now, refresh every 30 minutes
    return false; // Implement your refresh logic
  }

  // OPTIMIZED: Load exchange rates in background
  Future<void> _loadExchangeRatesInBackground() async {
    if (await _areCachedRatesValid()) {
      return; // Use cached rates
    }
    
    // Load new rates without blocking UI
    _loadExchangeRates();
  }

  // OPTIMIZED: Check if cached rates are still valid
  Future<bool> _areCachedRatesValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_ratesTimestampKey);
      
      if (timestampStr == null) return false;
      
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      
      return now.difference(timestamp) < _ratesCacheDuration;
    } catch (e) {
      return false;
    }
  }

  // OPTIMIZED: Load currency preference (cached)
  Future<void> _loadUserCurrencyPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString('preferred_currency') ?? 'SYP';
      if (mounted) {
        setState(() {
          _selectedCurrency = savedCurrency;
        });
      }
    } catch (e) {
      print('Error loading currency preference: $e');
    }
  }

  // OPTIMIZED: Save currency preference
  Future<void> _saveCurrencyPreference(String currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_currency', currency);
    } catch (e) {
      print('Error saving currency preference: $e');
    }
  }

  // OPTIMIZED: Load exchange rates with better error handling
  Future<void> _loadExchangeRates() async {
    if (_isLoadingRates) return; // Prevent multiple requests
    
    setState(() {
      _isLoadingRates = true;
    });

    try {
      // Use timeout to prevent hanging
      await Future.any([
        _fetchExchangeRates(),
        Future.delayed(Duration(seconds: 10), () => throw TimeoutException('Timeout')),
      ]);
    } catch (e) {
      print('Error loading exchange rates: $e');
      // Keep using cached rates
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRates = false;
        });
      }
    }
  }

  // OPTIMIZED: Fetch exchange rates with single API call
  Future<void> _fetchExchangeRates() async {
    try {
      // Use a single API call for all rates
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/SYP'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        if (mounted) {
          setState(() {
            _exchangeRates = {
              'USD': (rates['USD'] as num?)?.toDouble() ?? 0.000077,
              'EUR': (rates['EUR'] as num?)?.toDouble() ?? 0.000070,
              'SYP': 1.0,
            };
          });
        }
        
        await _saveRatesToLocal();
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
      // Use fallback rates
      _useFallbackRates();
    }
  }

  // OPTIMIZED: Use fallback rates
  void _useFallbackRates() {
    setState(() {
      _exchangeRates = {
        'USD': 0.000077,
        'EUR': 0.000070,
        'SYP': 1.0,
      };
    });
  }

  // OPTIMIZED: Save rates with timestamp
  Future<void> _saveRatesToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ratesCacheKey, json.encode(_exchangeRates));
      await prefs.setString(_ratesTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving rates: $e');
    }
  }

  // OPTIMIZED: Load cached rates
  Future<void> _loadCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = prefs.getString(_ratesCacheKey);
      
      if (ratesJson != null) {
        final rates = Map<String, double>.from(json.decode(ratesJson));
        if (mounted) {
          setState(() {
            _exchangeRates = rates;
          });
        }
      }
    } catch (e) {
      print('Error loading cached rates: $e');
    }
  }

  // OPTIMIZED: Memoized price conversion
  final Map<String, String> _priceCache = {};
  
  String _convertPrice(dynamic price, {bool showSymbol = true}) {
    if (price == null) return 'Price not set';
    
    // Create cache key
    final cacheKey = '${price}_${_selectedCurrency}_$showSymbol';
    if (_priceCache.containsKey(cacheKey)) {
      return _priceCache[cacheKey]!;
    }
    
    try {
      final priceValue = price is num ? price.toDouble() : double.parse(price.toString());
      String result;
      
      if (_selectedCurrency == 'SYP') {
        final symbol = showSymbol ? 'SYP ' : '';
        result = '$symbol${priceValue.toStringAsFixed(0)}';
      } else {
        final rate = _exchangeRates[_selectedCurrency] ?? 1.0;
        final convertedAmount = priceValue * rate;
        final currency = _currencies.firstWhere((c) => c['code'] == _selectedCurrency);
        final symbol = showSymbol ? '${currency['symbol']} ' : '';
        
        result = '$symbol${convertedAmount >= 1 ? convertedAmount.toStringAsFixed(2) : convertedAmount.toStringAsFixed(4)}';
      }
      
      // Cache the result
      _priceCache[cacheKey] = result;
      
      // Limit cache size
      if (_priceCache.length > 100) {
        _priceCache.clear();
      }
      
      return result;
    } catch (e) {
      return 'Price not set';
    }
  }

  // OPTIMIZED: Debounced refresh
  Future<void> _debouncedRefresh() async {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(Duration(milliseconds: 500), () async {
      final homeProvider = context.read<HomeProvider>();
      await homeProvider.refreshData();
      await _loadExchangeRates();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
       backgroundColor:Theme.of(context).appBarTheme.backgroundColor ,
      body: SafeArea(
        child: Consumer<HomeProvider>(
          builder: (context, homeProvider, child) {
            // OPTIMIZED: Better loading states
            if (homeProvider.isLoading && homeProvider.categories.isEmpty) {
              return _buildShimmerLoading();
            }

            if (homeProvider.error != null && homeProvider.categories.isEmpty) {
              return _buildErrorState(homeProvider);
            }

            return RefreshIndicator(
              onRefresh: _debouncedRefresh,
              child: CustomScrollView(
                slivers: [
                  // OPTIMIZED: Use slivers for better performance
                  SliverToBoxAdapter(
                    child: _buildEnhancedHeader(context, homeProvider),
                  ),
                  
                  // Categories section
                  if (homeProvider.categories.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildCategoriesSection(homeProvider.categories),
                    ),
                  
                  // Content sections
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(height: 8),
                        
                        // OPTIMIZED: Only build sections with data
                        if (homeProvider.featuredProducts.isNotEmpty)
                          _buildFeaturedSection(homeProvider.featuredProducts),
                        
                        if (homeProvider.allProducts.isNotEmpty)
                          _buildRecentlyAddedSection(homeProvider.allProducts),
                        
                        if (homeProvider.personalizedProducts.isNotEmpty) ...[
                          SizedBox(height: 8),
                          _buildPersonalizedSection(homeProvider.personalizedProducts),
                        ],
                        
                        if (homeProvider.adBanners.isNotEmpty) ...[
                          SizedBox(height: 8),
                          _buildAdBannersSection(homeProvider.adBanners),
                        ],
                        
                        // Product sections
                        if (homeProvider.mostViewedProducts.isNotEmpty)
                          _buildProductSection(AppLocalizations.mostViewed.tr(), homeProvider.mostViewedProducts),
                        
                        if (homeProvider.mobilePhones.isNotEmpty)
                          _buildProductSection(AppLocalizations.mobiles.tr(), homeProvider.mobilePhones),
                        
                        if (homeProvider.computers.isNotEmpty)
                          _buildProductSection(AppLocalizations.computers.tr(), homeProvider.computers),
                        
                        if (homeProvider.computerAccessories.isNotEmpty)
                          _buildProductSection(AppLocalizations.computerAccessories.tr(), homeProvider.computerAccessories),
                        
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // OPTIMIZED: Shimmer loading
  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header shimmer
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 62,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(width: 9),
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(width: 9),
                    Container(
                      width: 80,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Categories shimmer
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 150,
                      height: 20,
                      color: Colors.grey[300],
                    ),
                    Container(
                      width: 60,
                      height: 20,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: List.generate(5, (index) => 
                    Container(
                      width: 70,
                      margin: EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: 60,
                            height: 12,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Product cards shimmer
          ...List.generate(3, (index) => 
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 120,
                        height: 20,
                        color: Colors.grey[300],
                      ),
                      Container(
                        width: 60,
                        height: 20,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // OPTIMIZED: Error state
  Widget _buildErrorState(HomeProvider homeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please try again',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => homeProvider.refreshData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsController.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Keep all your existing build methods but add RepaintBoundary for performance
 Widget _buildEnhancedHeader(BuildContext context, HomeProvider homeProvider) {
  return RepaintBoundary(
    child: Container(
      padding: EdgeInsets.all(6),
      child: Column(
        children: [
          // Your existing header code...
          Row(
            children: [
              Container(
                height: 70,
                width: 62,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset('assets/icons/home_logo.png', 
                  height: 70, width: 62, fit: BoxFit.fill),
              ),
              
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage()));
                  },
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          child: Icon(Icons.search, color: Colors.grey[600]),
                        ),
                        Expanded(
                          child: Text(
                            AppLocalizations.search.tr(),
                            style: GoogleFonts.jost(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 9),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage()));
                },
                child: Container(
                  height: 45,
                  width: 45,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!)
                  ),
                  child: SvgPicture.asset('assets/icons/Notification.svg',
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    height: 40, width: 40, fit: BoxFit.cover),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LocationsPage()));
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(Icons.location_on_outlined, color: Color(0xFF9CA3AF), size: 20),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.location.tr(),
                                  style: GoogleFonts.jost(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                Text(
                                  (homeProvider.userLocationAddress != null && homeProvider.userLocationAddress!.isNotEmpty)
                                    ? (_getCityName(homeProvider.userLocationAddress!) ?? '')
                                    : 'Location not set'.tr(),
                                  style: GoogleFonts.jost(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(Icons.keyboard_arrow_right, color: Color(0xFF9CA3AF), size: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 9),
              GestureDetector(
                onTap: _showCurrencySelector,
                child: Container(
                  height: 45,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // FIX: Use safe currency lookup with fallback
                      Text(
                        _getSafeCurrencyFlag(),
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(width: 4),
                      Text(
                        _selectedCurrency,
                        style: GoogleFonts.jost(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, 
                        size: 16, color: Colors.grey[600]),
                    ],
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
String _getSafeCurrencyFlag() {
  try {
    final currency = _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
      orElse: () => _currencies.first, // Fallback to first currency
    );
    return currency['flag'] ?? '🇸🇾';
  } catch (e) {
    print('Error getting currency flag: $e');
    return '🇸🇾'; // Default flag
  }
}


  // OPTIMIZED: Product card with RepaintBoundary
  Widget _buildProductCard(Map<String, dynamic> product) {
    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          context.read<HomeProvider>().incrementProductView(product['id'] ?? '');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product['id'] ?? '')
            )
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMPROVED: Image container with better quality
              Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: _buildProductImage(product),
                    ),
                    
                    // Currency indicator
                    if (_selectedCurrency != 'SYP')
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[700]!.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _selectedCurrency,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Favorite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, child) {
                          final productId = product['id'] ?? '';
                          final isFavorite = favoritesProvider.isFavorite(productId);
                          
                          return GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await favoritesProvider.toggleFavorite(productId);
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isFavorite ? Icons.heart_broken : Icons.favorite,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          isFavorite 
                                            ? 'Removed from favorites'.tr()
                                            : 'Added to favorites'.tr(),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: isFavorite ? Colors.orange : Colors.red,
                                    duration: Duration(milliseconds: 1500),
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Negotiable badge
                    if (product['allowPriceNegotiation'] == true)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.yellow[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Negotiable'.tr(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Product details (rest of the card remains the same)
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['itemTitle'] ?? 'Product Title'.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    
                    // Price with currency conversion
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _convertPrice(product['price']),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // Show original SYP price if converted
                        if (_selectedCurrency != 'SYP' && product['price'] != null)
                          Text(
                            'ل.س${(product['price'] as num).toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Text(
                          product['condition'] ?? 'Used'.tr(),
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Spacer(),
                        Text(
                          _getTimeSincePosted(product['createdAt']),
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['locationAddress'] ?? 'Location not set'.tr(),
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${product['viewCount'] ?? product['views'] ?? 0} ${'views'.tr()}',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // OPTIMIZED: Currency selector with better performance
  void _showCurrencySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Select Currency'.tr(),
                      style: GoogleFonts.jost(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Spacer(),
                    if (_isLoadingRates)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(ColorsController.primaryColor),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20),
                ..._currencies.map((currency) {
                  final isSelected = _selectedCurrency == currency['code'];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (mounted) {
                            setState(() {
                              _selectedCurrency = currency['code']!;
                              _priceCache.clear(); // Clear price cache
                            });
                          }
                          await _saveCurrencyPreference(currency['code']!);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? ColorsController.primaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected 
                                ? Border.all(color: ColorsController.primaryColor.withOpacity(0.3))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Text(
                                currency['flag']!,
                                style: TextStyle(fontSize: 24),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currency['name']!,
                                      style: GoogleFonts.jost(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected ? ColorsController.primaryColor : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '${currency['symbol']} (${currency['code']})',
                                      style: GoogleFonts.jost(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: ColorsController.primaryColor,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // OPTIMIZED: Categories section with lazy loading
  Widget _buildCategoriesSection(List<Map<String, dynamic>> categories) {
    return RepaintBoundary(
      child: Container(
        // color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.browseCategories.tr(), 
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,)
                ),
                InkWell(
                  onTap: _navigateToAllCategories,
                  child: Text(
                    AppLocalizations.seeAll.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: ColorsController.primaryColor,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: math.min(categories.length, 8), // Limit to 8 categories
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Container(
                    width: 70,
                    margin: EdgeInsets.only(right: 12),
                    child: _buildCategoryItem(
                      category['name'] ?? 'Category',
                      category['iconUrl'] ?? 'category',
                      _getColorFromHex(category['color'] ?? '#666666'),
                      onTap: () => _navigateToCategoryHierarchy(category),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // OPTIMIZED: Product section with better performance
  Widget _buildProductSection(String title, List<Map<String, dynamic>> products) {
    if (products.isEmpty) return SizedBox.shrink();
    
    return RepaintBoundary(
      child: Container(
        // color: Colors.white,
        margin: EdgeInsets.only(top: 8),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,)),
                InkWell(
                  onTap: () => _navigateToProductList(title, products),
                  child: Text(
                    AppLocalizations.seeAll.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: ColorsController.primaryColor,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                if (products.isNotEmpty)
                  Expanded(child: _buildProductCard(products[0])),
                if (products.length > 1) ...[
                  SizedBox(width: 12),
                  Expanded(child: _buildProductCard(products[1])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // OPTIMIZED: Recently added section
  Widget _buildRecentlyAddedSection(List<Map<String, dynamic>> allProducts) {
    if (allProducts.isEmpty) return SizedBox.shrink();
    
    // Use a more efficient sorting approach
    final recentProducts = allProducts.take(20).toList(); // Limit processing
    recentProducts.sort((a, b) {
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
    
    final recentlyAdded = recentProducts.take(2).toList();
    
    return RepaintBoundary(
      child: Container(
        // color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recently Added'.tr(),
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,),
                ),
                InkWell(
                  onTap: () => _navigateToProductList('Recently Added', recentlyAdded),
                  child: Text(
                    AppLocalizations.seeAll.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: ColorsController.primaryColor,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                if (recentlyAdded.isNotEmpty)
                  Expanded(child: _buildProductCard(recentlyAdded[0])),
                if (recentlyAdded.length > 1) ...[
                  SizedBox(width: 12),
                  Expanded(child: _buildProductCard(recentlyAdded[1])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // OPTIMIZED: Featured section
  Widget _buildFeaturedSection(List<Map<String, dynamic>> featuredProducts) {
    if (featuredProducts.isEmpty) return SizedBox.shrink();
    
    return RepaintBoundary(
      child: Container(
        // color: Colors.white,
        // color: ColorsController.darkBackground,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.featured.tr(), 
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)
                ),
                InkWell(
                  onTap: () => _navigateToProductList(AppLocalizations.featured.tr(), featuredProducts),
                  child: Text(
                    AppLocalizations.seeAll.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: ColorsController.primaryColor,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                if (featuredProducts.isNotEmpty)
                  Expanded(child: _buildProductCard(featuredProducts[0])),
                if (featuredProducts.length > 1) ...[
                  SizedBox(width: 12),
                  Expanded(child: _buildProductCard(featuredProducts[1])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // OPTIMIZED: Personalized section
  Widget _buildPersonalizedSection(List<Map<String, dynamic>> personalizedProducts) {
    if (personalizedProducts.isEmpty) return SizedBox.shrink();
    
    return RepaintBoundary(
      child: Container(
        // color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.personalized.tr(), 
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)
                ),
                InkWell(
                  onTap: () => _navigateToProductList(AppLocalizations.personalized.tr(), personalizedProducts),
                  child: Text(
                    AppLocalizations.seeAll.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: ColorsController.primaryColor,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                if (personalizedProducts.isNotEmpty)
                  Expanded(child: _buildProductCard(personalizedProducts[0])),
                if (personalizedProducts.length > 1) ...[
                  SizedBox(width: 12),
                  Expanded(child: _buildProductCard(personalizedProducts[1])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // OPTIMIZED: Ad banners section
Widget _buildAdBannersSection(List<Map<String, dynamic>> banners) {
    if (banners.isEmpty) return SizedBox.shrink();

    return RepaintBoundary(
      child: Container(
        height: 180,
        margin: EdgeInsets.symmetric(vertical: 8),
        child: PageView.builder(
          itemCount: banners.length,
          itemBuilder: (context, index) {
            final banner = banners[index];
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _handleBannerTap(banner),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: UniversalImage(
                          imageUrl: banner['imageUrl'] ?? '',
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          highQuality: true, // High quality for banners
                          errorWidget: Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: [0.3, 1.0],
                            ),
                          ),
                        ),
                      ),
                      
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (banner['title'] != null && banner['title'].toString().isNotEmpty)
                              Text(
                                banner['title'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            
                            if (banner['title'] != null && 
                                banner['title'].toString().isNotEmpty &&
                                banner['description'] != null && 
                                banner['description'].toString().isNotEmpty)
                              SizedBox(height: 4),
                            
                            if (banner['description'] != null && banner['description'].toString().isNotEmpty)
                              Text(
                                banner['description'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // OPTIMIZED: Category item with RepaintBoundary
  Widget _buildCategoryItem(String title, String icon, Color color, {VoidCallback? onTap}) {
    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: UniversalImage(
                  imageUrl: icon,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  highQuality: true, // High quality for category icons
                  borderRadius: BorderRadius.circular(25),
                  errorWidget: Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.category, size: 30, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 32,
              child: Text(
                title.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10, 
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // OPTIMIZED: Product image with better caching
   Widget _buildProductImage(Map<String, dynamic> product) {
    final imageUrls = product['imageUrls'] as List<dynamic>?;
  
  if (imageUrls != null && imageUrls.isNotEmpty) {
    return WatermarkPreservingImage(
      imageUrl: imageUrls.first.toString(),
      width: double.infinity,
      height: 170,
      fit: BoxFit.cover, // Now you can use cover without losing watermark
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      preserveWatermark: true,
    );
  } else {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
    );
  }
 
  }

  // Helper methods (keep unchanged)
  void _navigateToAllCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AllCategoriesPage()),
    );
  }

  void _navigateToCategoryHierarchy(Map<String, dynamic> category) {
    final categoryId = category['id'] ?? '';
    final categoryName = category['name'] ?? '';
    final level = category['level'] ?? 0;

    if (level == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubCategoriesPage(
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        ),
      );
    } else if (level == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubSubCategoriesPage(
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryProductsPage(
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        ),
      );
    }
  }

  void _navigateToProductList(String title, List<Map<String, dynamic>> products) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListPage(
          title: title,
          products: products,
        ),
      ),
    );
  }

  void _handleBannerTap(Map<String, dynamic> banner) {
    final targetType = banner['targetType'];
    final targetId = banner['targetId'];
    final linkUrl = banner['linkUrl'];
    
    switch (targetType) {
      case 'category':
        if (targetId != null) {
          _navigateToCategoryHierarchy({
            'id': targetId, 
            'name': banner['title'] ?? 'Category', 
            'level': 0
          });
        }
        break;
      case 'product':
        if (targetId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: targetId),
            ),
          );
        }
        break;
      case 'external':
        if (linkUrl != null) {
          // Use url_launcher package to open external URL
          // launch(linkUrl);
        }
        break;
    }
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  String? _getCityName(String? locationAddress) {
    if (locationAddress == null || locationAddress.isEmpty) return null;
    
    List<String> parts = locationAddress.split(',');
    if (parts.isNotEmpty) {
      return parts[0].trim();
    }
    return locationAddress;
  }

  String _getTimeSincePosted(dynamic createdAt) {
    if (createdAt == null) return 'Recently'.tr();
    
    try {
      DateTime postDate;
      if (createdAt is Timestamp) {
        postDate = createdAt.toDate();
      } else if (createdAt is DateTime) {
        postDate = createdAt;
      } else {
        return 'Recently'.tr();
      }
      
      final now = DateTime.now();
      final difference = now.difference(postDate);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now'.tr();
      }
    } catch (e) {
      return 'Recently'.tr();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}