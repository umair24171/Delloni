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
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

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
  
  // FIXED: Changed default to USD and correct rate format
  String _selectedCurrency = 'USD';
  String _pricingType = 'Fixed Price';
  bool _showPriceField = true;
  bool _isLoadingRates = false;
  DateTime? _lastRateUpdate;
  Timer? _rateUpdateTimer;
  
  // FIXED: Correct USD-based format (USD=1.0, others are rates from USD)
  Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'EUR': 0.851,
    'SYP': 12904.0, // 1 USD = 12904 SYP
  };

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'SYP', 'name': 'Syrian Pound', 'symbol': 'SYP', 'flag': '🇸🇾'},
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
    print('🟢 FIXED CODE VERSION - Using exchangerate-api.com only!');
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    _priceFocusNode.addListener(() {
      if (!_priceFocusNode.hasFocus) {
        FocusScope.of(context).unfocus();
      }
    });
    
    // Load rates immediately and start periodic updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadExchangeRates();
        _startPeriodicRateUpdates();
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _animationController.dispose();
    _priceFocusNode.dispose();
    _rateUpdateTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRateUpdates() {
    _rateUpdateTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      if (mounted) {
        print('🔄 Auto-refreshing rates...');
        _loadExchangeRates();
      }
    });
  }

  // COMPLETELY REWRITTEN: Only use exchangerate-api.com
  Future<void> _loadExchangeRates() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingRates = true;
    });

    try {
      print('🌐 Loading exchange rates from API...');
      
      // ONLY use exchangerate-api.com - no Central Bank
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      ).timeout(Duration(seconds: 10));
      
      print('📡 API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        print('📄 Raw API rates - EUR: ${rates['EUR']}, SYP: ${rates['SYP']}');
        
        // CORRECT format: USD as base (1.0)
        final newRates = {
          'USD': 1.0,
          'EUR': (rates['EUR'] as num?)?.toDouble() ?? 0.851,
          'SYP': (rates['SYP'] as num?)?.toDouble() ?? 12904.0,
        };
        
        if (mounted) {
          setState(() {
            _exchangeRates = newRates;
            _lastRateUpdate = DateTime.now();
            _isLoadingRates = false;
          });
          
          print('✅ SUCCESS! Exchange rates updated:');
          print('   USD: 1.0 (base)');
          print('   EUR: ${_exchangeRates['EUR']}');
          print('   SYP: ${_exchangeRates['SYP']}');
          
          // Test conversion
          final testSYP = 22.0;
          final testUSD = testSYP / _exchangeRates['SYP']!;
          print('🧪 TEST: $testSYP SYP = \$${testUSD.toStringAsFixed(4)} USD');
          
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Row(
          //       children: [
          //         Icon(Icons.check_circle, color: Colors.white),
          //         SizedBox(width: 8),
          //         Text('✅ Live rates: 1 USD = ${_exchangeRates['SYP']?.toStringAsFixed(0)} SYP'),
          //       ],
          //     ),
          //     backgroundColor: Colors.green,
          //     duration: Duration(seconds: 2),
          //   ),
          // );
        }
      } else {
        throw Exception('API returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading exchange rates: $e');
      if (mounted) {
        setState(() {
          _isLoadingRates = false;
        });
        
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Row(
        //       children: [
        //         Icon(Icons.error_outline, color: Colors.white),
        //         SizedBox(width: 8),
        //         Expanded(child: Text('❌ Failed to update rates. Using fallback.')),
        //       ],
        //     ),
        //     backgroundColor: Colors.orange,
        //     duration: Duration(seconds: 3),
        //   ),
        // );
      }
    }
  }

  void _onPricingTypeChanged(String newType) {
    setState(() {
      _pricingType = newType;
      _showPriceField = newType != 'Give Away';
      if (newType == 'Give Away') {
        _priceController.clear();
        FocusScope.of(context).unfocus();
      }
    });
    
    if (_showPriceField) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  
  void _showCurrencyConverter() {
    if (_priceController.text.isEmpty) return;
    
    final amount = double.tryParse(_priceController.text) ?? 0;
    if (amount <= 0) return;
    
    print('🔄 Converting amount: $amount $_selectedCurrency');
    print('📊 Current exchange rates: $_exchangeRates');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
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
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Text(
                                'LIVE API',
                                style: GoogleFonts.jost(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              onPressed: _isLoadingRates
                                  ? null
                                  : () async {
                                      await _loadExchangeRates();
                                      setModalState(() {});
                                    },
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
                          _formatLastUpdate(_lastRateUpdate!),
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    
                    // Show current rates
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Exchange Rates (Base: USD)',
                            style: GoogleFonts.jost(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '1 USD = ${_exchangeRates['EUR']?.toStringAsFixed(4)} EUR',
                            style: GoogleFonts.jost(fontSize: 11, color: Colors.blue[600]),
                          ),
                          Text(
                            '1 USD = ${_exchangeRates['SYP']?.toStringAsFixed(0)} SYP',
                            style: GoogleFonts.jost(fontSize: 11, color: Colors.blue[600], fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    
                    // Currency conversions
                    Column(
                      children: _currencies.map((currency) {
                        // FIXED: Proper conversion logic
                        double convertedAmount;
                        
                        if (currency['code'] == _selectedCurrency) {
                          // Same currency
                          convertedAmount = amount;
                        } else {
                          // Convert from selected currency to USD first
                          double usdAmount;
                          if (_selectedCurrency == 'USD') {
                            usdAmount = amount;
                          } else {
                            usdAmount = amount / _exchangeRates[_selectedCurrency]!;
                          }
                          
                          // Convert from USD to target currency
                          if (currency['code'] == 'USD') {
                            convertedAmount = usdAmount;
                          } else {
                            convertedAmount = usdAmount * _exchangeRates[currency['code']]!;
                          }
                        }
                        
                        print('💱 Converting: $amount $_selectedCurrency → ${convertedAmount.toStringAsFixed(2)} ${currency['code']}');
                        
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
                                  if (currency['code'] != 'USD')
                                    Text(
                                      '1 USD = ${_exchangeRates[currency['code']]?.toStringAsFixed(currency['code'] == 'SYP' ? 0 : 4)} ${currency['code']}',
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
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatLastUpdate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final locale = context.locale.languageCode;

    if (difference.inSeconds < 30) {
      return 'Just now'.tr();
    } else if (difference.inMinutes < 1) {
      return  locale == 'ar'
          ? 'منذ ${difference.inMinutes} ثانية'
          : '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
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

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.pricingShipping.tr(),
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Force refresh button
          IconButton(
            icon: _isLoadingRates 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh, color: ColorsController.primaryColor),
            onPressed: _isLoadingRates ? null : _loadExchangeRates,
            tooltip: 'Refresh live rates',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.setYourPriceDelivery.tr(),
                style: GoogleFonts.jost(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.priceCompetitively.tr(),
                style: GoogleFonts.jost(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              // ADDED: Status indicator showing fixed version
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${"✅ FIXED VERSION • API Only •".tr()} 1 USD = ${_exchangeRates['SYP']?.toStringAsFixed(0)} SYP • ${_lastRateUpdate != null ? _formatLastUpdate(_lastRateUpdate!) : 'Loading...'.tr()}',
                        style: GoogleFonts.jost(
                          fontSize: 11,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle(AppLocalizations.currency.tr(), Icons.attach_money),
              const SizedBox(height: 12),
              _buildCurrencySelector(),
              const SizedBox(height: 32),
              
              _buildSectionTitle(AppLocalizations.pricingType.tr(), Icons.psychology),
              const SizedBox(height: 12),
              _buildPricingTypeSelection(),
              const SizedBox(height: 32),
              
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
              
              _buildSectionTitle(AppLocalizations.delivery.tr(), Icons.local_shipping),
              const SizedBox(height: 12),
              _buildShippingOptions(itemProvider),
              const SizedBox(height: 32),
              
              if (_priceController.text.isNotEmpty && _pricingType != 'Give Away') ...[
                _buildPriceSummaryCard(),
                const SizedBox(height: 32),
              ],
              
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
                      currency['name']!.toString().tr(),
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
                        type['type'].toString().tr(),
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
                        type['subtitle'].toString().tr(),
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
              hintText: 'Enter price amount'.tr(),
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
                      // Live rate indicator
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!, width: 0.5),
                        ),
                        child: Text(
                          '${_exchangeRates['SYP']?.toStringAsFixed(0)}',
                          style: GoogleFonts.jost(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[600],
                          ),
                        ),
                      ),
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
                    'This price is negotiable. Buyers can make offers.'.tr(),
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
                    title.tr(),
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
                    subtitle.tr(),
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
                'Price Summary'.tr(),
                style: GoogleFonts.jost(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorsController.primaryColor,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  'LIVE'.tr(),
                  style: GoogleFonts.jost(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
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
                    'Your Price'.tr(),
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
                    _pricingType.tr(),
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
                      _pricingType == 'Fixed Price' ? 'FIXED'.tr() : 'NEGO'.tr(),
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
              final priceValue = _pricingType != 'Give Away' ? double.parse(_priceController.text) : 0.0;
              final isNegotiable = _pricingType == 'Negotiable';
              
              itemProvider.updatePricingShipping(
                price: priceValue,
                allowPriceNegotiation: isNegotiable,
              );
              
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text('Pricing information saved successfully!'),
              //     backgroundColor: Colors.green,
              //   ),
              // );
                
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