import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/view/add_photos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  
  // Enhanced currency and pricing options
  String _selectedCurrency = 'PKR';
  String _pricingType = 'Fixed Price'; // Fixed Price, Negotiable, Give Away
  bool _showPriceField = true;
  
  // Currency exchange rates (you can fetch these from an API)
  final Map<String, double> _exchangeRates = {
    'PKR': 1.0,
    'USD': 0.0035, // 1 PKR = 0.0035 USD
    'EUR': 0.0032, // 1 PKR = 0.0032 EUR
    'SYP': 9.0,    // 1 PKR = 9 SYP (approximate)
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
  }

  @override
  void dispose() {
    _priceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPricingTypeChanged(String newType) {
    setState(() {
      _pricingType = newType;
      _showPriceField = newType != 'Give Away';
      if (newType == 'Give Away') {
        _priceController.clear();
      }
    });
    
    // Animate the price field appearance/disappearance
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
                Text(
                  'Price in Other Currencies',
                  style: GoogleFonts.jost(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                ..._currencies.map((currency) {
                  final convertedAmount = currency['code'] == _selectedCurrency 
                      ? amount 
                      : amount * (_exchangeRates[currency['code']] ?? 1.0);
                  
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
          'Pricing & Shipping',
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              'Set Your Price & Delivery Options',
              style: GoogleFonts.jost(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Price your item competitively and choose how you\'d like to deliver it to buyers.',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // Currency Selection Section
            _buildSectionTitle('Currency', Icons.attach_money),
            const SizedBox(height: 12),
            _buildCurrencySelector(),
            const SizedBox(height: 32),
            
            // Pricing Type Section
            _buildSectionTitle('Pricing Type', Icons.psychology),
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
                    _buildSectionTitle('Set Price', Icons.price_change),
                    const SizedBox(height: 12),
                    _buildPriceInput(itemProvider),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
            
            // Shipping Options Section
            _buildSectionTitle('Delivery Options', Icons.local_shipping),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: _currencies.map((currency) {
          return DropdownMenuItem<String>(
            value: currency['code'],
            child: Row(
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
                      '${currency['symbol']} ${currency['code']}',
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currency['name']!,
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
        onChanged: (value) {
          setState(() {
            _selectedCurrency = value!;
          });
        },
        dropdownColor: Colors.white,
        style: GoogleFonts.jost(color: Colors.black),
      ),
    );
  }

  Widget _buildPricingTypeSelection() {
    return Column(
      children: _pricingTypes.map((typeData) {
        final isSelected = _pricingType == typeData['type'];
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _onPricingTypeChanged(typeData['type']),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? typeData['color'].withOpacity(0.1) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? typeData['color'] 
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: typeData['color'].withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: typeData['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      typeData['icon'],
                      color: typeData['color'],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeData['type'],
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? typeData['color'] : Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          typeData['subtitle'],
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    scale: isSelected ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 200),
                    child: Icon(
                      Icons.check_circle,
                      color: typeData['color'],
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceInput(ItemProvider itemProvider) {
    final currency = _currencies.firstWhere((c) => c['code'] == _selectedCurrency);
    
    return Column(
      children: [
        Row(
          children: [
            // Currency Symbol Container
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: ColorsController.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                border: Border.all(color: ColorsController.primaryColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currency['flag']!,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(width: 4),
                    Text(
                      currency['symbol']!,
                      style: GoogleFonts.jost(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorsController.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Price Input Field
            Expanded(
              child: TextFormField(
                controller: _priceController,
                style: GoogleFonts.jost(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  hintStyle: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: ColorsController.primaryColor, width: 2.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Colors.red, width: 1.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
                validator: (value) {
                  if (_pricingType != 'Give Away') {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid price';
                    }
                  }
                  return null;
                },
                onChanged: (value) {
                  itemProvider.updatePricingShipping(
                    price: double.tryParse(value),
                  );
                  setState(() {}); // Refresh to update summary card
                },
              ),
            ),
          ],
        ),
        
        // Currency Converter Button
        if (_priceController.text.isNotEmpty) ...[
          SizedBox(height: 12),
          TextButton.icon(
            onPressed: _showCurrencyConverter,
            icon: Icon(Icons.compare_arrows, size: 16),
            label: Text(
              'View in other currencies',
              style: GoogleFonts.jost(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              foregroundColor: ColorsController.primaryColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShippingOptions(ItemProvider itemProvider) {
    final shippingOptions = [
      {
        'value': 'Home Delivery',
        'title': 'Home Delivery',
        'subtitle': 'You deliver to buyer\'s location',
        'icon': Icons.home,
      },
      {
        'value': 'Cash on Delivery',
        'title': 'Cash on Delivery',
        'subtitle': 'Payment upon delivery',
        'icon': Icons.payment,
      },
      {
        'value': 'Both',
        'title': 'Both Options',
        'subtitle': 'Let buyer choose delivery method',
        'icon': Icons.alt_route,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: shippingOptions.map((option) {
          final isSelected = itemProvider.shippingOption == option['value'];
          
          return InkWell(
            onTap: () {
              itemProvider.updatePricingShipping(shippingOption: option['value'] as String);
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? ColorsController.primaryColor.withOpacity(0.05) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? ColorsController.primaryColor.withOpacity(0.2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      option['icon'] as IconData,
                      size: 20,
                      color: isSelected ? ColorsController.primaryColor : Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['title'] as String,
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? ColorsController.primaryColor : Colors.black,
                          ),
                        ),
                        Text(
                          option['subtitle'] as String,
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio<String>(
                    value: option['value'] as String,
                    groupValue: itemProvider.shippingOption,
                    onChanged: (value) {
                      itemProvider.updatePricingShipping(shippingOption: value);
                    },
                    activeColor: ColorsController.primaryColor,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceSummaryCard() {
    final amount = double.tryParse(_priceController.text) ?? 0;
    final currency = _currencies.firstWhere((c) => c['code'] == _selectedCurrency);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorsController.primaryColor.withOpacity(0.1),
            ColorsController.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorsController.primaryColor.withOpacity(0.3)),
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
              SizedBox(width: 8),
              Text(
                'Price Summary',
                style: GoogleFonts.jost(
                  fontSize: 16,
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
              Text(
                'Item Price',
                style: GoogleFonts.jost(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${currency['symbol']}${amount.toStringAsFixed(_selectedCurrency == 'PKR' ? 0 : 2)}',
                style: GoogleFonts.jost(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pricing Type',
                style: GoogleFonts.jost(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _pricingType == 'Fixed Price' 
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _pricingType,
                  style: GoogleFonts.jost(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _pricingType == 'Fixed Price' ? Colors.blue : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(ItemProvider itemProvider) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Back',
                style: GoogleFonts.jost(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                // Validate price is required for non-give-away items
                if (_pricingType != 'Give Away' && _priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Please enter a price for your item'),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                
                // Update pricing details
                itemProvider.updatePricingShipping(
                  price: _pricingType == 'Give Away' ? 0.0 : double.tryParse(_priceController.text),
                  allowPriceNegotiation: _pricingType == 'Negotiable',
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EnhancedAddPhotosPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsController.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}