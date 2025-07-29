
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
// Complete MarketplaceHomePage with SYP as default currency - NO CACHING, REAL-TIME RATES
// Add this import: import 'package:flutter/foundation.dart'; // for kDebugMode

class MarketplaceHomePage extends StatefulWidget {
  @override
  _MarketplaceHomePageState createState() => _MarketplaceHomePageState();
}

class _MarketplaceHomePageState extends State<MarketplaceHomePage> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  // FIXED: SYP as default currency (prices stored in SYP)
  String _selectedCurrency = 'SYP';
  bool _isLoadingRates = false;
  
  // FIXED: SYP-based exchange rates (SYP as base currency) - NO CACHING
  Map<String, double> _exchangeRates = {
    'SYP': 1.0,        // Base currency (prices stored in SYP)
    'USD': 0.0000775,  // 1 SYP = 0.0000775 USD (fallback)
    'EUR': 0.0000659,  // 1 SYP = 0.0000659 EUR (fallback)
  };

  bool _shouldRefreshData(HomeProvider homeProvider) {
    return false; // Implement your refresh logic
  }

  final List<Map<String, String>> _currencies = [
    {'code': 'SYP', 'name': 'Syrian Pound', 'symbol': 'SYP', 'flag': '🇸🇾'}, // SYP first
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
  ];

  Timer? _refreshTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    print('🟢 MARKETPLACE HOME - SYP Base Currency');
    _initializePageData();
  }

  Future<void> _initializePageData() async {
    if (_isInitialized) return;
    
    await _loadUserCurrencyPreference();
    
    // Always fetch fresh exchange rates - NO CACHING
    await _loadExchangeRates();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHomeData();
    });
    
    _isInitialized = true;
  }

  Future<void> _initializeHomeData() async {
    final homeProvider = context.read<HomeProvider>();
    
    if (homeProvider.categories.isEmpty || 
        homeProvider.allProducts.isEmpty ||
        _shouldRefreshData(homeProvider)) {
      await homeProvider.refreshData();
    }
  }

  // FIXED: Load currency preference with SYP as default
  Future<void> _loadUserCurrencyPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString('preferred_currency') ?? 'SYP'; // Default to SYP
      if (mounted) {
        setState(() {
          _selectedCurrency = savedCurrency;
        });
      }
    } catch (e) {
      print('Error loading currency preference: $e');
    }
  }

  Future<void> _saveCurrencyPreference(String currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_currency', currency);
    } catch (e) {
      print('Error saving currency preference: $e');
    }
  }

  Future<void> _loadExchangeRates() async {
    if (_isLoadingRates) return;
    
    setState(() {
      _isLoadingRates = true;
    });

    try {
      print('🌐 Loading exchange rates...');
      await Future.any([
        _fetchExchangeRates(),
        Future.delayed(Duration(seconds: 10), () => throw TimeoutException('Timeout')),
      ]);
    } catch (e) {
      print('❌ Error loading exchange rates: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRates = false;
        });
      }
    }
  }

  // FIXED: Fetch exchange rates with SYP to other currencies conversion - NO CACHING
  Future<void> _fetchExchangeRates() async {
    try {
      print('🌐 Fetching FRESH exchange rates...');
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 8));
      
      print('📡 API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        final usdToSyp = (rates['SYP'] as num?)?.toDouble() ?? 12904.0;
        final usdToEur = (rates['EUR'] as num?)?.toDouble() ?? 0.851;
        
        print('🔄 Raw API rates: 1 USD = $usdToSyp SYP, 1 USD = $usdToEur EUR');
        
        if (mounted) {
          setState(() {
            // FIXED: SYP as base (1 SYP = X other currency)
            _exchangeRates = {
              'SYP': 1.0,                           // Base currency
              'USD': 1.0 / usdToSyp,               // 1 SYP = (1/12904) USD
              'EUR': usdToEur / usdToSyp,          // 1 SYP = (EUR_rate/SYP_rate) EUR
            };
          });
          
          print('✅ REAL-TIME SYP-based rates updated:');
          print('   SYP: ${_exchangeRates['SYP']} (base)');
          print('   USD: ${_exchangeRates['USD']} (1 SYP = ${_exchangeRates['USD']} USD)');
          print('   EUR: ${_exchangeRates['EUR']} (1 SYP = ${_exchangeRates['EUR']} EUR)');
          
          // Test conversion example
          final testSyp = 5000.0;
          final testUsd = testSyp * _exchangeRates['USD']!;
          final testEur = testSyp * _exchangeRates['EUR']!;
          print('💰 TEST: SYP $testSyp = \${testUsd.toStringAsFixed(2)} USD = €${testEur.toStringAsFixed(2)} EUR');
        }
      }
    } catch (e) {
      print('❌ Error fetching exchange rates: $e');
      _useFallbackRates();
    }
  }

  void _useFallbackRates() {
    setState(() {
      _exchangeRates = {
        'SYP': 1.0,        // Base currency
        'USD': 0.0000775,  // 1 SYP = 0.0000775 USD (approx 1 USD = 12,904 SYP)
        'EUR': 0.0000659,  // 1 SYP = 0.0000659 EUR (approx 1 EUR = 15,174 SYP)
      };
    });
    print('⚠️ Using FALLBACK SYP-based rates:');
    print('   SYP: ${_exchangeRates['SYP']} (base)');
    print('   USD: ${_exchangeRates['USD']} (1 SYP = ${_exchangeRates['USD']} USD)');
    print('   EUR: ${_exchangeRates['EUR']} (1 SYP = ${_exchangeRates['EUR']} EUR)');
    
    // Test conversion example
    final testSyp = 5000.0;
    final testUsd = testSyp * _exchangeRates['USD']!;
    final testEur = testSyp * _exchangeRates['EUR']!;
    print('💰 FALLBACK TEST: SYP $testSyp = \${testUsd.toStringAsFixed(2)} USD = €${testEur.toStringAsFixed(2)} EUR');
  }

  // FIXED: Price conversion with SYP as stored currency - NO CACHING
  String _convertPrice(dynamic price, {bool showSymbol = true}) {
    if (price == null) return 'Price not set';
    
    try {
      // Price is stored in SYP in database
      final priceInSyp = price is num ? price.toDouble() : double.parse(price.toString());
      String result;
      
      if (_selectedCurrency == 'SYP') {
        // Display in SYP (original stored currency)
        final symbol = showSymbol ? 'SYP ' : '';
        result = '$symbol${priceInSyp.toStringAsFixed(0)}'; // No decimals for SYP
        print('💱 Price display (SYP): $priceInSyp SYP → $result');
      } else {
        // Convert from SYP to selected currency
        final rate = _exchangeRates[_selectedCurrency] ?? 1.0;
        final convertedAmount = priceInSyp * rate; // Multiply SYP price by rate
        final currency = _currencies.firstWhere((c) => c['code'] == _selectedCurrency);
        final symbol = showSymbol ? '${currency['symbol']} ' : '';
        
        final decimals = 2; // USD and EUR use 2 decimals
        result = '$symbol${convertedAmount.toStringAsFixed(decimals)}';
        
        print('💱 Price conversion: $priceInSyp SYP × $rate = $convertedAmount $_selectedCurrency → $result');
      }
      
      return result;
    } catch (e) {
      print('❌ Price conversion error: $e');
      return 'Price not set';
    }
  }

  Future<void> _debouncedRefresh() async {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(Duration(milliseconds: 500), () async {
      final homeProvider = context.read<HomeProvider>();
      await homeProvider.refreshData();
      await _loadExchangeRates();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _getCurrencySymbol(String currencyCode) {
    final currency = _currencies.firstWhere(
      (c) => c['code'] == currencyCode,
      orElse: () => {'symbol': currencyCode},
    );
    return currency['symbol'] ?? currencyCode;
  }

  // FIXED: Get formatted price with SYP as base
  String _getFormattedPrice(dynamic price, {String? currency}) {
    currency ??= _selectedCurrency;
    
    if (price == null || price == 0) return 'Free';
    
    try {
      // Price stored in SYP
      final priceInSyp = price is num ? price.toDouble() : double.parse(price.toString());
      
      if (currency == 'SYP') {
        // Display original SYP price
        return 'SYP ${priceInSyp.toStringAsFixed(0)}';
      } else {
        // Convert from SYP to target currency
        final rate = _exchangeRates[currency] ?? 1.0;
        final convertedAmount = priceInSyp * rate;
        final symbol = _getCurrencySymbol(currency);
        final decimals = 2; // USD/EUR use 2 decimals
        
        return '$symbol${convertedAmount.toStringAsFixed(decimals)}';
      }
    } catch (e) {
      return 'Price error';
    }
  }

  Future<void> _switchCurrency(String newCurrency) async {
    if (newCurrency == _selectedCurrency) return;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Switching to $newCurrency...'),
            ],
          ),
          duration: Duration(milliseconds: 800),
          backgroundColor: ColorsController.primaryColor,
        ),
      );
    }

    setState(() {
      _selectedCurrency = newCurrency;
    });
    
    await _saveCurrencyPreference(newCurrency);
    print('💰 Currency switched to: $newCurrency');
    
    // Always fetch fresh rates when switching currency - NO CACHING
    if (newCurrency != 'SYP') {
      await _loadExchangeRates();
    }
  }

  bool _isValidPrice(dynamic price) {
    if (price == null) return false;
    
    try {
      final priceValue = price is num ? price.toDouble() : double.parse(price.toString());
      return priceValue >= 0;
    } catch (e) {
      return false;
    }
  }

  String _getSafeCurrencyFlag() {
    try {
      final currency = _currencies.firstWhere(
        (c) => c['code'] == _selectedCurrency,
        orElse: () => _currencies.firstWhere((c) => c['code'] == 'SYP'),
      );
      return currency['flag'] ?? '🇸🇾';
    } catch (e) {
      print('Error getting currency flag: $e');
      return '🇸🇾';
    }
  }

  bool get isUsingConvertedCurrency => _selectedCurrency != 'SYP';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<HomeProvider>(
          builder: (context, homeProvider, child) {
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
                  SliverToBoxAdapter(
                    child: _buildEnhancedHeader(context, homeProvider),
                  ),
                  
                  if (homeProvider.categories.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildCategoriesSection(homeProvider.categories),
                    ),
                  
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(height: 8),
                        
                        if (homeProvider.mostViewedProducts.isNotEmpty)
                          _buildProductSection("Most Viewed".tr(), homeProvider.mostViewedProducts),
                        
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
                        
                        if (homeProvider.mobilePhones.isNotEmpty)
                          _buildProductSection("Mobiles".tr(), homeProvider.mobilePhones),
                        
                        if (homeProvider.computers.isNotEmpty)
                          _buildProductSection("Computers".tr(), homeProvider.computers),
                        
                        if (homeProvider.computerAccessories.isNotEmpty)
                          _buildProductSection("Computer Accessories".tr(), homeProvider.computerAccessories),
                        
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

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
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

  Widget _buildEnhancedHeader(BuildContext context, HomeProvider homeProvider) {
    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.all(6),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 80,
                  width: 75,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset('assets/icons/new_delloni.png',
                    height: 80, width: 100, fit: BoxFit.cover),
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

  // FIXED: Product card with correct SYP pricing display
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
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[850] 
                : Colors.white,
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
                    
                    // Currency conversion indicator (only show when NOT SYP)
                    if (isUsingConvertedCurrency)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ColorsController.primaryColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getSafeCurrencyFlag(),
                                style: TextStyle(fontSize: 10),
                              ),
                              SizedBox(width: 2),
                              Text(
                                _selectedCurrency,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
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
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    
                    _buildPriceDisplay(product['price']),
                    
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

  // FIXED: Price display widget with correct SYP logic - REAL TIME
  Widget _buildPriceDisplay(dynamic price) {
    if (price == null || price == 0) {
      return Text(
        'Free',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.green[600],
        ),
      );
    }

    try {
      // Price is stored in SYP
      final priceInSyp = price is num ? price.toDouble() : double.parse(price.toString());
      
      if (_selectedCurrency == 'SYP') {
        // Show only SYP price (original stored price)
        print('📱 Displaying SYP price: $priceInSyp');
        return Text(
          'SYP ${priceInSyp.toStringAsFixed(0)}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        );
      } else {
        // Show converted price with original SYP crossed out
        final rate = _exchangeRates[_selectedCurrency] ?? 1.0;
        final convertedAmount = priceInSyp * rate;
        final symbol = _getCurrencySymbol(_selectedCurrency);
        final decimals = 2; // USD/EUR use 2 decimals
        
        print('📱 Converting price: $priceInSyp SYP × $rate = $convertedAmount $_selectedCurrency');
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Converted price (prominent)
            Text(
              '$symbol${convertedAmount.toStringAsFixed(decimals)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            // Original SYP price (crossed out, smaller)
            Text(
              'SYP ${priceInSyp.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[500],
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.grey[500],
              ),
            ),
          ],
        );
      }
    } catch (e) {
      print('❌ Price display error: $e');
      return Text(
        'Price error',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.red[600],
        ),
      );
    }
  }

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
                          await _switchCurrency(currency['code']!);
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

  Widget _buildCategoriesSection(List<Map<String, dynamic>> categories) {
    return RepaintBoundary(
      child: Container(
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
                itemCount: math.min(categories.length, 8),
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

  Widget _buildProductSection(String title, List<Map<String, dynamic>> products) {
    if (products.isEmpty) return SizedBox.shrink();
    
    return RepaintBoundary(
      child: Container(
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

  Widget _buildRecentlyAddedSection(List<Map<String, dynamic>> allProducts) {
    if (allProducts.isEmpty) return SizedBox.shrink();
    
    final recentProducts = allProducts.take(20).toList();
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

  Widget _buildFeaturedSection(List<Map<String, dynamic>> featuredProducts) {
    if (featuredProducts.isEmpty) return SizedBox.shrink();
    
    return RepaintBoundary(
      child: Container(
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

  Widget _buildPersonalizedSection(List<Map<String, dynamic>> personalizedProducts) {
    if (personalizedProducts.isEmpty) return SizedBox.shrink();
    
    return RepaintBoundary(
      child: Container(
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
                          highQuality: true,
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
                  highQuality: true,
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

  Widget _buildProductImage(Map<String, dynamic> product) {
    final imageUrls = product['imageUrls'] as List<dynamic>?;
  
    if (imageUrls != null && imageUrls.isNotEmpty) {
      return WatermarkPreservingImage(
        imageUrl: imageUrls.first.toString(),
        width: double.infinity,
        height: 170,
        fit: BoxFit.cover,
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

  // Helper methods
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
}