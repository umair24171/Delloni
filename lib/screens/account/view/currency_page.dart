import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({Key? key}) : super(key: key);

  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  String selectedCurrency = 'SYP';
  bool isChanging = false;
  String changingCurrency = '';

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'SYP', 'name': 'Syrian Pound', 'symbol': 'ل.س', 'flag': '🇸🇾'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString('preferred_currency') ?? 'SYP';
      setState(() {
        selectedCurrency = savedCurrency;
      });
    } catch (e) {
      print('Error loading currency preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.selectYourCurrency.tr(),
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Currency Section
              Text(
                AppLocalizations.selectYourCurrency.tr(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              
              // Currency Options
              ..._currencies.map((currency) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCurrencyOption(currency),
                );
              }).toList(),
              
              const SizedBox(height: 40),
              
              // Info Text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.pricesDisplayedSypConverted.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Auto-save indicator
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Changes are saved automatically',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(Map<String, String> currency) {
    final bool isSelected = selectedCurrency == currency['code'];
    final bool isLoading = isChanging && changingCurrency == currency['code'];
    
    return GestureDetector(
      onTap: isChanging ? null : () => _selectCurrency(currency['code']!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? ColorsController.primaryColor.withOpacity(0.1) 
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ColorsController.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Radio button indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? ColorsController.primaryColor : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorsController.primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Flag
            Text(
              currency['flag']!,
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            
            // Currency info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency['name']!,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? ColorsController.primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    '${currency['symbol']} (${currency['code']})',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Loading indicator for the currency being changed
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(ColorsController.primaryColor),
                ),
              )
            else if (isSelected)
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

  Future<void> _selectCurrency(String currencyCode) async {
    // Don't change if already selected
    if (selectedCurrency == currencyCode) return;
    
    setState(() {
      isChanging = true;
      changingCurrency = currencyCode;
    });

    try {
      // Save to preferences immediately
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_currency', currencyCode);

      // Update UI
      setState(() {
        selectedCurrency = currencyCode;
        isChanging = false;
        changingCurrency = '';
      });

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Currency changed to ${_currencies.firstWhere((c) => c['code'] == currencyCode)['name']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      // Optional: Add haptic feedback
      // HapticFeedback.lightImpact();
      
    } catch (e) {
      setState(() {
        isChanging = false;
        changingCurrency = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Error changing currency. Please try again.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}