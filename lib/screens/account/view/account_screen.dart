import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/account/view/currency_page.dart';
import 'package:arabicmarketplace/screens/account/view/favorite_ads.dart';
import 'package:arabicmarketplace/screens/account/view/help_contact_pag.dart';
import 'package:arabicmarketplace/screens/account/view/language_screen.dart';
import 'package:arabicmarketplace/screens/account/view/my_ads.dart';
import 'package:arabicmarketplace/screens/notifications/view/notifications_page.dart';
import 'package:arabicmarketplace/screens/account/view/edit_profile_screen.dart';
import 'package:arabicmarketplace/screens/account/view/re_auth_dialog.dart';
import 'package:arabicmarketplace/screens/account/view/terms_conditions.dart';
import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
import 'package:arabicmarketplace/screens/reviews_page/view/reviews_page.dart';
import 'package:arabicmarketplace/screens/account/controller/account_service.dart';
import 'package:arabicmarketplace/screens/auth/view/login_screen.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arabicmarketplace/main.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AccountService _accountService = AccountService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.account.tr(),
                    style: GoogleFonts.jost(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Section
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        final user = userProvider.currentUser;
                        return Column(
                          children: [
                            // Profile Image
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: user?.profileImage != null
                                    ? Image.network(
                                        user!.profileImage!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            _buildDefaultAvatar(),
                                      )
                                    : _buildDefaultAvatar(),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Name
                            Text(
                              user?.companyName ?? user?.email?.split('@').first.toUpperCase() ?? AppLocalizations.user.tr(),
                              style: GoogleFonts.jost(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // User Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                user?.type.toUpperCase().tr() ?? AppLocalizations.user.tr(),
                                style: GoogleFonts.jost(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Rating Stars (placeholder)
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children: [
                            //     Icon(Icons.star, color: Colors.amber[600], size: 20),
                            //     Icon(Icons.star, color: Colors.amber[600], size: 20),
                            //     Icon(Icons.star, color: Colors.amber[600], size: 20),
                            //     Icon(Icons.star, color: Colors.amber[600], size: 20),
                            //     Icon(Icons.star, color: Colors.grey[400], size: 20),
                            //   ],
                            // ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Dark Mode Toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 33.0),
                      child: Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          final isDark = themeProvider.themeMode == ThemeMode.dark;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.dark_mode, color: isDark ? ColorsController.primaryColor : Colors.grey[700]),
                            title: Text(
                              'Dark Mode'.tr(),
                              style: GoogleFonts.jost(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark ? ColorsController.primaryColor : Colors.black,
                              ),
                            ),
                            trailing: Switch(
                              value: isDark,
                              onChanged: (val) {
                                themeProvider.toggleTheme(val);
                              },
                              activeColor: ColorsController.primaryColor,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Menu Items
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: '${AppLocalizations.myProfile.tr()}',
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.business_center_outlined,
                            title:'${AppLocalizations.myAds.tr()}',
                            onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => MyAdsPage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.star_outline,
                            title: '${AppLocalizations.favouriteAds.tr()}',
                            iconColor: ColorsController.primaryColor,
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => FavoriteAds()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.bar_chart_outlined,
                            title: '${AppLocalizations.notifications.tr()}',
                            onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.star_outline,
                            title: '${AppLocalizations.reviews.tr()}',
                            onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewsPage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.help_outline,
                            title: '${AppLocalizations.helpContactUs.tr()}',
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => HelpContactPage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.info_outline,
                            title: '${AppLocalizations.termsConditions.tr()}',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => TermsConditionsPage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.language_outlined,
                            title: '${AppLocalizations.selectLanguage.tr()}',
                            onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => LanguagePage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.currency_exchange_outlined,
                            title: '${AppLocalizations.currency.tr()}',
                            onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => CurrencyPage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.logout_outlined,
                            title: '${AppLocalizations.logout.tr()}',
                            iconColor: Colors.orange[700],
                            onTap: _showLogoutDialog,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Delete Account Button
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _showDeleteAccountDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffF25252),
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Image.asset('assets/icons/Trash.png', height: 32, width: 32),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${AppLocalizations.deleteAccount.tr()}',
                                    style: GoogleFonts.jost(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context).colorScheme.onBackground,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Space for bottom navigation
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      // color: Theme.of(context).colorScheme.surface,
      child: const Icon(
        Icons.person,
        size: 60,
        // color: Colors.white,
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    IconData? icon,
    Color? iconColor,
    required VoidCallback onTap,
    bool? isDark=false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 22,
                    color: iconColor ?? Theme.of(context).colorScheme.onBackground,
                  ),
                  const SizedBox(width: 16),
                ] else ...[
                  const SizedBox(width: 38),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: iconColor ?? Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
                Transform.rotate(angle: context.locale.languageCode=='ar'?3.14 : 0,child: Image.asset('assets/icons/arrow_next.png', color: Theme.of(context).colorScheme.onBackground,height: 14, width: 24))
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                 '${AppLocalizations.logout.tr()}',
                  style: GoogleFonts.jost(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Text(
                 '${AppLocalizations.areYouSureLogout.tr()}',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 30),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          '${AppLocalizations.cancel.tr()}',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleLogout(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '${AppLocalizations.logout.tr()}',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    size: 40,
                    // color: Theme.of(context).colorScheme.error,
                    // color: Colors.redAccent,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  '${AppLocalizations.deleteAccount.tr()}',
                  style: GoogleFonts.jost(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    // color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Warning message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.errorContainer),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
// color: Colors.red,
                        // color: Theme.of(context).colorScheme.error,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppLocalizations.thisActionCannotUndone.tr()}',
                        style: GoogleFonts.jost(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          // color: Colors.red,
                          // color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Details
                Text(
                  '${AppLocalizations.deletingAccountPermanently.tr()}',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // List of things that will be deleted
                Column(
                  children: [
                    _buildDeletionItem(AppLocalizations.allPersonalInformation.tr()),
                    _buildDeletionItem(AppLocalizations.activeListingsAds.tr()),
                    _buildDeletionItem(AppLocalizations.messageHistoryConversations.tr()),
                    _buildDeletionItem(AppLocalizations.reviewsRatings.tr()),
                    _buildDeletionItem(AppLocalizations.accountPreferencesSettings.tr()),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Confirmation text
                Text(
                  '${AppLocalizations.absolutelySureProceed.tr()}',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 30),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          '${AppLocalizations.cancel.tr()}',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showFinalDeleteConfirmation(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                         '${AppLocalizations.delete.tr()}',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFinalDeleteConfirmation() {
    Navigator.of(context).pop(); // Close previous dialog
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  AppLocalizations.finalConfirmation.tr(),
                  style: GoogleFonts.jost(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Text(
                  AppLocalizations.typeDeleteConfirm.tr(),
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // Confirmation input
                TextFormField(
                  onChanged: (value) {
                    setState(() {
                      // Update state for button enable/disable
                    });
                  },
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.typeDeleteHere.tr(),
                    hintStyle: GoogleFonts.jost(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.errorContainer),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.cancel.tr(),
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleDeleteAccount(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.deleteForever.tr(),
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeletionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.jost(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _handleLogout() async {
    Navigator.of(context).pop(); // Close dialog
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _accountService.logout();
      
      if (result['success']) {
        // Clear user provider
        Provider.of<UserProvider>(context, listen: false).clearUser();
        
        // Navigate to login screen and clear all routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.loggedOutSuccessfully.tr()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showErrorSnackBar(result['message'] ?? AppLocalizations.logoutFailed.tr());
      }
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.logoutError.tr());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleDeleteAccount() async {
    Navigator.of(context).pop(); // Close dialog
    
    setState(() => _isLoading = true);
    
    try {
      // Check if re-authentication is needed
      if (_accountService.needsReauthentication()) {
        setState(() => _isLoading = false);
        
        // Show re-authentication dialog
        await showReAuthDialog(
          context,
          onSuccess: () => _performDeleteAccount(),
          onError: (message) => _showErrorSnackBar(message),
        );
        return;
      }
      
      await _performDeleteAccount();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(AppLocalizations.accountDeletionError.tr());
    }
  }

  Future<void> _performDeleteAccount() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _accountService.deleteAccount();
      
      if (result['success']) {
        // Clear user provider
        Provider.of<UserProvider>(context, listen: false).clearUser();
        
        // Navigate to login screen and clear all routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.accountDeletedSuccessfully.tr()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (result['requiresReauth'] == true) {
          // Show re-authentication dialog
          await showReAuthDialog(
            context,
            onSuccess: () => _performDeleteAccount(),
            onError: (message) => _showErrorSnackBar(message),
          );
        } else {
          _showErrorSnackBar(result['message'] ?? AppLocalizations.accountDeletionFailed.tr());
        }
      }
          } catch (e) {
        _showErrorSnackBar(AppLocalizations.accountDeletionError.tr());
      } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}