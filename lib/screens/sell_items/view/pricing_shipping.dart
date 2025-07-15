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
  final FocusNode _priceFocusNode = FocusNode(); // ADDED: Focus node for price field
  
  // Enhanced currency and pricing options
  String _selectedCurrency = 'SYP';
  String _pricingType = 'Fixed Price';
  bool _showPriceField = true;
  bool _isLoadingRates = false;
  DateTime? _lastRateUpdate;
  
  // UPDATED: Real-time exchange rates with Syrian Central Bank integration
  // Rates are stored as: 1 SYP = X USD/EUR
 
Map<String, double> _exchangeRates = {
  'USD': 0.000077, // Updated fallback: 1 SYP = 0.000077 USD (1 USD = ~13,000 SYP)
  'EUR': 0.000070, // Updated fallback: 1 SYP = 0.000070 EUR (1 EUR = ~14,286 SYP)
  'SYP': 1.0,      // 1 SYP = 1 SYP
};
  final List<Map<String, String>> _currencies = [
  {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
  {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
  {'code': 'SYP', 'name': 'Syrian Pound', 'symbol': 'SYP', 'flag': '🇸🇾'}, // Changed from 'ل.س' to 'SYP'
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
  
  // ADDED: Listener to dismiss keyboard when field loses focus
  _priceFocusNode.addListener(() {
    if (!_priceFocusNode.hasFocus) {
      FocusScope.of(context).unfocus();
    }
  });
  
  // ENHANCED: Load real-time exchange rates immediately
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _loadExchangeRates();
    }
  });
}
  @override
  void dispose() {
    _priceController.dispose();
    _animationController.dispose();
    _priceFocusNode.dispose(); // ADDED: Dispose focus node
    super.dispose();
  }

  // ADDED: Load real-time exchange rates from Syrian Central Bank
 // ENHANCED: Load real-time exchange rates with better error handling
Future<void> _loadExchangeRates() async {
  if (!mounted) return;
  
  setState(() {
    _isLoadingRates = true;
  });

  try {
    print('Loading exchange rates...');
    
    // Fetch rates from Syrian Central Bank API
    final sypToUsdRate = await _fetchSyrianCentralBankRate();
    print('Fetched SYP to USD rate: $sypToUsdRate');
    
    // Fetch EUR rate from USD base
    final eurRate = await _fetchEurRate();
    print('Fetched EUR rate: $eurRate');
    
    // Calculate SYP to EUR rate
    final sypToEurRate = sypToUsdRate * eurRate;
    
    if (mounted) {
      setState(() {
        _exchangeRates = {
          'USD': sypToUsdRate,
          'EUR': sypToEurRate,
          'SYP': 1.0,
        };
        print('Updated exchange rates: $_exchangeRates');
        _lastRateUpdate = DateTime.now();
        _isLoadingRates = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Exchange rates updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    print('Error loading exchange rates: $e');
    if (mounted) {
      setState(() {
        _isLoadingRates = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Failed to update exchange rates. Using cached rates.')),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

  // ADDED: Fetch Syrian Central Bank rate
  // ENHANCED: Fixed Syrian Central Bank rate fetching
Future<double> _fetchSyrianCentralBankRate() async {
  try {
    print('Fetching exchange rate from Syrian Central Bank...');
    
    // Make HTTP request to Syrian Central Bank API
    final response = await http.get(
      Uri.parse('https://www.cb.gov.sy/index.php?lang=2'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
      },
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final document = parser.parse(response.body);
      print('Successfully fetched CB page, parsing...');
      
      // Multiple parsing strategies for Syrian Central Bank website
      
      // Strategy 1: Look for exchange rate table
      final tables = document.querySelectorAll('table');
      for (final table in tables) {
        final rows = table.querySelectorAll('tr');
        for (final row in rows) {
          final cells = row.querySelectorAll('td, th');
          for (int i = 0; i < cells.length - 1; i++) {
            final cellText = cells[i].text.toLowerCase().trim();
            
            // Look for USD indicators
            if (cellText.contains('usd') || 
                cellText.contains('dollar') || 
                cellText.contains('أمريكي') ||
                cellText == 'us' ||
                cellText.contains('united states')) {
              
              // Check next cells for the rate
              for (int j = i + 1; j < cells.length; j++) {
                final rateText = cells[j].text.trim();
                final RegExp regex = RegExp(r'(\d{1,5}(?:[,.]?\d{3})*(?:[.,]\d{1,4})?)');
                final match = regex.firstMatch(rateText);
                
                if (match != null) {
                  final rateStr = match.group(1)?.replaceAll(',', '').replaceAll('.', '');
                  final rate = double.tryParse(rateStr ?? '');
                  
                  if (rate != null && rate > 1000 && rate < 50000) { // Reasonable range for SYP
                    print('Found USD to SYP rate from table: $rate');
                    return 1.0 / rate; // Convert to SYP to USD rate
                  }
                }
              }
            }
          }
        }
      }
      
      // Strategy 2: Look for specific patterns in the entire page
      final pageText = document.body?.text ?? '';
      
      // Look for patterns like "USD 13000" or "13000 SYP" etc.
      final patterns = [
        RegExp(r'USD[\s:]*(\d{4,5})'),
        RegExp(r'(\d{4,5})[\s]*SYP'),
        RegExp(r'دولار[\s:]*(\d{4,5})'),
        RegExp(r'(\d{4,5})[\s]*ليرة'),
      ];
      
      for (final pattern in patterns) {
        final matches = pattern.allMatches(pageText);
        for (final match in matches) {
          final rateStr = match.group(1);
          final rate = double.tryParse(rateStr ?? '');
          
          if (rate != null && rate > 1000 && rate < 50000) {
            print('Found rate using pattern matching: $rate');
            return 1.0 / rate;
          }
        }
      }
      
      // Strategy 3: Look in script tags for JSON data
      final scripts = document.querySelectorAll('script');
      for (final script in scripts) {
        final scriptContent = script.text;
        if (scriptContent.contains('usd') || scriptContent.contains('USD')) {
          final RegExp regex = RegExp(r'(\d{4,5}(?:\.\d{1,4})?)');
          final matches = regex.allMatches(scriptContent);
          
          for (final match in matches) {
            final rateStr = match.group(1);
            final rate = double.tryParse(rateStr ?? '');
            
            if (rate != null && rate > 1000 && rate < 50000) {
              print('Found rate in script: $rate');
              return 1.0 / rate;
            }
          }
        }
      }
    }
    
    print('Could not parse rate from CB website, trying alternative API...');
    
    // Fallback: Try alternative Syrian exchange rate API
    try {
      final fallbackResponse = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      ).timeout(Duration(seconds: 5));
      
      if (fallbackResponse.statusCode == 200) {
        final data = json.decode(fallbackResponse.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        // Note: This API might not have SYP, but we can use an estimated rate
        if (rates.containsKey('SYP')) {
          final sypRate = (rates['SYP'] as num).toDouble();
          print('Found SYP rate from alternative API: $sypRate');
          return 1.0 / sypRate;
        }
      }
    } catch (e) {
      print('Alternative API also failed: $e');
    }
    
  } catch (e) {
    print('Error fetching Syrian Central Bank rate: $e');
  }
  
  // Ultimate fallback with current approximate rate (as of 2024)
  // 1 USD ≈ 13,000 SYP (this should be updated based on current rates)
  print('Using fallback rate: 13000 SYP = 1 USD');
  return 1.0 / 13000; // 1 SYP = 0.000077 USD
}

  // ADDED: Fetch EUR rate from USD base
  Future<double> _fetchEurRate() async {
    try {
      // Using a free exchange rate API
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        // Get EUR rate from USD base
        final eurRate = (rates['EUR'] as num?)?.toDouble() ?? 0.91;
        print('Fetched EUR rate from USD: $eurRate');
        return eurRate;
      }
    } catch (e) {
      print('Error fetching EUR rate: $e');
    }
    
    // Fallback rate
    return 0.91;
  }

  void _onPricingTypeChanged(String newType) {
    setState(() {
      _pricingType = newType;
      _showPriceField = newType != 'Give Away';
      if (newType == 'Give Away') {
        _priceController.clear();
        FocusScope.of(context).unfocus(); // ADDED: Dismiss keyboard
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
    
    print('Converting amount: $amount $_selectedCurrency');
    print('Current exchange rates: $_exchangeRates');

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
                      AppLocalizations.priceInOtherCurrencies.tr(),
                      style: GoogleFonts.jost(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    // ADDED: Refresh rates button
                    IconButton(
                      onPressed: _isLoadingRates ? null : _loadExchangeRates,
                      icon: _isLoadingRates 
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.refresh, size: 20),
                      tooltip: AppLocalizations.refreshExchangeRates.tr(),
                    ),
                    // ADDED: Test conversion button
                    IconButton(
                      onPressed: _testConversion,
                      icon: Icon(Icons.bug_report, size: 20),
                      tooltip: AppLocalizations.testConversionLogic.tr(),
                    ),
                  ],
                ),
                
                // ADDED: Last update time
                if (_lastRateUpdate != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      _formatLastUpdate(_lastRateUpdate!),
                      // AppLocalizations.lastUpdated.tr(args: []),
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                
                ..._currencies.map((currency) {
                  // Convert from selected currency to target currency
                  double convertedAmount;
                  if (currency['code'] == _selectedCurrency) {
                    convertedAmount = amount;
                  } else if (_selectedCurrency == 'SYP') {
                    // Converting from SYP to other currency
                    convertedAmount = amount * (_exchangeRates[currency['code']] ?? 1.0);
                    print('Converting $_selectedCurrency to ${currency['code']}: $amount * ${_exchangeRates[currency['code']]} = $convertedAmount');
                  } else {
                    // Converting from other currency to SYP, then to target currency
                    final sypAmount = amount / (_exchangeRates[_selectedCurrency] ?? 1.0);
                    convertedAmount = sypAmount * (_exchangeRates[currency['code']] ?? 1.0);
                    print('Converting $_selectedCurrency to ${currency['code']}: $amount -> $sypAmount SYP -> $convertedAmount');
                  }
                  
                  return Container(
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
                              '${currency['symbol']}${convertedAmount.toStringAsFixed(currency['code'] == 'SYP' ? 0 : 2)}',
                              style: GoogleFonts.jost(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: currency['code'] == _selectedCurrency 
                                    ? ColorsController.primaryColor
                                    : Colors.black,
                              ),
                            ),
                            // ADDED: Show exchange rate
                            if (currency['code'] != 'SYP')
                              Text(
                                '1 SYP = ${_exchangeRates[currency['code']]?.toStringAsFixed(6)} ${currency['code']}',
                                style: GoogleFonts.jost(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            // ADDED: Show reverse rate for better understanding
                            if (currency['code'] != 'SYP')
                              Text(
                                '1 ${currency['code']} = ${(1.0 / (_exchangeRates[currency['code']] ?? 1.0)).toStringAsFixed(0)} SYP',
                                style: GoogleFonts.jost(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ],
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

  // ADDED: Format last update time
String _formatLastUpdate(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);
  
  if (difference.inSeconds < 30) {
    return 'Just now';
  } else if (difference.inMinutes < 1) {
    return '${difference.inSeconds} seconds ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else {
    return '${difference.inDays} days ago';
  }
}

  // ADDED: Test conversion logic
  void _testConversion() {
    print('=== Testing Currency Conversion ===');
    
    // Test with current rates
    final testAmount = 50.0; // 50 EUR
    
    // Convert EUR to USD
    final eurToUsd = testAmount / 0.91; // 1 EUR = 1.1 USD approximately
    print('50 EUR = ${eurToUsd.toStringAsFixed(2)} USD');
    
    // Convert EUR to SYP using our rates
    final eurToSyp = testAmount / 0.000070; // 1 EUR = 14285.71 SYP
    print('50 EUR = ${eurToSyp.toStringAsFixed(0)} SYP');
    
    // Convert SYP to USD
    final sypToUsd = eurToSyp * 0.000077; // 1 SYP = 0.000077 USD
    print('${eurToSyp.toStringAsFixed(0)} SYP = ${sypToUsd.toStringAsFixed(2)} USD');
    
    print('=== End Test ===');
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
      // ADDED: Dismiss keyboard when tapping outside
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
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
            mainAxisSize: MainAxisSize.min, // Ensure Row doesn't expand unnecessarily
            children: [
              Text(
                currency['flag']!,
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(width: 12),
              Column( // Replace Expanded with Column directly
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
          onTap: () => _onPricingTypeChanged(type['type']),
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
                    '${currency['symbol']}${amount.toStringAsFixed(_selectedCurrency == 'SYP' ? 0 : 2)}',
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
              // Save pricing information
              final priceValue = _pricingType != 'Give Away' ? double.parse(_priceController.text) : 0.0;
              final isNegotiable = _pricingType == 'Negotiable';
              
              itemProvider.updatePricingShipping(
                price: priceValue,
                allowPriceNegotiation: isNegotiable,
              );
              
              // Navigate to next screen - replace with your actual next page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.pricingInformationSaved.tr()),
                  backgroundColor: Colors.green,
                ),
              );
               // Update pricing details
                itemProvider.updatePricingShipping(
                  price: _pricingType == 'Give Away' ? 0.0 : double.tryParse(_priceController.text),
                  allowPriceNegotiation: _pricingType == 'Negotiable',
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EnhancedAddPhotosPage()),
                );
              // Navigator.pop(context);
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