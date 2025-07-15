import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/auth/controller/auth_provider.dart';
import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
import 'package:arabicmarketplace/screens/custom_bottom_bar.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String selectedLanguage = 'English';
  String selectedCurrency = 'SYP';
  bool isLoading = false;
  bool _isInitialized = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeCurrentLanguage();
      _isInitialized = true;
    }
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

  void _initializeCurrentLanguage() {
    final currentLocale = context.locale;
    final currentLang = currentLocale.languageCode == 'ar' ? 'العربية' : 'English';
    
    if (mounted) {
      setState(() {
        selectedLanguage = currentLang;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.languageCurrency.tr(),
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                                  // Language Section
              Text(
                AppLocalizations.selectYourLanguage.tr(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
                    const SizedBox(height: 20),
                    
                    // Language Options
                    _buildLanguageOption('English', 'en'),
                    const SizedBox(height: 16),
                    _buildLanguageOption('العربية', 'ar'),
                    
                    const SizedBox(height: 40),
                    
                                  // Currency Section
              Text(
                AppLocalizations.selectYourCurrency.tr(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
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
                  ],
                ),
              ),
            ),
            
            // Save Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        AppLocalizations.saveChanges.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, String languageCode) {
    final bool isSelected = selectedLanguage == language;
    
    return GestureDetector(
      onTap: () => _selectLanguage(language, languageCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ColorsController.primaryColor.withOpacity(0.1) : Colors.white,
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
            Expanded(
              child: Text(
                language,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? ColorsController.primaryColor : Colors.black,
                ),
              ),
            ),
            if (language == 'English')
              Text(
                '🇺🇸',
                style: TextStyle(fontSize: 24),
              )
            else
              Text(
                '🇸🇦',
                style: TextStyle(fontSize: 24),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(Map<String, String> currency) {
    final bool isSelected = selectedCurrency == currency['code'];
    
    return GestureDetector(
      onTap: () => _selectCurrency(currency['code']!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ColorsController.primaryColor.withOpacity(0.1) : Colors.white,
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
            Text(
              currency['flag']!,
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency['name']!,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? ColorsController.primaryColor : Colors.black,
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
          ],
        ),
      ),
    );
  }

  void _selectLanguage(String language, String languageCode) async {
    if (selectedLanguage == language) return;

    setState(() {
      selectedLanguage = language;
    });

    // Immediately change the app language for preview
    await context.setLocale(Locale(languageCode));
  }

  void _selectCurrency(String currencyCode) async {
    if (selectedCurrency == currencyCode) return;

    setState(() {
      selectedCurrency = currencyCode;
    });

    // Save currency preference
    await _saveCurrencyPreference(currencyCode);
  }

  Future<void> _saveCurrencyPreference(String currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_currency', currency);
    } catch (e) {
      print('Error saving currency preference: $e');
    }
  }

  Future<void> _savePreferences() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // Save language to user preferences in Firestore
      final authService = AuthService();
      final user = authService.getCurrentUser();
      
      if (user != null) {
        await authService.updateUserLanguage(user.uid, selectedLanguage);
        
        // Update the UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.refreshUser();
      }

      // Save to local storage for persistence
      final prefs = await SharedPreferences.getInstance();
      final languageCode = selectedLanguage == 'العربية' ? 'ar' : 'en';
      await prefs.setString('selected_language', languageCode);

      // Save currency preference
      await _saveCurrencyPreference(selectedCurrency);

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.languageCurrencySavedSuccessfully.tr()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomBottomNavigationBar()),
        );
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.errorSavingPreferences.tr(args: ['$e'])),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
