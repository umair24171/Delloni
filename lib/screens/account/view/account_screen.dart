import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/account/view/favorite_ads.dart';
import 'package:arabicmarketplace/screens/account/view/help_contact_pag.dart';
import 'package:arabicmarketplace/screens/account/view/language_screen.dart';
import 'package:arabicmarketplace/screens/account/view/my_ads.dart';
import 'package:arabicmarketplace/screens/account/view/notifications_page.dart';
import 'package:arabicmarketplace/screens/account/view/edit_profile_screen.dart';
import 'package:arabicmarketplace/screens/account/view/re_auth_dialog.dart';
import 'package:arabicmarketplace/screens/account/view/terms_conditions.dart';
import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
import 'package:arabicmarketplace/screens/reviews_page/view/reviews_page.dart';
import 'package:arabicmarketplace/screens/account/controller/account_service.dart';
import 'package:arabicmarketplace/screens/auth/view/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Account',
                    style: GoogleFonts.jost(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
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
                              user?.companyName ?? user?.email?.split('@').first.toUpperCase() ?? 'User',
                              style: GoogleFonts.jost(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // User Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: ColorsController.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ColorsController.primaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                user?.type.toUpperCase() ?? 'USER',
                                style: GoogleFonts.jost(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ColorsController.primaryColor,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Rating Stars (placeholder)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star, color: Colors.amber[600], size: 20),
                                Icon(Icons.star, color: Colors.amber[600], size: 20),
                                Icon(Icons.star, color: Colors.amber[600], size: 20),
                                Icon(Icons.star, color: Colors.amber[600], size: 20),
                                Icon(Icons.star, color: Colors.grey[400], size: 20),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Menu Items
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: 'My Profile',
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.business_center_outlined,
                            title: 'My Ads',
                            onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => MyAdsPage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.star_outline,
                            title: 'Favourite Ads',
                            iconColor: ColorsController.primaryColor,
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => FavoriteAds()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.bar_chart_outlined,
                            title: 'Notifications',
                            onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.star_outline,
                            title: 'Reviews',
                            onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewsPage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.help_outline,
                            title: 'Help/Contact Us',
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => HelpContactPage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.info_outline,
                            title: 'Terms & Conditions',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => TermsConditionsPage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.language_outlined,
                            title: 'Select Language',
                            onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => LanguagePage()));
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.logout_outlined,
                            title: 'Logout',
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
                          foregroundColor: Colors.white,
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
                                    'Delete Account',
                                    style: GoogleFonts.jost(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
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
      color: Colors.grey[800],
      child: const Icon(
        Icons.person,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    IconData? icon,
    Color? iconColor,
    required VoidCallback onTap,
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
                    color: iconColor ?? Colors.black,
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
                      color: iconColor ?? Colors.black,
                    ),
                  ),
                ),
                Image.asset('assets/icons/arrow_next.png', height: 14, width: 24)
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
              color: Colors.white,
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
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 40,
                    color: Colors.orange[700],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Logout',
                  style: GoogleFonts.jost(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Are you sure you want to logout from your account?',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
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
                          'Cancel',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
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
                          'Logout',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
              color: Colors.white,
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
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    size: 40,
                    color: Colors.red[600],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Delete Account',
                  style: GoogleFonts.jost(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Warning message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red[600],
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This action cannot be undone!',
                        style: GoogleFonts.jost(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Details
                Text(
                  'Deleting your account will permanently remove:',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // List of things that will be deleted
                Column(
                  children: [
                    _buildDeletionItem('• All your personal information'),
                    _buildDeletionItem('• Your active listings and ads'),
                    _buildDeletionItem('• Message history and conversations'),
                    _buildDeletionItem('• Reviews and ratings'),
                    _buildDeletionItem('• Account preferences and settings'),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Confirmation text
                Text(
                  'Are you absolutely sure you want to proceed?',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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
                          'Cancel',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showFinalDeleteConfirmation(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
              color: Colors.white,
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
                    color: Colors.red[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    size: 40,
                    color: Colors.red[700],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Final Confirmation',
                  style: GoogleFonts.jost(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Type "DELETE" to confirm account deletion',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
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
                    hintText: 'Type DELETE here',
                    hintStyle: GoogleFonts.jost(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[600]!, width: 2),
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
                          'Cancel',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleDeleteAccount(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Delete Forever',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
            color: Colors.grey[600],
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
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showErrorSnackBar(result['message'] ?? 'Logout failed');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred during logout');
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
      _showErrorSnackBar('An error occurred during account deletion');
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
            content: Text('Account deleted successfully'),
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
          _showErrorSnackBar(result['message'] ?? 'Account deletion failed');
        }
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred during account deletion');
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