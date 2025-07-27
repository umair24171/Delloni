import 'dart:convert';
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/view/add_photos_page.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
class EnhancedPricingShippingPage extends StatefulWidget {
  const EnhancedPricingShippingPage({Key? key}) : super(key: key);

  @override
  State<EnhancedPricingShippingPage> createState() => _EnhancedPricingShippingPageState();
}

class _EnhancedPricingShippingPageState extends State<EnhancedPricingShippingPage> 
    with TickerProviderStateMixin {
  final TextEditingController _priceController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final FocusNode _priceFocusNode = FocusNode();
  
  // Enhanced currency and pricing options
  String _selectedCurrency = 'PKR';
  String _pricingType = 'Fixed Price';
  bool _showPriceField = true;
  bool _isLoadingRates = false;
  DateTime? _lastRateUpdate;
  
  // UPDATED: Real-time exchange rates with Syrian Central Bank integration
  Map<String, double> _exchangeRates = {
    'PKR': 1.0,
    'USD': 0.0035,
    'EUR': 0.0032,
    'SYP': 9.0,
  };
  
  final List<Map<String, String>> _currencies = [
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': '₨', 'flag': '🇵🇰'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'SYP', 'name': 'Syrian Pound', 'symbol': 'ل.س', 'flag': '🇸🇾'},
  ];

  final List<Map<String, dynamic>> _pricingTypes = [
    {
      'type': 'Fixed Price',
      'description': 'Set a specific non-negotiable price',
      'icon': Icons.price_check,
      'color': Colors.blue,
      'subtitle': 'Buyers pay the exact amount',
    },
    {
      'type': 'Negotiable',
      'description': 'Open to price discussions with buyers',
      'icon': Icons.handshake,
      'color': Colors.orange,
      'subtitle': 'Allow haggling and offers',
    },
    {
      'type': 'Give Away',
      'description': 'Offer item for free',
      'icon': Icons.favorite,
      'color': Colors.green,
      'subtitle': 'Help someone in need',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // FIXED: Auto-dismiss keyboard when focus is lost
    _priceFocusNode.addListener(() {
      if (!_priceFocusNode.hasFocus) {
        FocusScope.of(context).unfocus();
      }
    });
    
    // Load real-time exchange rates on startup
    _loadExchangeRates();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _animationController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  // ENHANCED: Load real-time exchange rates from Syrian Central Bank
  Future<void> _loadExchangeRates() async {
    setState(() {
      _isLoadingRates = true;
    });

    try {
      // Fetch Syrian Pound rate from Central Bank
      final sypRate = await _fetchSyrianCentralBankRate();
      
      // Fetch other currency rates
      final otherRates = await _fetchOtherCurrencyRates();
      
      setState(() {
        _exchangeRates = {
          'PKR': 1.0,
          'USD': otherRates['USD'] ?? 0.0035,
          'EUR': otherRates['EUR'] ?? 0.0032,
          'SYP': sypRate,
        };
        _lastRateUpdate = DateTime.now();
        _isLoadingRates = false;
      });
      
      // Save rates to local storage for offline use
      await _saveRatesToLocal();
      
    } catch (e) {
      print('Error loading exchange rates: $e');
      
      // Try to load cached rates
      await _loadCachedRates();
      
      setState(() {
        _isLoadingRates = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Using cached exchange rates. Check your internet connection.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadExchangeRates,
          ),
        ),
      );
    }
  }

  // ENHANCED: Fetch Syrian Central Bank rate with better parsing
  Future<double> _fetchSyrianCentralBankRate() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.cb.gov.sy/index.php?lang=2'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
      ).timeout(Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        
        // Look for USD exchange rate in various possible locations
        final patterns = [
          r'USD[^\d]*(\d+\.?\d*)',
          r'Dollar[^\d]*(\d+\.?\d*)',
          r'US Dollar[^\d]*(\d+\.?\d*)',
          r'(\d+\.?\d*)[^\d]*USD',
          r'(\d+\.?\d*)[^\d]*Dollar',
        ];
        
        // Search in different elements
        final searchTexts = [
          document.body?.text ?? '',
          ...document.querySelectorAll('table').map((e) => e.text),
          ...document.querySelectorAll('.rate, .exchange, .currency').map((e) => e.text),
          ...document.querySelectorAll('td, th').map((e) => e.text),
        ];
        
        for (final text in searchTexts) {
          for (final pattern in patterns) {
            final regex = RegExp(pattern, caseSensitive: false);
            final match = regex.firstMatch(text);
            if (match != null) {
              final rate = double.tryParse(match.group(1) ?? '');
              if (rate != null && rate > 100 && rate < 10000) {
                // Convert from USD/SYP to PKR/SYP
                // Assuming 1 USD ≈ 280 PKR
                final pkrToSyp = rate / 280;
                print('Found Syrian Central Bank rate: 1 USD = $rate SYP, 1 PKR = $pkrToSyp SYP');
                return pkrToSyp;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching Syrian Central Bank rate: $e');
    }
    
    // Fallback: Try alternative Syrian financial websites
    try {
      return await _fetchAlternativeSyrianRate();
    } catch (e) {
      print('Alternative Syrian rate fetch failed: $e');
    }
    
    // Final fallback rate
    return 9.0;
  }

  // NEW: Alternative Syrian rate sources
  Future<double> _fetchAlternativeSyrianRate() async {
    try {
      // Try Syrian stock exchange or other financial sites
      final response = await http.get(
        Uri.parse('https://dse.sy/'),
        headers: {'User-Agent': 'Mozilla/5.0 (compatible; ExchangeRateApp/1.0)'},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final text = response.body.toLowerCase();
        final regex = RegExp(r'usd[^\d]*(\d+\.?\d*)');
        final match = regex.firstMatch(text);
        if (match != null) {
          final rate = double.tryParse(match.group(1) ?? '');
          if (rate != null && rate > 100) {
            return rate / 280; // Convert to PKR/SYP
          }
        }
      }
    } catch (e) {
      print('Alternative rate source failed: $e');
    }
    
    return 9.0; // Fallback rate
  }

  // ENHANCED: Fetch other currency rates with better error handling
  Future<Map<String, double>> _fetchOtherCurrencyRates() async {
    try {
      // Try multiple API sources for reliability
      final futures = [
        _fetchFromExchangeRateAPI(),
        _fetchFromFreeCurrencyAPI(),
      ];
      
      final results = await Future.wait(futures, eagerError: false);
      
      // Use the first successful result
      for (final result in results) {
        if (result != null && result.isNotEmpty) {
          return result;
        }
      }
    } catch (e) {
      print('Error fetching currency rates: $e');
    }
    
    // Fallback rates
    return {
      'USD': 0.0035,
      'EUR': 0.0032,
    };
  }

  Future<Map<String, double>?> _fetchFromExchangeRateAPI() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/PKR'),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        return {
          'USD': (rates['USD'] as num?)?.toDouble() ?? 0.0035,
          'EUR': (rates['EUR'] as num?)?.toDouble() ?? 0.0032,
        };
      }
    } catch (e) {
      print('ExchangeRate API failed: $e');
    }
    return null;
  }

  Future<Map<String, double>?> _fetchFromFreeCurrencyAPI() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.fixer.io/latest?base=PKR&access_key=YOUR_API_KEY'),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final rates = data['rates'] as Map<String, dynamic>;
          return {
            'USD': (rates['USD'] as num?)?.toDouble() ?? 0.0035,
            'EUR': (rates['EUR'] as num?)?.toDouble() ?? 0.0032,
          };
        }
      }
    } catch (e) {
      print('Fixer API failed: $e');
    }
    return null;
  }

  // NEW: Cache rates locally
  Future<void> _saveRatesToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = json.encode(_exchangeRates);
      await prefs.setString('exchange_rates', ratesJson);
      await prefs.setString('rates_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving rates: $e');
    }
  }

  Future<void> _loadCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = prefs.getString('exchange_rates');
      final timestamp = prefs.getString('rates_timestamp');
      
      if (ratesJson != null && timestamp != null) {
        final cachedTime = DateTime.parse(timestamp);
        final hoursSinceCache = DateTime.now().difference(cachedTime).inHours;
        
        // Use cached rates if less than 6 hours old
        if (hoursSinceCache < 6) {
          final rates = Map<String, double>.from(json.decode(ratesJson));
          setState(() {
            _exchangeRates = rates;
            _lastRateUpdate = cachedTime;
          });
        }
      }
    } catch (e) {
      print('Error loading cached rates: $e');
    }
  }

  void _onPricingTypeChanged(String newType) {
    setState(() {
      _pricingType = newType;
      _showPriceField = newType != 'Give Away';
      if (newType == 'Give Away') {
        _priceController.clear();
        FocusScope.of(context).unfocus(); // FIXED: Dismiss keyboard immediately
      }
    });
    
    if (_showPriceField) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  String _convertPrice(double amount) {
    if (_selectedCurrency == 'PKR') return amount.toStringAsFixed(0);
    
    final rate = _exchangeRates[_selectedCurrency] ?? 1.0;
    final convertedAmount = amount * rate;
    
    return convertedAmount >= 1 
        ? convertedAmount.toStringAsFixed(2)
        : convertedAmount.toStringAsFixed(4);
  }

  void _showCurrencyConverter() {
    if (_priceController.text.isEmpty) return;
    
    final amount = double.tryParse(_priceController.text) ?? 0;
    if (amount <= 0) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price in Other Currencies',
                      style: GoogleFonts.jost(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        // ENHANCED: Show data freshness indicator
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isDataFresh() ? Colors.green[50] : Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isDataFresh() ? Colors.green : Colors.orange,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isDataFresh() ? Icons.check_circle : Icons.schedule,
                                size: 12,
                                color: _isDataFresh() ? Colors.green[700] : Colors.orange[700],
                              ),
                              SizedBox(width: 4),
                              Text(
                                _isDataFresh() ? 'Live' : 'Cached',
                                style: GoogleFonts.jost(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _isDataFresh() ? Colors.green[700] : Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          onPressed: _isLoadingRates ? null : _loadExchangeRates,
                          icon: _isLoadingRates 
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(Icons.refresh, size: 20),
                          tooltip: 'Refresh exchange rates',
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (_lastRateUpdate != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Last updated: ${_formatLastUpdate(_lastRateUpdate!)}',
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                
               // In the _showCurrencyConverter() method, replace the currency mapping section with this:

..._currencies.map((currency) {
  final convertedAmount = currency['code'] == _selectedCurrency 
      ? amount 
      : amount * (_exchangeRates[currency['code']] ?? 1.0);
  
  return Column(
    children: [
      Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: currency['code'] == _selectedCurrency 
              ? ColorsController.primaryColor.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: currency['code'] == _selectedCurrency 
                ? ColorsController.primaryColor
                : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Text(
              currency['flag']!,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency['name']!,
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currency['code']!,
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${currency['symbol']}${convertedAmount.toStringAsFixed(currency['code'] == 'PKR' ? 0 : 2)}',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: currency['code'] == _selectedCurrency 
                        ? ColorsController.primaryColor
                        : Colors.black,
                  ),
                ),
                if (currency['code'] != 'PKR')
                  Text(
                    '1 PKR = ${_exchangeRates[currency['code']]?.toStringAsFixed(currency['code'] == 'SYP' ? 2 : 4)} ${currency['code']}',
                    style: GoogleFonts.jost(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      // Add Syrian Bank dependency note for SYP
      if (currency['code'] == 'SYP')
        Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance,
                color: Colors.blue[700],
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Syrian Pound rate depends on Syrian Central Bank official rates',
                  style: GoogleFonts.jost(
                    fontSize: 11,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
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

  // NEW: Check if data is fresh (less than 1 hour old)
  bool _isDataFresh() {
    if (_lastRateUpdate == null) return false;
    return DateTime.now().difference(_lastRateUpdate!).inHours < 1;
  }

  String _formatLastUpdate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.pricingShipping.tr(),
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      // FIXED: Dismiss keyboard when tapping outside
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          _priceFocusNode.unfocus(); // Extra ensure focus is lost
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Text(
                AppLocalizations.setYourPriceDelivery.tr(),
                style: GoogleFonts.jost(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.priceCompetitively.tr(),
                style: GoogleFonts.jost(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              
              // Currency Selection Section
              _buildSectionTitle(AppLocalizations.currency.tr(), Icons.attach_money),
              const SizedBox(height: 12),
              _buildCurrencySelector(),
              const SizedBox(height: 32),
              
              // Pricing Type Section
              _buildSectionTitle(AppLocalizations.pricingType.tr(), Icons.psychology),
              const SizedBox(height: 12),
              _buildPricingTypeSelection(),
              const SizedBox(height: 32),
              
              // Price Field Section
              if (_showPriceField) ...[
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(AppLocalizations.setPrice.tr(), Icons.price_change),
                      const SizedBox(height: 12),
                      _buildPriceInput(itemProvider),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
              
              // Shipping Options Section
              _buildSectionTitle(AppLocalizations.delivery.tr(), Icons.local_shipping),
              const SizedBox(height: 12),
              _buildShippingOptions(itemProvider),
              const SizedBox(height: 32),
              
              // Price Summary Card (if price is set)
              if (_priceController.text.isNotEmpty && _pricingType != 'Give Away') ...[
                _buildPriceSummaryCard(),
                const SizedBox(height: 32),
              ],
              
              // Bottom Navigation
              _buildBottomNavigation(itemProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorsController.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: ColorsController.primaryColor,
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.jost(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCurrency,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        items: _currencies.map((currency) {
          return DropdownMenuItem<String>(
            value: currency['code'],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currency['flag']!,
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currency['name']!,
                      style: GoogleFonts.jost(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${currency['symbol']} (${currency['code']})',
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedCurrency = newValue;
            });
            // FIXED: Dismiss keyboard when changing currency
            FocusScope.of(context).unfocus();
          }
        },
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: ColorsController.primaryColor,
        ),
      ),
    );
  }

  Widget _buildPricingTypeSelection() {
    return Column(
      children: _pricingTypes.map((type) {
        final isSelected = _pricingType == type['type'];
        return GestureDetector(
          onTap: () {
            _onPricingTypeChanged(type['type']);
            // FIXED: Dismiss keyboard when changing pricing type
            FocusScope.of(context).unfocus();
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? ColorsController.primaryColor.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? ColorsController.primaryColor
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? ColorsController.primaryColor
                        : type['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    type['icon'],
                    size: 20,
                    color: isSelected 
                        ? Colors.white
                        : type['color'],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type['type'],
                        style: GoogleFonts.jost(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? ColorsController.primaryColor
                              : Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        type['subtitle'],
                        style: GoogleFonts.jost(
                          fontSize: 12,
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
        );
      }).toList(),
    );
  }

  Widget _buildPriceInput(ItemProvider itemProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: _priceController,
            focusNode: _priceFocusNode,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: 'Enter price amount',
              hintStyle: GoogleFonts.jost(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              prefixIcon: Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  _currencies.firstWhere((c) => c['code'] == _selectedCurrency)['symbol']!,
                  style: GoogleFonts.jost(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ColorsController.primaryColor,
                  ),
                ),
              ),
              suffixIcon: _priceController.text.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.currency_exchange,
                          color: ColorsController.primaryColor,
                        ),
                        onPressed: _showCurrencyConverter,
                        tooltip: 'View in other currencies',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          _priceController.clear();
                          FocusScope.of(context).unfocus(); // FIXED: Dismiss keyboard when clearing
                          setState(() {});
                        },
                      ),
                    ],
                  )
                : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            style: GoogleFonts.jost(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            onChanged: (value) {
              setState(() {});
            },
            onFieldSubmitted: (value) {
              // FIXED: Dismiss keyboard when user presses done/enter
              FocusScope.of(context).unfocus();
              _priceFocusNode.unfocus();
            },
            onTap: () {
              // Optional: Automatically select all text when tapping
              if (_priceController.text.isNotEmpty) {
                _priceController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _priceController.text.length,
                );
              }
            },
          ),
        ),
        if (_pricingType == 'Negotiable') ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This price is negotiable. Buyers can make offers.',
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShippingOptions(ItemProvider itemProvider) {
    return Column(
      children: [
        _buildShippingOption(
          'Pickup Only',
          'Buyer picks up from your location',
          Icons.location_on,
          itemProvider.shippingOption == 'Pickup Only',
          () => itemProvider.updatePricingShipping(shippingOption: 'Pickup Only'),
        ),
        SizedBox(height: 12),
        _buildShippingOption(
          'Delivery Available',
          'You will deliver or ship the item',
          Icons.local_shipping,
          itemProvider.shippingOption == 'Delivery Available',
          () => itemProvider.updatePricingShipping(shippingOption: 'Delivery Available'),
        ),
        SizedBox(height: 12),
        _buildShippingOption(
          'Both Options',
          'Buyer can choose pickup or delivery',
          Icons.swap_horiz,
          itemProvider.shippingOption == 'Both',
          () => itemProvider.updatePricingShipping(shippingOption: 'Both'),
        ),
      ],
    );
  }

  Widget _buildShippingOption(String title, String subtitle, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? ColorsController.primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? ColorsController.primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? ColorsController.primaryColor
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected 
                    ? Colors.white
                    : Colors.grey[600],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? ColorsController.primaryColor
                          : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.jost(
                      fontSize: 12,
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
    );
  }

  Widget _buildPriceSummaryCard() {
    final amount = double.tryParse(_priceController.text) ?? 0;
    if (amount <= 0) return SizedBox.shrink();

    final currency = _currencies.firstWhere((c) => c['code'] == _selectedCurrency);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsController.primaryColor.withOpacity(0.1),
            ColorsController.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsController.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: ColorsController.primaryColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Price Summary',
                style: GoogleFonts.jost(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorsController.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Price',
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${currency['symbol']}${amount.toStringAsFixed(_selectedCurrency == 'PKR' ? 0 : 2)}',
                    style: GoogleFonts.jost(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ColorsController.primaryColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _pricingType,
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _pricingType == 'Fixed Price' 
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _pricingType == 'Fixed Price' ? 'FIXED' : 'NEGO',
                      style: GoogleFonts.jost(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _pricingType == 'Fixed Price' 
                            ? Colors.blue[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(ItemProvider itemProvider) {
    final canProceed = _pricingType == 'Give Away' || 
                      (_priceController.text.isNotEmpty && 
                       double.tryParse(_priceController.text) != null &&
                       double.parse(_priceController.text) > 0);
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: ColorsController.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              AppLocalizations.back.tr(),
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorsController.primaryColor,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: canProceed ? () {
              // FIXED: Dismiss keyboard before navigation
              FocusScope.of(context).unfocus();
              _priceFocusNode.unfocus();
              
              // Save pricing information
              final priceValue = _pricingType != 'Give Away' ? double.parse(_priceController.text) : 0.0;
              final isNegotiable = _pricingType == 'Negotiable';
              
              itemProvider.updatePricingShipping(
                price: priceValue,
                allowPriceNegotiation: isNegotiable,
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pricing information saved successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Navigate to next screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EnhancedAddPhotosPage()),
              );
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsController.primaryColor,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              AppLocalizations.next.tr(),
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: canProceed ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }
}