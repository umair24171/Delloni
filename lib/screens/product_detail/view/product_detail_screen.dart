import 'dart:convert';
import 'dart:developer';

import 'package:arabicmarketplace/controller/review_provider.dart';
import 'package:arabicmarketplace/controller/review_service.dart';
import 'package:arabicmarketplace/main.dart';
import 'package:arabicmarketplace/screens/account/view/account_profile_page.dart';
import 'package:arabicmarketplace/screens/product_detail/controller/product_detail_provider.dart';
import 'package:arabicmarketplace/screens/product_detail/model/product_detail_model.dart';
import 'package:arabicmarketplace/screens/reviews_page/model/review_model.dart';
import 'package:arabicmarketplace/screens/reviews_page/view/reviews_page.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:arabicmarketplace/widgets/image_optimise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailScreen extends StatefulWidget {
  final String? productId;
  final ProductDetailModel? product; // For when passed from home

  const ProductDetailScreen({
    Key? key,
    this.productId,
    this.product,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductDetailProvider _provider;
  PageController _pageController = PageController();
   // CURRENCY CONVERSION PROPERTIES
  String _selectedCurrency = 'SYP'; // Default to Syrian Pound
  bool _isLoadingRates = false;
  DateTime? _lastRateUpdate;
  
  // Exchange rates with Syrian Pound as base (1 SYP = X other currency)
  Map<String, double> _exchangeRates = {
    'SYP': 1.0,
    // 'PKR': 0.0032, // 1 SYP ≈ 0.0032 PKR
    'USD': 0.00040, // 1 SYP ≈ 0.0004 USD
    'EUR': 0.00037, // 1 SYP ≈ 0.00037 EUR
  };
  
  final List<Map<String, String>> _currencies = [
    {'code': 'SYP', 'name': 'Syrian Pound', 'symbol': 'ل.س', 'flag': '🇸🇾'},
    // {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': '₨', 'flag': '🇵🇰'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
  ];

   @override
  void initState() {
    super.initState();
    _provider = ProductDetailProvider();
    _loadExchangeRates(); // Load exchange rates on startup
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.productId != null) {
        _provider.initializeProduct(widget.productId!);
      }
    
    });
  }
   // CURRENCY CONVERSION METHODS
  Future<void> _loadExchangeRates() async {
    setState(() {
      _isLoadingRates = true;
    });

    try {
      // Fetch Syrian Central Bank rate
      final sypRates = await _fetchSyrianCentralBankRates();
      
      // Fetch other currency rates
      final otherRates = await _fetchOtherCurrencyRates();
      
      setState(() {
        _exchangeRates = {
          'SYP': 1.0,
          // 'PKR': otherRates['PKR'] ?? 0.0032,
          'USD': otherRates['USD'] ?? 0.00040,
          'EUR': otherRates['EUR'] ?? 0.00037,
        };
        _lastRateUpdate = DateTime.now();
        _isLoadingRates = false;
      });
      
      // Save rates to local storage
      await _saveRatesToLocal();
      
    } catch (e) {
      print('Error loading exchange rates: $e');
      
      // Try to load cached rates
      await _loadCachedRates();
      
      setState(() {
        _isLoadingRates = false;
      });
    }
  }

  Future<Map<String, double>> _fetchSyrianCentralBankRates() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.cb.gov.sy/index.php?lang=2'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        
        // Parse USD to SYP rate
        final patterns = [
          r'USD[^\d]*(\d+\.?\d*)',
          r'Dollar[^\d]*(\d+\.?\d*)',
          r'(\d+\.?\d*)[^\d]*USD',
        ];
        
        final searchTexts = [
          document.body?.text ?? '',
          ...document.querySelectorAll('table').map((e) => e.text),
          ...document.querySelectorAll('.rate, .exchange, .currency').map((e) => e.text),
        ];
        
        for (final text in searchTexts) {
          for (final pattern in patterns) {
            final regex = RegExp(pattern, caseSensitive: false);
            final match = regex.firstMatch(text);
            if (match != null) {
              final usdToSyp = double.tryParse(match.group(1) ?? '');
              if (usdToSyp != null && usdToSyp > 100 && usdToSyp < 10000) {
                // Convert to SYP base rates
                return {
                  'USD': 1.0 / usdToSyp, // 1 SYP = X USD
                  // 'PKR': (1.0 / usdToSyp) * 280, // Assuming 1 USD ≈ 280 PKR
                  'EUR': (1.0 / usdToSyp) * 0.92, // Assuming 1 USD ≈ 0.92 EUR
                };
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching Syrian Central Bank rates: $e');
    }
    
    // Fallback rates
    return {
      'USD': 0.00040,
      // 'PKR': 0.0032,
      'EUR': 0.00037,
    };
  }

  Future<Map<String, double>> _fetchOtherCurrencyRates() async {
    try {
      // Try to fetch from exchange rate API
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        // Convert to SYP base (assuming 1 USD = 2500 SYP as fallback)
        final usdToSyp = 2500.0;
        
        return {
          'USD': 1.0 / usdToSyp,
          // 'PKR': (rates['PKR'] as num?)?.toDouble() ?? 280.0 / usdToSyp,
          'EUR': (rates['EUR'] as num?)?.toDouble() ?? 0.92 / usdToSyp,
        };
      }
    } catch (e) {
      print('Error fetching other currency rates: $e');
    }
    
    // Fallback rates
    return {
      'USD': 0.00040,
      // 'PKR': 0.0032,
      'EUR': 0.00037,
    };
  }

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

  String _convertPrice(double amount, String originalCurrency) {
  
    // Convert PKR to SYP first (assuming original prices are in PKR)
    double sypAmount;
    sypAmount = amount;
    
    if (_selectedCurrency == 'SYP') {
      return sypAmount.toStringAsFixed(0);
    }
    
    final rate = _exchangeRates[_selectedCurrency] ?? 1.0;
    final convertedAmount = sypAmount * rate;
    
    return convertedAmount >= 1 
        ? convertedAmount.toStringAsFixed(2)
        : convertedAmount.toStringAsFixed(4);
  }

  String _getFormattedPrice(ProductDetailModel product) {
    if (product.price == 0.0) return 'Free';

    final currency = _currencies.firstWhere((c) => c['code'] == _selectedCurrency);
    final convertedPrice = _convertPrice(product.price, 'SYP'); // Assuming original is PKR
    
    return '${currency['symbol']}$convertedPrice';
  }

  bool _isDataFresh() {
    if (_lastRateUpdate == null) return false;
    return DateTime.now().difference(_lastRateUpdate!).inHours < 1;
  }

  String _formatLastUpdate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final locale = context.locale.languageCode;

    if (difference.inMinutes < 1) {
      return 'Just now'.tr();
    } else  if (difference.inMinutes < 60) {
      return locale == 'ar'
          ? 'منذ ${difference.inMinutes} دقيقة'
          : '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return locale == 'ar'
          ? 'منذ ${difference.inHours} ساعة'
          : '${difference.inHours} hours ago';
    } else {
      return locale == 'ar'
          ? 'منذ ${difference.inDays} يوم'
          : '${difference.inDays} days ago';
    }
  }

  void _showCurrencyConverter(ProductDetailModel product) {
    if (product.price <= 0) return;

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
                      'Price in Different Currencies'.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
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
                                _isDataFresh() ? 'Live'.tr() : 'Cached'.tr(),
                                style: GoogleFonts.outfit(
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
                      '${"Last updated:".tr()} ${_formatLastUpdate(_lastRateUpdate!)}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                
                ..._currencies.map((currency) {
                  // Convert PKR price to SYP first, then to target currency
                  double sypPrice = product.price / 9.0; // PKR to SYP conversion
                  double convertedAmount;
                  
                  if (currency['code'] == 'SYP') {
                    convertedAmount = sypPrice;
                  } else {
                    final rate = _exchangeRates[currency['code']] ?? 1.0;
                    convertedAmount = sypPrice * rate;
                  }
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: currency['code'] == _selectedCurrency 
                          ? Color(0xFF2D5016).withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currency['code'] == _selectedCurrency 
                            ? Color(0xFF2D5016)
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
                                currency['name']!.toString().tr(),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                currency['code']!,
                                style: GoogleFonts.outfit(
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
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: currency['code'] == _selectedCurrency 
                                    ? Color(0xFF2D5016)
                                    : Colors.black,
                              ),
                            ),
                            if (currency['code'] != 'SYP')
                              Text(
                                '1 SYP = ${_exchangeRates[currency['code']]?.toStringAsFixed(currency['code'] == 'SYP' ? 2 : 4)} ${currency['code']}',
                                style: GoogleFonts.outfit(
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


  Future<void> _handleCallButtonPress(ProductDetailProvider provider) async {
  // Show loading indicator
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
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
          Text('Opening dialer...'),
        ],
      ),
      backgroundColor: Color(0xFF2D5016),
      duration: Duration(seconds: 1),
    ),
  );



  // Call the provider method and get status
  Map<String, dynamic> result = await provider.callSellerWithStatus();
  
  // Hide the loading snackbar
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  
  // Show result feedback
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            result['success'] 
              ? (result['hasNumber'] ? Icons.phone : Icons.info_outline)
              : Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(child: Text(result['message'])),
        ],
      ),
      backgroundColor: result['success'] 
        ? (result['hasNumber'] ? Colors.green : Colors.orange)
        : Colors.red,
      duration: Duration(seconds: 3),
      action: !result['hasNumber'] && result['success'] ? SnackBarAction(
        label: 'Chat Instead'.tr(),
        textColor: Colors.white,
        onPressed: () => provider.chatWithSeller(context),
      ) : null,
    ),
  );
}

Future<void> _shareProduct(ProductDetailProvider provider) async {
  final product = provider.product;
  if (product == null) return;

  try {
    // Create share content
    String shareText = '''
🏷️ ${product.title}

💰 ${product.getFormattedPrice()}${product.allowPriceNegotiation ? ' (Negotiable)' : ''}

📍 ${product.locationAddress ?? 'Location not specified'}

🏷️ Condition: ${product.condition}

${product.description.isNotEmpty ? '📝 ${product.description}\n' : ''}
⏰ Posted: ${product.getTimeSincePosted()}

Check out this amazing product on our marketplace!

#Marketplace #${product.category} #ForSale
''';

    // Share with result handling
    final result = await Share.share(
      shareText,
      subject: '${product.title} - ${product.getFormattedPrice()}',
    );

    // Show feedback based on result
    if (result.status == ShareResultStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Product shared successfully!'.tr()),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    // Show error if sharing fails
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Failed to share product'.tr()),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
    print('Error sharing product: $e');
  }
}


  @override
  void dispose() {
    _provider.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
   
   // ENHANCED: Title and Price Section with Currency Selection
  Widget _buildEnhancedTitlePriceSection(ProductDetailModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        
        // Enhanced Price Row with Currency Selector and Converter
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getFormattedPrice(product),
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (product.allowPriceNegotiation) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Negotiable'.tr(),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  // Currency Selection Row
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF2D5016).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF2D5016).withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            isDense: true,
                            items: _currencies.map((currency) {
                              return DropdownMenuItem<String>(
                                value: currency['code'],
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(currency['flag']!, style: TextStyle(fontSize: 14)),
                                    SizedBox(width: 4),
                                    Text(
                                      currency['code']!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2D5016),
                                      ),
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
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Color(0xFF2D5016),
                            ),
                            dropdownColor: Colors.white,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: Color(0xFF2D5016),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showCurrencyConverter(product),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.currency_exchange,
                                size: 14,
                                color: Colors.blue[700],
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Convert'.tr(),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                product.locationAddress ?? 'Location not specified'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Text(
              product.getTimeSincePosted(),
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        if (product.condition.isNotEmpty) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getConditionColor(product.condition),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product.condition=='new'?'new'.tr():product.condition=='refurbished'?"refurbished".tr():product.condition=='Good'?"Good".tr():product.condition,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
// ENHANCED: Category-specific Stats Section (Top row with icons)
 Widget _buildCategoryStatsSection(ProductDetailModel product) {
  // Get field template data to determine which fields have icons
  final fieldTemplateData = _getFieldTemplateData(product);
  final fieldsWithIcons = _getFieldsWithIcons(product, fieldTemplateData);
  
  if (fieldsWithIcons.isEmpty) return SizedBox.shrink();

  final statItems = <Widget>[];

  // Build stat items from fields that have icons in template
  for (final fieldData in fieldsWithIcons) {
    statItems.add(_buildStatItemWithIcon(
      fieldData['icon'],
      fieldData['iconUrl'],
      fieldData['value'],
      fieldData['label'],
    ));
  }

  return Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Color(0xFFE9ECEF), width: 1),
    ),
    child: Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.spaceAround,
      children: statItems.take(6).toList(), // Show up to 6 stats
    ),
  );
}

// Helper method to extract field template data from product
Map<String, Map<String, dynamic>> _getFieldTemplateData(ProductDetailModel product) {
  final templateData = <String, Map<String, dynamic>>{};
  
  try {
    // Check if product has categoryFieldTemplate
    if (product.specifications.containsKey('categoryFieldTemplate')) {
      final template = product.specifications['categoryFieldTemplate'];
      print('DEBUG: categoryFieldTemplate found: $template');
      
      if (template is List) {
        for (final fieldConfig in template) {
          if (fieldConfig is Map) {
            final fieldName = fieldConfig['fieldName'] ?? fieldConfig['name'];
            if (fieldName != null) {
              templateData[fieldName] = Map<String, dynamic>.from(fieldConfig);
              print('DEBUG: Added template for field $fieldName: $fieldConfig');
            }
          }
        }
      }
    }
  } catch (e) {
    print('Error parsing field template: $e');
  }
  
  return templateData;
}
// Enhanced stat item builder that can handle both custom icons and fallback icons
// Alternative solution using IntrinsicWidth for more flexible sizing
Widget _buildStatItemWithIcon(IconData fallbackIcon, String? iconUrl, String value, String label) {
  return IntrinsicWidth(
    child: Container(
      constraints: BoxConstraints(
        minWidth: 80,
        maxWidth: 120,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2D5016).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildIconWidget(iconUrl, fallbackIcon),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

// Helper method to build icon widget (custom URL or fallback) - NO CHANGES NEEDED
Widget _buildIconWidget(String? iconUrl, IconData fallbackIcon) {
  if (iconUrl != null && iconUrl.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        iconUrl,
        width: 24,
        height: 24,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading custom icon: $error');
          return Icon(
            fallbackIcon,
            size: 24,
            color: Color(0xFF2D5016),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D5016)),
            ),
          );
        },
      ),
    );
  } else {
    return Icon(
      fallbackIcon,
      size: 24,
      color: Color(0xFF2D5016),
    );
  }
}
// Helper method to get fields that have icons based on template
List<Map<String, dynamic>> _getFieldsWithIcons(ProductDetailModel product, Map<String, Map<String, dynamic>> templateData) {
  final fieldsWithIcons = <Map<String, dynamic>>[];
  
  // Check categorySpecificFields against template
  product.categorySpecificFields.forEach((fieldName, value) {
    if (value == null || value.toString().trim().isEmpty) return;
    
    final template = templateData[fieldName];
    final hasIcon = template?['showFieldIcon'] == true;
    final iconUrl = template?['fieldIconUrl'];
    final label = template?['label'] ?? _formatFieldName(fieldName);
    
    print('DEBUG: Field $fieldName - hasIcon: $hasIcon, iconUrl: $iconUrl');
    
    if (hasIcon) {
      // Format the value
      String formattedValue = _formatFieldValueForDisplay(value, fieldName);
      
      fieldsWithIcons.add({
        'fieldName': fieldName,
        'value': formattedValue,
        'label': label,
        'icon': _getDefaultIconForField(fieldName), // Fallback icon
        'iconUrl': iconUrl,
        'hasCustomIcon': iconUrl != null && iconUrl.toString().isNotEmpty,
      });
      
      print('DEBUG: Added field with icon: $fieldName = $formattedValue');
    }
  });
  
  return fieldsWithIcons;
}

// Helper method to format field values for display
String _formatFieldValueForDisplay(dynamic value, String fieldName) {
  if (value == null) return 'N/A';
  
  // Handle boolean values
  if (value is bool) {
    return value ? 'Yes' : 'No';
  }
  
  // Add units based on field name
  String stringValue = value.toString();
  final fieldLower = fieldName.toLowerCase();
  
  if (fieldLower.contains('year') && stringValue.length == 4) {
    return stringValue;
  } else if (fieldLower.contains('size') && RegExp(r'^\d+\.?\d*$').hasMatch(stringValue)) {
    return stringValue + '"';
  } else if (fieldLower.contains('storage') || fieldLower.contains('ram')) {
    return stringValue + ' GB';
  } else if (fieldLower.contains('battery')) {
    return stringValue + ' mAh';
  } else if (fieldLower.contains('engine')) {
    return stringValue + ' cc';
  } else if (fieldLower.contains('area')) {
    return stringValue + ' sq ft';
  } else if (fieldLower.contains('mileage') || fieldLower.contains('kilometers')) {
    return stringValue + ' km';
  }
  
  return stringValue;
}

// Helper method to get default icon for fields (fallback)
IconData _getDefaultIconForField(String fieldName) {
  final fieldLower = fieldName.toLowerCase();
  
  if (fieldLower.contains('color')) return Icons.palette;
  if (fieldLower.contains('model') || fieldLower.contains('year')) return Icons.calendar_today;
  if (fieldLower.contains('size')) return Icons.straighten;
  if (fieldLower.contains('storage')) return Icons.storage;
  if (fieldLower.contains('ram') || fieldLower.contains('memory')) return Icons.memory;
  if (fieldLower.contains('battery')) return Icons.battery_full;
  if (fieldLower.contains('screen')) return Icons.tv;
  if (fieldLower.contains('camera')) return Icons.camera_alt;
  if (fieldLower.contains('network')) return Icons.network_cell;
  if (fieldLower.contains('engine')) return Icons.engineering;
  if (fieldLower.contains('fuel')) return Icons.local_gas_station;
  if (fieldLower.contains('transmission')) return Icons.settings;
  if (fieldLower.contains('mileage') || fieldLower.contains('kilometers')) return Icons.speed;
  
  return Icons.info_outline; // Default fallback icon
}
   
   

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Consumer<ProductDetailProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(provider.error!, style: TextStyle(color: Colors.red)),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refreshData(),
                      child: Text('Retry'.tr()),
                    ),
                  ],
                ),
              );
            }

            if (provider.product == null) {
              return Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Images with Overlay AppBar
                  _buildImageSectionWithOverlay(provider.product!, provider),
                  
                  // Content Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ENHANCED: Title and Price with Currency Selection
                        _buildEnhancedTitlePriceSection(provider.product!),
                        
                        SizedBox(height: 25),
                        
                        // Action Buttons
                        _buildActionButtons(provider),
                        
                        SizedBox(height: 30),
                        
                        // Your existing sections...
                        _buildCategoryStatsSection(provider.product!),
                        SizedBox(height: 30),
                        _buildCategoryDetailsSection(provider.product!),
                        SizedBox(height: 30),
                        _buildDescriptionSection(provider.product!),
                        SizedBox(height: 30),
                        _buildCategoryFeaturesSection(provider.product!),
                        SizedBox(height: 30),
                        _buildSellerSection(provider.seller, provider),
                        SizedBox(height: 30),
                        _buildSellerReviewsSection(provider.seller),
                        SizedBox(height: 30),
                        _buildRelatedProductsSection(provider.relatedProducts),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: Consumer<ProductDetailProvider>(
          builder: (context, provider, child) {
            if (provider.product == null || provider.seller == null) {
              return SizedBox.shrink();
            }
            
            return _canUserReview(provider.seller!.id) 
                ? FloatingActionButton.extended(
                    onPressed: () => _showQuickReviewDialog(provider.product!, provider.seller!),
                    backgroundColor: Color(0xFF2D5016),
                    icon: Icon(Icons.star_outline, color: Colors.white),
                    label: Text(
                      'Review Seller'.tr(),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : SizedBox.shrink();
          },
        ),
      ),
    );
  }
 
 
 // ENHANCED: Category Details Section - Only fields WITHOUT icons
Widget _buildCategoryDetailsSection(ProductDetailModel product) {
  // Get field template data to determine which fields have icons
  final fieldTemplateData = _getFieldTemplateData(product);
  final fieldsWithIcons = _getFieldsWithIcons(product, fieldTemplateData);
  final fieldsWithIconNames = fieldsWithIcons.map((f) => f['fieldName']).toSet();
  
  // Get fields WITHOUT icons for specifications section
  final fieldsWithoutIcons = <Map<String, String>>[];
  
  // Check categorySpecificFields that don't have icons
  product.categorySpecificFields.forEach((fieldName, value) {
    if (value == null || value.toString().trim().isEmpty) return;
    if (fieldsWithIconNames.contains(fieldName)) return; // Skip fields already shown in stats
    
    final template = fieldTemplateData[fieldName];
    final hasIcon = template?['showFieldIcon'] == true;
    
    if (!hasIcon) {
      final label = template?['label'] ?? _formatFieldName(fieldName);
      final formattedValue = _formatFieldValueForDisplay(value, fieldName);
      
      fieldsWithoutIcons.add({
        'label': label,
        'value': formattedValue,
      });
      
      print('DEBUG: Added field without icon: $fieldName = $formattedValue');
    }
  });

  // Add other specifications that aren't in categorySpecificFields
  final specifications = Map<String, dynamic>.from(product.specifications);
  
  // Remove fields that are already processed
  product.categorySpecificFields.keys.forEach((key) {
    specifications.remove(key);
  });
  
  // Remove template data and other metadata
  specifications.remove('categoryFieldTemplate');
  specifications.remove('hasCategoryFields');
  specifications.remove('flattenedFields');

  // Add remaining specs that don't have icons
  specifications.forEach((fieldName, value) {
    if (value == null || value.toString().trim().isEmpty) return;
    if (fieldName.toLowerCase().contains('template')) return;
    if (fieldName.toLowerCase().contains('fields')) return;
    
    // Don't add if it's a field that should have an icon based on our fallback logic
    final fieldLower = fieldName.toLowerCase();
    final hasDefaultIcon = _shouldHaveDefaultIcon(fieldLower);
    
    if (!hasDefaultIcon) {
      fieldsWithoutIcons.add({
        'label': _formatFieldName(fieldName),
        'value': _formatFieldValueForDisplay(value, fieldName),
      });
    }
  });

  // If no fields to show, return empty widget
  if (fieldsWithoutIcons.isEmpty && 
      product.brand == null && product.color == null && product.dimensions == null) {
    return SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Specifications'.tr(),
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 15),
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE9ECEF), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display fields without icons
            ...fieldsWithoutIcons.map((field) => _buildDetailRow(
              field['label']!,
              field['value']!,
            )),

            // Add standard fields if not already included
            if (product.brand != null && product.brand!.isNotEmpty)
              _buildDetailRow('Brand'.tr(), product.brand!),
            if (product.color != null && product.color!.isNotEmpty && !product.categorySpecificFields.containsKey('color'))
              _buildDetailRow('Color'.tr(), product.color!),
            if (product.dimensions != null && product.dimensions!.isNotEmpty)
              _buildDetailRow('Dimensions'.tr(), product.dimensions!),

            // Always add Ad ID and Views
            if (fieldsWithoutIcons.isNotEmpty || product.brand != null || product.color != null || product.dimensions != null)
              Divider(height: 24, color: Color(0xFFE9ECEF)),
            _buildDetailRow('Ad ID'.tr(), product.id.substring(0, 8).toUpperCase()),
            _buildDetailRow('Views'.tr(), product.viewCount.toString()),
          ],
        ),
      ),
    ],
  );
}
// Helper method to check if a field should have a default icon
bool _shouldHaveDefaultIcon(String fieldLower) {
  return fieldLower.contains('color') ||
         fieldLower.contains('model') ||
         fieldLower.contains('year') ||
         fieldLower.contains('size') ||
         fieldLower.contains('storage') ||
         fieldLower.contains('ram') ||
         fieldLower.contains('memory') ||
         fieldLower.contains('battery') ||
         fieldLower.contains('screen') ||
         fieldLower.contains('camera') ||
         fieldLower.contains('network') ||
         fieldLower.contains('engine') ||
         fieldLower.contains('fuel') ||
         fieldLower.contains('transmission') ||
         fieldLower.contains('mileage') ||
         fieldLower.contains('kilometers');
}

// Enhanced Features Section - Only boolean features
Widget _buildCategoryFeaturesSection(ProductDetailModel product) {
  // Get field template data
  final fieldTemplateData = _getFieldTemplateData(product);
  
  // Extract boolean features from category fields
  final features = <String>[];
  
  product.categorySpecificFields.forEach((fieldName, value) {
    if (value is bool && value == true) {
      final template = fieldTemplateData[fieldName];
      final label = template?['label'] ?? _formatFieldName(fieldName);
      features.add(label);
    }
  });

  // Add any additional features from specifications
  for (final entry in product.specifications.entries) {
    if (entry.value is bool && entry.value == true) {
      final displayName = _formatFieldName(entry.key);
      if (!features.contains(displayName)) {
        features.add(displayName);
      }
    }
  }

  // Add legacy features
  features.addAll(product.features.where((f) => !features.contains(f)));

  if (features.isEmpty) return SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Features'.tr(),
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 15),
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE9ECEF), width: 1),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            return _buildFeatureItem(
              _getFeatureIcon(features[index]),
              features[index],
            );
          },
        ),
      ),
    ],
  );
}

// Helper method to format field names
String _formatFieldName(String fieldName) {
  final displayNames = {
    'year': 'Year',
    'kilometers': 'Mileage',
    'mileage': 'Mileage',
    'fuel_type': 'Fuel Type',
    'transmission': 'Transmission',
    'engine_capacity': 'Engine Capacity',
    'body_type': 'Body Type',
    'car_type': 'Car Type',
    'doors': 'Doors',
    'seating_capacity': 'Seating',
    'power_steering': 'Power Steering',
    'air_conditioning': 'Air Conditioning',
    'bike_type': 'Bike Type',
    'engine_type': 'Engine Type',
    'storage': 'Storage',
    'ram': 'RAM',
    'screen_size': 'Screen Size',
    'battery_capacity': 'Battery',
    'network_type': 'Network',
    'dual_sim': 'Dual SIM',
    'processor': 'Processor',
    'storage_type': 'Storage Type',
    'storage_capacity': 'Storage Capacity',
    'graphics_card': 'Graphics Card',
    'operating_system': 'Operating System',
    'property_type': 'Property Type',
    'area': 'Area',
    'bedrooms': 'Bedrooms',
    'bathrooms': 'Bathrooms',
    'furnished': 'Furnished',
    'parking': 'Parking',
    'purpose': 'Purpose',
    'size': 'Size',
    'material': 'Material',
    'gender': 'Gender',
    'room_type': 'Room Type',
    'assembly_required': 'Assembly Required',
    'sport_type': 'Sport Type',
    'suitable_for': 'Suitable For',
    'color': 'Color',
    'model': 'Model',
  };

  return displayNames[fieldName.toLowerCase()] ?? fieldName
    .split('_')
    .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
    .join(' ');
}

// Helper widget for detail rows
Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label.tr(),
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

// Helper widget for feature items
Widget _buildFeatureItem(IconData icon, String text) {
  return Container(
    padding: EdgeInsets.all(0),
    decoration: BoxDecoration(
      color: Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Color(0xFFE9ECEF), width: 1),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xFF2D5016).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon, 
            size: 18, 
            color: Color(0xFF2D5016),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

// Helper method to get feature icons
IconData _getFeatureIcon(String feature) {
  String lowerFeature = feature.toLowerCase();
  if (lowerFeature.contains('power steering')) return Icons.casino;
  if (lowerFeature.contains('air conditioning') || lowerFeature.contains('ac')) return Icons.ac_unit;
  if (lowerFeature.contains('lock')) return Icons.lock_outline;
  if (lowerFeature.contains('seat')) return Icons.airline_seat_recline_normal;
  if (lowerFeature.contains('automatic') || lowerFeature.contains('gear')) return Icons.settings;
  if (lowerFeature.contains('speed')) return Icons.speed;
  if (lowerFeature.contains('bluetooth')) return Icons.bluetooth;
  if (lowerFeature.contains('camera')) return Icons.camera_alt;
  if (lowerFeature.contains('gps') || lowerFeature.contains('navigation')) return Icons.navigation;
  if (lowerFeature.contains('dual sim')) return Icons.sim_card;
  if (lowerFeature.contains('parking')) return Icons.local_parking;
  if (lowerFeature.contains('furnished')) return Icons.chair;
  return Icons.check_circle_outline;
}




Widget _buildImageSectionWithOverlay(ProductDetailModel product, ProductDetailProvider provider) {
  return Stack(
    children: [
      // Main Image Container
      Container(
        height: 400, // Increased height to accommodate status bar
        width: double.infinity,
        child: product.imageUrls.isNotEmpty
            ? PageView.builder(
                controller: _pageController,
                itemCount: product.imageUrls.length,
                onPageChanged: (index) => provider.updateImageIndex(index),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE8E8E8), Color(0xFFF5F5F5)],
                      ),
                    ),
                    child: 
                    WatermarkPreservingImage(
height: double.infinity,
width: double.infinity,
preserveWatermark: true,
                        imageUrl:  product.imageUrls[index],
                        fit: BoxFit.cover,
                      
                      ),
                   
                  );
                },
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8E8E8), Color(0xFFF5F5F5)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey[600]),
                ),
              ),
      ),
      
      // Gradient overlay for better icon visibility
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 120,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      
      // Custom AppBar overlay
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Container(
            height: 56,
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // Back Button
                Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                Spacer(),
                
                // Action Buttons
                Consumer<ProductDetailProvider>(
                  builder: (context, provider, child) {
                    return Row(
                      children: [
                        // Favorite Button
                        Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              provider.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: provider.isFavorite ? Colors.red : Colors.black,
                            ),
                            onPressed: () => provider.toggleFavorite(),
                          ),
                        ),
                        
                        // Share Button
                        Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.share_outlined, color: Colors.black),
                            onPressed: () => _shareProduct(provider),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      
      // Image counter (bottom right)
      if (product.imageUrls.length > 1)
        Positioned(
          bottom: 15,
          right: 20,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${provider.currentImageIndex + 1}/${product.imageUrls.length}',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      
      // Negotiable tag (bottom left)
      if (product.allowPriceNegotiation)
        Positioned(
          bottom: 15,
          left: 20,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.yellow[700],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              'Negotiable'.tr(),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
    ],
  );
}
 
 Widget _buildActionButtons(ProductDetailProvider provider) {
  return Row(
    children: [
      Expanded(
        child: Container(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => provider.chatWithSeller(context),
            icon: Icon(Icons.chat_outlined, color: Colors.white),
            label: Text(
             '${AppLocalizations.chat.tr()}',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2D5016),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ),
      SizedBox(width: 15),
      Expanded(
        child: Container(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _handleCallButtonPress(provider),
            icon: Icon(
              provider.sellerHasPhoneNumber 
                ? Icons.phone_outlined 
                : Icons.phone_disabled_outlined,
              color: Colors.white,
            ),
            label: Text(
              provider.sellerHasPhoneNumber ? '${AppLocalizations.call.tr()}' : 'No Number'.tr(),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.sellerHasPhoneNumber 
                ? Color(0xFF2D5016) 
                : Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}


  Widget _buildDescriptionSection(ProductDetailModel product) {
    if (product.description.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
        AppLocalizations.description.tr(),
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            // color: Colors.black,
          ),
        ),
        SizedBox(height: 15),
        Text(
          product.description,
          style: GoogleFonts.outfit(
            fontSize: 15,
            // color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }


 Widget _buildSellerSection(SellerModel? seller, ProductDetailProvider provider) {
  if (seller == null) return SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppLocalizations.sellerDetail.tr(),
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          // color: Colors.black,
        ),
      ),
      SizedBox(height: 15),
      Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _navigateToSellerProfile(seller.id),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: seller.profileImageUrl != null
                        ? NetworkImage(seller.profileImageUrl!)
                        : null,
                    child: seller.profileImageUrl == null
                        ? Icon(Icons.person, size: 30)
                        : null,
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.getDisplayName(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '${ AppLocalizations.memberSince.tr()}: ${seller.getMemberSinceFormatted()}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 5),
                        UserRatingWidget(
                          userId: seller.id,
                          showCount: true,
                          iconSize: 16,
                          fontSize: 14,
                        ),
                        // Show phone status
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              provider.sellerHasPhoneNumber 
                                ? Icons.phone 
                                : Icons.phone_disabled,
                              size: 12,
                              color: provider.sellerHasPhoneNumber 
                                ? Colors.green 
                                : Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              provider.sellerHasPhoneNumber
                                ? '${AppLocalizations.phoneAvailable.tr()}'
                                : 'No phone number'.tr(),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: provider.sellerHasPhoneNumber 
                                  ? Colors.green[700] 
                                  : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (provider.sellerHasPhoneNumber && provider.sellerFormattedPhone != null) ...[
                              SizedBox(width: 8),
                              Text(
                                provider.sellerFormattedPhone!,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: () => provider.chatWithSeller(context),
                              child: Icon(
                                Icons.message_outlined,
                                size: 20,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: provider.sellerHasPhoneNumber 
                                  ? Colors.green.withOpacity(0.3) 
                                  : Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _handleCallButtonPress(provider),
                              child: Icon(
                                provider.sellerHasPhoneNumber 
                                  ? Icons.phone_outlined 
                                  : Icons.phone_disabled_outlined,
                                size: 20,
                                color: provider.sellerHasPhoneNumber 
                                  ? Colors.grey[700] 
                                  : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      InkWell(
                        onTap: () => _navigateToSellerProfile(seller.id),
                        child: Text(
                          'View Profile'.tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Color(0xFF2D5016),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Quick action buttons
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showQuickReviewDialog(provider.product!, seller),
                    icon: Icon(Icons.star_outline, size: 18),
                    label: Text(
                     '${AppLocalizations.leaveReview.tr()}',
                      style: GoogleFonts.outfit(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF2D5016),
                      side: BorderSide(color: Color(0xFF2D5016)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToSellerReviews(seller.id),
                    icon: Icon(Icons.reviews_outlined, size: 18),
                    label: Text(
                 '${AppLocalizations.allReviews.tr()}',
                      style: GoogleFonts.outfit(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

  // New method to build seller reviews section
  Widget _buildSellerReviewsSection(SellerModel? seller) {
    if (seller == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
             '${AppLocalizations.recentReviews.tr()}',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                // color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToSellerReviews(seller.id),
              child: Text(
                'View All'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Color(0xFF2D5016),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        // Use the RecentReviewsWidget
        RecentReviewsWidget(
          userId: seller.id,
          maxReviews: 2,
        ),
      ],
    );
  }

  Widget _buildRelatedProductsSection(List<ProductDetailModel> relatedProducts) {
    if (relatedProducts.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Products'.tr(),
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            // color: Colors.black,
          ),
        ),
        SizedBox(height: 15),
        Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: relatedProducts.length,
            itemBuilder: (context, index) {
              final product = relatedProducts[index];
              return Container(
                width: 150,
                margin: EdgeInsets.only(right: 15),
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
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(productId: product.id),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          child: product.imageUrls.isNotEmpty
                              ? Image.network(
                                  product.imageUrls.first,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.image, color: Colors.grey[400]),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image, color: Colors.grey[400]),
                                ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              product.getFormattedPrice(),
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Review-related methods
  bool _canUserReview(String sellerId) {
    // Logic to check if current user can review this seller
    // This would typically check if user has purchased from this seller
    // and hasn't already reviewed them
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid == sellerId) {
      return false; // Can't review yourself
    }
    return true; // Simplified - in real app, check purchase history
  }

  void _showQuickReviewDialog(ProductDetailModel product, SellerModel seller) {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            '${"Rate".tr()} ${seller.getDisplayName()}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600,color: Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your experience with this seller?'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => rating = index + 1.0),
                    child: Icon(
                      Icons.star,
                      size: 36,
                      color: index < rating ? Colors.amber : Colors.grey[300],
                    ),
                  );
                }),
              ),
              SizedBox(height: 8),
              Text(
                _getRatingText(rating),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getRatingColor(rating),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)'.tr(),
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFF2D5016)),
                  ),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel'.tr(),
                style: GoogleFonts.outfit(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _submitQuickReviewWithDebug(product, seller, rating, commentController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2D5016),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Submit Review'.tr(),
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _debugReviewSubmission(ProductDetailModel product, SellerModel seller) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    log('DEBUG: No current user');
    return;
  }

  log('=== DEBUG REVIEW SUBMISSION ===');
  log('Current User ID: ${user.uid}');
  log('Product ID: ${product.id}');
  log('Seller ID: ${seller.id}');
  log('Product Title: ${product.title}');
  log('Seller Name: ${seller.getDisplayName()}');

  // Check document existence
  final reviewService = ReviewService();
  Map<String, bool> docCheck = await reviewService.debugCheckDocuments(
    reviewerId: user.uid,
    revieweeId: seller.id,
    itemId: product.id,
  );

  log('Document Existence Check:');
  log('- Reviewer (${user.uid}): ${docCheck['reviewer']}');
  log('- Reviewee (${seller.id}): ${docCheck['reviewee']}');
  log('- Item (${product.id}): ${docCheck['item']}');

  // Check specific field values
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      log('Reviewer Data:');
      log('- Type: ${userData['type']}');
      log('- Email: ${userData['email']}');
      log('- Company Name: ${userData['companyName']}');
    }

    DocumentSnapshot sellerDoc = await FirebaseFirestore.instance.collection('users').doc(seller.id).get();
    if (sellerDoc.exists) {
      Map<String, dynamic> sellerData = sellerDoc.data() as Map<String, dynamic>;
      log('Seller Data:');
      log('- Type: ${sellerData['type']}');
      log('- Email: ${sellerData['email']}');
      log('- Company Name: ${sellerData['companyName']}');
    }

    DocumentSnapshot itemDoc = await FirebaseFirestore.instance.collection('items').doc(product.id).get();
    if (itemDoc.exists) {
      Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
      log('Item Data:');
      log('- Title: ${itemData['title']}');
      log('- ItemTitle: ${itemData['itemTitle']}');
      log('- SellerId: ${itemData['sellerId']}');
      log('- Status: ${itemData['status']}');
    }
  } catch (e) {
    log('Error during debug check: $e');
  }

  log('=== END DEBUG ===');
}

// Modified review submission method with debug
Future<void> _submitQuickReviewWithDebug(
  ProductDetailModel product, 
  SellerModel seller, 
  double rating, 
  String comment
) async {
  try {
    // First run debug
    await _debugReviewSubmission(product, seller);

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Submitting review...'),
          ],
        ),
        backgroundColor: Color(0xFF2D5016),
        duration: Duration(seconds: 2),
      ),
    );

    final reviewProvider = context.read<ReviewProvider>();
    
    bool success = await reviewProvider.createReview(
      revieweeId: seller.id,
      itemId: product.id,
      rating: rating,
      comment: comment.trim(),
      transactionType: 'purchase',
    );

    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Review submitted successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      log('Review submission failed. Error: ${reviewProvider.error}');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reviewProvider.error ?? 'Failed to submit review'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    log('Exception during review submission: $e');
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
}


  void _navigateToSellerProfile(String sellerId) {
    // Navigate to seller's profile page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountProfilePage(userId: sellerId,),
      ),
    );
  }

  void _navigateToSellerReviews(String sellerId) {
    // Navigate to seller's reviews page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsPage(
          userId: sellerId,
          showCreateReviewButton: false,
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating <= 1) return 'Poor'.tr();
    if (rating <= 2) return 'Fair'.tr();
    if (rating <= 3) return 'Good'.tr();
    if (rating <= 4) return 'Very Good'.tr();
    return 'Excellent'.tr();
  }

  Color _getRatingColor(double rating) {
    if (rating <= 2) return Colors.red;
    if (rating <= 3) return Colors.orange;
    if (rating <= 4) return Colors.blue;
    return Colors.green;
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'used':
        return Colors.orange;
      case 'refurbished':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

 
}





// User Rating Widget (from the review system)
class UserRatingWidget extends StatelessWidget {
  final String userId;
  final bool showCount;
  final double iconSize;
  final double fontSize;

  const UserRatingWidget({
    Key? key,
    required this.userId,
    this.showCount = true,
    this.iconSize = 16,
    this.fontSize = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReviewService().getUserRatingSummary(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: iconSize, color: Colors.grey[300]),
              SizedBox(width: 4),
              Text(
                '--',
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  color: Colors.grey[500],
                ),
              ),
            ],
          );
        }

        final data = snapshot.data!;
        final rating = data['averageRating']?.toDouble() ?? 0.0;
        final count = data['reviewCount'] ?? 0;

        if (count == 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border, size: iconSize, color: Colors.grey[400]),
              SizedBox(width: 4),
              Text(
                'No reviews'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  color: Colors.grey[500],
                ),
              ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: iconSize, color: Colors.amber),
            SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: GoogleFonts.outfit(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showCount) ...[
              SizedBox(width: 4),
              Text(
                '($count)',
                style: GoogleFonts.outfit(
                  fontSize: fontSize - 2,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// Recent Reviews Widget
class RecentReviewsWidget extends StatelessWidget {
  final String userId;
  final int maxReviews;

  const RecentReviewsWidget({
    Key? key,
    required this.userId,
    this.maxReviews = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ReviewService().getUserReviews(userId, limit: maxReviews),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Text(
                'No reviews yet'.tr(),
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        final reviews = snapshot.data!.docs
            .map((doc) => ReviewModel.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList();

        return Column(
          children: reviews.map((review) => _buildCompactReviewCard(review)).toList(),
        );
      },
    );
  }

  Widget _buildCompactReviewCard(ReviewModel review) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
             Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => AccountProfilePage(userId: review.reviewerId,),
      ),
    );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFF2D5016),
                  child: Text(
                    review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : 'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.reviewerName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStarRating(review.rating, size: 12),
              ],
            ),
          ),
          if (review.comment.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              review.comment,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 4),
          Text(
            review.formattedDate,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 12}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}
