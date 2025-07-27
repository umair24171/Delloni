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
  bool isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeCurrentLanguage();
      _isInitialized = true;
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
      // backgroundColor: Colors.white,
      appBar: AppBar(
        // backgroundColor: Colors.white,
         surfaceTintColor:Theme.of(context).appBarTheme.backgroundColor ,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.selectLanguage.tr(),
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            // color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(ColorsController.primaryColor),
                ),
              )
            : SingleChildScrollView(
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
                        // color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Language Options
                    _buildLanguageOption('English', 'en'),
                    const SizedBox(height: 16),
                    _buildLanguageOption('العربية', 'ar'),
                    
                    const SizedBox(height: 20),
                  ],
                ),
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

  void _selectLanguage(String language, String languageCode) async {
    if (selectedLanguage == language || isLoading) return;

    setState(() {
      selectedLanguage = language;
      isLoading = true;
    });

    try {
      // Change the app language immediately
      await context.setLocale(Locale(languageCode));
      
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
      await prefs.setString('selected_language', languageCode);

      if (mounted) {
        // Navigate to home screen automatically
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
            content: Text('Error changing language'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}