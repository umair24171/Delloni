// providers/profile_provider.dart
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:arabicmarketplace/screens/auth/model/auth_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
class ProfileProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // State variables
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  UserModel? _userProfile;
  
  // Form controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // Password visibility
  bool _isPasswordVisible = false;
  
  // Profile image
  XFile? _selectedImage;
  String? _profileImageUrl;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  UserModel? get userProfile => _userProfile;
  bool get isPasswordVisible => _isPasswordVisible;
  XFile? get selectedImage => _selectedImage;
  String? get profileImageUrl => _profileImageUrl;

  ProfileProvider() {
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    try {
      _setLoading(true);
      await _loadUserProfile();
    } catch (e) {
      _setError('Failed to load profile: $e');
      log('ProfileProvider initialization error: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('User not authenticated');
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Create UserModel from data
        _userProfile = UserModel.fromFirestore(userData, null);
        _profileImageUrl = _userProfile?.profileImage;
        
        // Populate form controllers
        _populateFormControllers();
        
        _setLoading(false);
      } else {
        _setError('User profile not found');
      }
    } catch (e) {
      _setError('Failed to load profile: $e');
      log('Error loading user profile: $e');
    }
  }

  // Populate form controllers with user data
  void _populateFormControllers() {
    if (_userProfile == null) return;

    // Use companyName for both individual and company users
    usernameController.text = _userProfile!.companyName ?? '';
    
    // Handle about field - show actual data if exists, empty string if not (placeholder will show)
    String aboutText = _userProfile!.bio ?? '';
    // Don't set placeholder text as actual text value
    if (aboutText.isEmpty || aboutText == 'Tell us about yourself...' || aboutText == 'Tell us about your company...') {
      aboutController.text = '';
    } else {
      aboutController.text = aboutText;
    }
    
    emailController.text = _userProfile!.email;
    phoneController.text = _userProfile!.phone;
    passwordController.text = '************'; // Placeholder for security
  }

  // Pick image from camera or gallery
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        _selectedImage = image;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to pick image: $e');
      log('Error picking image: $e');
    }
  }

  // Upload profile image to Firebase Storage
  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return _profileImageUrl;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final String fileName = 'profile_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('profile_images/$fileName');
      
      final UploadTask uploadTask = ref.putFile(File(_selectedImage!.path));
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      log('Error uploading profile image: $e');
      return null;
    }
  }

  // NEW: Save only the about field (limited editing)
  Future<bool> saveAboutOnly() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setSaving(true);
      _setError(null);

      // Upload profile image if selected (allow profile image changes)
      String? imageUrl = await _uploadProfileImage();
      
      // Prepare update data - only about field and profile image
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update about field
      String aboutText = aboutController.text.trim();
      updateData['bio'] = aboutText.isEmpty ? '' : aboutText;
      
      // Update profile image if changed
      if (imageUrl != null) {
        updateData['profileImage'] = imageUrl;
        _profileImageUrl = imageUrl;
      }

      // Update Firestore document
      await _firestore.collection('users').doc(currentUser.uid).update(updateData);

      // Update local user profile
      _userProfile = _userProfile?.copyWith(
        bio: aboutText.isEmpty ? '' : aboutText,
        profileImage: imageUrl,
      );

      _selectedImage = null; // Clear selected image
      _setSaving(false);
      
      return true;
    } catch (e) {
      _setError('Failed to save about info: $e');
      _setSaving(false);
      log('Error saving about info: $e');
      return false;
    }
  }

  // MODIFIED: Original save profile method (kept for compatibility but limited)
  Future<bool> saveProfile() async {
    // For the new UI, redirect to saveAboutOnly since other fields are read-only
    return await saveAboutOnly();
  }

  // Update email (requires re-authentication) - kept for admin/support use
  Future<void> _updateEmail(String newEmail) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await currentUser.updateEmail(newEmail);
    } catch (e) {
      if (e.toString().contains('requires-recent-login')) {
        throw Exception('Please re-login to update your email address');
      }
      throw e;
    }
  }

  // Update password (still allowed)
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setSaving(true);
      _setError(null);

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );
      
      await currentUser.reauthenticateWithCredential(credential);
      
      // Update password
      await currentUser.updatePassword(newPassword);
      
      _setSaving(false);
      return true;
    } catch (e) {
      _setError('Failed to update password: $e');
      _setSaving(false);
      log('Error updating password: $e');
      return false;
    }
  }

  // Delete profile image
  Future<void> deleteProfileImage() async {
    try {
      _selectedImage = null;
      _profileImageUrl = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete profile image: $e');
    }
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    await _loadUserProfile();
  }

  // MODIFIED: Validate form data (only for about field now)
  bool validateForm() {
    // Since most fields are now read-only, we only validate what can be changed
    // About field is optional, so no validation needed
    
    _setError(null);
    return true;
  }

  // Helper method to validate about field if needed
  bool validateAboutField() {
    // About field validation (optional)
    String aboutText = aboutController.text.trim();
    
    // You can add validation rules here if needed
    // For example, max length check:
    if (aboutText.length > 500) {
      _setError('About section cannot exceed 500 characters');
      return false;
    }
    
    _setError(null);
    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Get user stats (for profile display)
  Future<Map<String, int>> getUserStats() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return {};

    try {
      // Get user's active ads
      final activeAdsQuery = await _firestore
          .collection('items')
          .where('sellerId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'active')
          .get();

      // Get user's total ads
      final totalAdsQuery = await _firestore
          .collection('items')
          .where('sellerId', isEqualTo: currentUser.uid)
          .get();

      // Get user's favorites
      final favoritesQuery = await _firestore
          .collection('userFavorites')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      // Get user's chats
      final chatsQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      return {
        'activeAds': activeAdsQuery.docs.length,
        'totalAds': totalAdsQuery.docs.length,
        'favorites': favoritesQuery.docs.length,
        'chats': chatsQuery.docs.length,
      };
    } catch (e) {
      log('Error getting user stats: $e');
      return {};
    }
  }

  // NEW: Method to check if user can edit personal info (for future admin features)
  bool canEditPersonalInfo() {
    // This could be extended to check user roles/permissions
    // For now, return false since personal info requires support contact
    return false;
  }

  // NEW: Method to get contact support info
  Map<String, String> getContactSupportInfo() {
    return {
      'email': 'support@yourapp.com',
      'phone': '+1 (555) 123-4567',
      'website': 'https://yourapp.com/support',
      'hours': '24/7 Support Available',
    };
  }

  @override
  void dispose() {
    usernameController.dispose();
    aboutController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

// Extended UserModel with additional profile fields
extension UserModelProfile on UserModel {
  String? get bio => null; // You can add this to your UserModel if needed
  
  UserModel copyWithProfile({
    String? name,
    String? companyName,
    String? bio,
    String? email,
    String? phone,
    String? profileImage,
  }) {
    return copyWith(
      // name: name,
      companyName: companyName,
      email: email,
      phone: phone,
      profileImage: profileImage,
    );
  }
}

// UPDATED: Profile validation helper (simplified for limited editing)
class ProfileValidator {
  static String? validateName(String? value) {
    // Since name is read-only, this is for display purposes only
    if (value == null || value.trim().isEmpty) {
      return 'Name is required - Contact support to update';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters - Contact support to update';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    // Since email is read-only, this is for display purposes only
    if (value == null || value.trim().isEmpty) {
      return 'Email is required - Contact support to update';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Invalid email format - Contact support to update';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    // Since phone is read-only, this is for display purposes only
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required - Contact support to update';
    }
    if (value.trim().length < 10) {
      return 'Invalid phone number - Contact support to update';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // NEW: Validate about field
  static String? validateAbout(String? value) {
    // About field is optional
    if (value != null && value.length > 500) {
      return 'About section cannot exceed 500 characters';
    }
    return null;
  }
}