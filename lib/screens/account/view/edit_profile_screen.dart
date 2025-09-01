// screens/profile_screen.dart - Updated with Backend Integration
import 'package:arabicmarketplace/screens/account/controller/profile_provider.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late ProfileProvider _profileProvider;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _profileProvider = ProfileProvider();
  }

  @override
  void dispose() {
    _profileProvider.dispose();
    super.dispose();
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.support_agent, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Contact Support'.tr(),
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.toChangePersonalInfoContactSupport.tr(),
              style: GoogleFonts.jost(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 16),
            _buildContactOption(
              icon: Icons.email,
              title: AppLocalizations.emailSupport.tr(),
              subtitle: AppLocalizations.supportEmail.tr(),
              onTap: () {
                // Add email launch functionality
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 8),
            _buildContactOption(
              icon: Icons.phone,
              title: AppLocalizations.phoneSupport.tr(),
              subtitle: AppLocalizations.supportPhone.tr(),
              onTap: () {
                // Add phone launch functionality
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 8),
            _buildContactOption(
              icon: Icons.chat,
              title: AppLocalizations.supportLiveChat.tr(),
              subtitle: AppLocalizations.available247.tr(),
              onTap: () {
                // Add chat functionality
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _profileProvider,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
           surfaceTintColor:Theme.of(context).appBarTheme.backgroundColor ,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onBackground, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.myProfile.tr(),
            style: GoogleFonts.jost(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          centerTitle: false,
          actions: [
            Consumer<ProfileProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onBackground),
                  onPressed: provider.isLoading ? null : () => provider.refreshProfile(),
                  tooltip: AppLocalizations.refresh.tr(),
                );
              },
            ),
          ],
        ),
        body: Consumer<ProfileProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      AppLocalizations.loadingProfile.tr(),
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      provider.error!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refreshProfile(),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Profile Image Section
                      _buildProfileImageSection(provider),
                      
                      const SizedBox(height: 40),
                      
                      // Read-only Name Field with Support Info
                      _buildReadOnlyTextField(
                        icon: Icons.person_outline,
                        hintText: provider.userProfile?.type == 'company' ? 'Company Name'.tr() : 'Name'.tr(),
                        controller: provider.usernameController,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Editable About Field
                      _buildEditableAboutField(provider),
                      
                      const SizedBox(height: 16),
                      
                      // Read-only Email Field with Support Info
                      _buildReadOnlyTextField(
                        icon: Icons.email_outlined,
                        hintText: 'Email'.tr(),
                        controller: provider.emailController,
                      ),
                      
                      // const SizedBox(height: 16),
                      
                      // Read-only Password Field
                      // _buildPasswordField(provider),
                      
                      const SizedBox(height: 16),
                      
                      // Read-only Phone Field with Support Info
                      _buildReadOnlyTextField(
                        icon: Icons.phone_outlined,
                        hintText: 'Phone number'.tr(),
                        controller: provider.phoneController,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Contact Support Info Card
                      // _buildContactSupportCard(),
                      
                      const SizedBox(height: 16),
                      
                      // User Stats Section
                      // _buildUserStatsSection(provider),
                      
                      const SizedBox(height: 16),
                      
                      // Save About Changes Button (only for about field)
                      _buildSaveAboutButton(provider),
                      
                      const SizedBox(height: 20),
                      
                      // Change Password Button
                      _buildChangePasswordButton(),
                      
                      const SizedBox(height: 20),
                      
                      // Contact Support Button
                      // _buildContactSupportButton(),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(ProfileProvider provider) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: ClipOval(
            child: _buildProfileImage(provider),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showImageSourceDialog(provider),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red[400],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(ProfileProvider provider) {
    // Priority: Selected image > Profile image URL > Default icon
    if (provider.selectedImage != null) {
      return Image.file(
        File(provider.selectedImage!.path),
        fit: BoxFit.cover,
        width: 116,
        height: 116,
      );
    } else if (provider.profileImageUrl != null && provider.profileImageUrl!.isNotEmpty) {
      return Image.network(
        provider.profileImageUrl!,
        fit: BoxFit.cover,
        width: 116,
        height: 116,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[800],
            child: const Icon(
              Icons.person,
              size: 70,
              color: Colors.white,
            ),
          );
        },
      );
    } else {
      return Container(
        color: Colors.grey[800],
        child: const Icon(
          Icons.person,
          size: 70,
          color: Colors.white,
        ),
      );
    }
  }

 // If you want to make other fields editable, replace _buildReadOnlyTextField with:
Widget _buildReadOnlyTextField({
  required IconData icon,
  required String hintText,
  required TextEditingController controller,
  bool obscureText = false,
  TextInputType keyboardType = TextInputType.text,
  VoidCallback? onToggleVisibility,
  bool showToggle = false,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white, // White background for editable
      borderRadius: BorderRadius.circular(27),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.jost(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        constraints: BoxConstraints(minHeight: 50),
        prefixIcon: Icon(icon, color: Colors.green[700], size: 20),
        suffixIcon: showToggle ? GestureDetector(
          onTap: onToggleVisibility,
          child: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
            size: 20,
          ),
        ) : null,
        hintText: hintText,
        hintStyle: GoogleFonts.jost(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[500],
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
  );
}


 Widget _buildEditableAboutField(ProfileProvider provider) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white, // Changed from grey to white (editable)
      borderRadius: BorderRadius.circular(27),
      border: Border.all(color: Colors.grey[300]!), // Add border for clarity
    ),
    child: TextFormField(
      controller: provider.aboutController,
      maxLines: 3,
      style: GoogleFonts.jost(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        constraints: BoxConstraints(minHeight: 50),
        prefixIcon: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Icon(Icons.info_outline, color: Colors.green[700], size: 20), // Changed color
        ),
        hintText: provider.userProfile?.type == 'company' 
            ? AppLocalizations.tellUsAboutYourCompany.tr()
            : AppLocalizations.tellUsAboutYourself.tr(),
        hintStyle: GoogleFonts.jost(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
  );
}


  Widget _buildPasswordField(ProfileProvider provider) {
    return Container(
      decoration: BoxDecoration(
        // color: Colors.grey[200], // Read-only color
        // borderRadius: BorderRadius.circular(27),
          borderRadius: BorderRadius.circular(27),
      border: Border.all(color: Colors.grey[300]!), // Add border for clarity
      ),
      child: TextFormField(
        controller: provider.passwordController,
        obscureText: !provider.isPasswordVisible,
        // readOnly: true,
        style: GoogleFonts.jost(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
        decoration: InputDecoration(
          constraints: BoxConstraints(maxHeight: 50),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600], size: 20),
          suffixIcon: GestureDetector(
            onTap: () => provider.togglePasswordVisibility(),
            child: Icon(
              provider.isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
          hintText: 'Enter password to change',
          hintStyle: GoogleFonts.jost(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  // Widget _buildContactSupportCard() {
  //   return Container(
  //     padding: EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.blue[50],
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.blue[200]!),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
  //         SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Need to update your information?',
  //                 style: GoogleFonts.jost(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w600,
  //                   color: Colors.blue[800],
  //                 ),
  //               ),
  //               SizedBox(height: 4),
  //               Text(
  //                 'Contact our support team to change your personal details.',
  //                 style: GoogleFonts.jost(
  //                   fontSize: 12,
  //                   color: Colors.blue[700],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue[600]),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildUserStatsSection(ProfileProvider provider) {
  //   return FutureBuilder<Map<String, int>>(
  //     future: provider.getUserStats(),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return Container(
  //           padding: EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             color: Colors.grey[100],
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: Center(child: CircularProgressIndicator()),
  //         );
  //       }

  //       final stats = snapshot.data ?? {};
  //       return Container(
  //         padding: EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: Colors.grey[100],
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: Column(
  //           children: [
  //             Text(
  //               'Profile Stats',
  //               style: GoogleFonts.jost(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w600,
  //                 color: Colors.black,
  //               ),
  //             ),
  //             SizedBox(height: 12),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceAround,
  //               children: [
  //                 _buildStatItem('Active Ads', stats['activeAds'] ?? 0),
  //                 _buildStatItem('Total Ads', stats['totalAds'] ?? 0),
  //                 _buildStatItem('Favorites', stats['favorites'] ?? 0),
  //                 _buildStatItem('Chats', stats['chats'] ?? 0),
  //               ],
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Add this method to save all changes:
Future<void> _saveAllChanges(ProfileProvider provider) async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  final success = await provider.saveProfile(); // This should save all fields
  
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile updated successfully!',
          style: GoogleFonts.jost(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.error ?? 'Failed to update profile',
          style: GoogleFonts.jost(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

 Widget _buildSaveAboutButton(ProfileProvider provider) {
  return SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: provider.isSaving ? null : () => _saveAllChanges(provider),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(27),
        ),
      ),
      child: provider.isSaving
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  AppLocalizations.saving.tr(),
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Text(
              'Save Changes'.tr(), // Update all profile information
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  );
}

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: () => _showChangePasswordDialog(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.green[700]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: Text(
          AppLocalizations.changePassword.tr(),
          style: GoogleFonts.jost(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.green[700],
          ),
        ),
      ),
    );
  }

  // Widget _buildContactSupportButton() {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 54,
  //     child: OutlinedButton(
  //       onPressed: _showContactSupportDialog,
  //       style: OutlinedButton.styleFrom(
  //         side: BorderSide(color: Colors.blue[600]!),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(27),
  //         ),
  //       ),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Icon(Icons.support_agent, color: Colors.blue[600], size: 20),
  //           SizedBox(width: 8),
  //           Text(
  //             'Contact Support',
  //             style: GoogleFonts.jost(
  //               fontSize: 16,
  //               fontWeight: FontWeight.w600,
  //               color: Colors.blue[600],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _showImageSourceDialog(ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.selectProfilePicture.tr(),
                style: GoogleFonts.jost(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: AppLocalizations.camera.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      provider.pickImage(ImageSource.camera);
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: AppLocalizations.gallery.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      provider.pickImage(ImageSource.gallery);
                    },
                  ),
                  if (provider.profileImageUrl != null)
                    _buildImageSourceOption(
                      icon: Icons.delete,
                      label: AppLocalizations.remove.tr(),
                      onTap: () {
                        Navigator.pop(context);
                        provider.deleteProfileImage();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.jost(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAboutChanges(ProfileProvider provider) async {
    // Only save the about field
    final success = await provider.saveAboutOnly();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.aboutInfoUpdatedSuccessfully.tr(),
            style: GoogleFonts.jost(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? AppLocalizations.failedToUpdateAboutInfo.tr(),
            style: GoogleFonts.jost(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isCurrentPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness != Brightness.dark
              ? Colors.white
              : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            AppLocalizations.changePassword.tr(),
            style: GoogleFonts.jost(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current Password
              TextField(
                controller: currentPasswordController,
                obscureText: !isCurrentPasswordVisible,
                style: GoogleFonts.jost(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Current Password".tr(),
                  labelStyle: GoogleFonts.jost(fontSize: 14,),
                  prefixIcon: Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isCurrentPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () => setState(() => isCurrentPasswordVisible = !isCurrentPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 16),
              
              // New Password
              TextField(
                controller: newPasswordController,
                obscureText: !isNewPasswordVisible,
                style: GoogleFonts.jost(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "New Password".tr(),
                  labelStyle: GoogleFonts.jost(fontSize: 14),
                  prefixIcon: Icon(Icons.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () => setState(() => isNewPasswordVisible = !isNewPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 16),
              
              // Confirm Password
              TextField(
                controller: confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                style: GoogleFonts.jost(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Confirm Password".tr(),
                  labelStyle: GoogleFonts.jost(fontSize: 14),
                  prefixIcon: Icon(Icons.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                currentPasswordController.dispose();
                newPasswordController.dispose();
                confirmPasswordController.dispose();
              },
              child: Text(
                AppLocalizations.cancel.tr(),
                style: GoogleFonts.jost(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Consumer<ProfileProvider>(
              builder: (context, provider, child) => TextButton(
                onPressed: provider.isSaving ? null : () async {
                  // Validate inputs
                  if (currentPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.pleaseEnterCurrentPassword.tr())),
                    );
                    return;
                  }
                  
                  if (newPasswordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.newPasswordMustBe6Characters.tr())),
                    );
                    return;
                  }
                  
                  if (newPasswordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.passwordsDoNotMatch.tr())),
                    );
                    return;
                  }

                  // Update password
                  final success = await provider.updatePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );

                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.passwordUpdatedSuccessfully.tr()),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.error ?? AppLocalizations.failedToUpdatePassword.tr()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }

                  currentPasswordController.dispose();
                  newPasswordController.dispose();
                  confirmPasswordController.dispose();
                },
                child: provider.isSaving 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        AppLocalizations.update.tr(),
                        style: GoogleFonts.jost(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Required imports at the top of the file:
/*
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/profile_provider.dart';
import '../providers/user_provider.dart';
import 'dart:io';
*/