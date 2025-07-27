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

  // NEW: Editing mode toggle
  bool _isEditingMode = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  UserModel? get userProfile => _userProfile;
  bool get isPasswordVisible => _isPasswordVisible;
  XFile? get selectedImage => _selectedImage;
  String? get profileImageUrl => _profileImageUrl;
  bool get isEditingMode => _isEditingMode;

  ProfileProvider() {
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    try {
      _setLoading(true);
      await _loadUserProfile();
    } catch (e) {
      _setError('Failed to load profile: $e');
      print('ProfileProvider initialization error: $e');
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

  void toggleEditingMode() {
    _isEditingMode = !_isEditingMode;
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
      print('Error loading user profile: $e');
    }
  }

  // Populate form controllers with user data
  void _populateFormControllers() {
    if (_userProfile == null) return;

    // Use companyName for both individual and company users
    usernameController.text = _userProfile!.companyName ?? '';
    
    // Handle about field - show actual data if exists, empty string if not
    String aboutText = _userProfile!.bio ?? '';
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
      print('Error picking image: $e');
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
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // NEW: Complete profile save method
  Future<bool> saveProfileChanges() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('User not authenticated');
      return false;
    }

    // Validate all form data
    if (!validateForm()) {
      return false;
    }

    try {
      _setSaving(true);
      _setError(null);

      // Upload profile image if selected
      String? imageUrl = await _uploadProfileImage();
      
      // Prepare update data for all fields
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update all editable fields
      String nameText = usernameController.text.trim();
      String aboutText = aboutController.text.trim();
      String emailText = emailController.text.trim();
      String phoneText = phoneController.text.trim();

      // Update Firestore fields
      if (nameText.isNotEmpty) {
        updateData['companyName'] = nameText;
      }
      
      updateData['bio'] = aboutText.isEmpty ? '' : aboutText;
      
      if (emailText.isNotEmpty && emailText != _userProfile?.email) {
        // Update email in both Auth and Firestore
        await _updateEmailIfChanged(emailText);
        updateData['email'] = emailText;
      }
      
      if (phoneText.isNotEmpty) {
        updateData['phone'] = phoneText;
      }
      
      // Update profile image if changed
      if (imageUrl != null) {
        updateData['profileImage'] = imageUrl;
        _profileImageUrl = imageUrl;
      }

      // Update Firestore document
      await _firestore.collection('users').doc(currentUser.uid).update(updateData);

      // Update local user profile
      _userProfile = _userProfile?.copyWith(
        companyName: nameText.isNotEmpty ? nameText : _userProfile?.companyName,
        email: emailText.isNotEmpty ? emailText : _userProfile?.email,
        phone: phoneText.isNotEmpty ? phoneText : _userProfile?.phone,
        profileImage: imageUrl ?? _userProfile?.profileImage,
      );

      _selectedImage = null; // Clear selected image
      _setSaving(false);
      
      return true;
    } catch (e) {
      _setError('Failed to save profile: $e');
      _setSaving(false);
      print('Error saving profile: $e');
      return false;
    }
  }

  // KEPT: Save only about field and profile image (for limited editing mode)
  Future<bool> saveAboutOnly() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setSaving(true);
      _setError(null);

      // Upload profile image if selected
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
        profileImage: imageUrl ?? _userProfile?.profileImage,
      );

      _selectedImage = null; // Clear selected image
      _setSaving(false);
      
      return true;
    } catch (e) {
      _setError('Failed to save about info: $e');
      _setSaving(false);
      print('Error saving about info: $e');
      return false;
    }
  }

  // UPDATED: Flexible save profile method
  Future<bool> saveProfile() async {
    // Use comprehensive save method by default
    return await saveProfileChanges();
  }

  // Helper method to update email if changed
  Future<void> _updateEmailIfChanged(String newEmail) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.email == newEmail) return;

    try {
      // Note: This might require re-authentication for security
      await currentUser.updateEmail(newEmail);
    } catch (e) {
      if (e.toString().contains('requires-recent-login')) {
        // Handle re-authentication requirement
        throw Exception('Email update requires recent login. Please sign out and sign in again, then try updating your email.');
      }
      throw e;
    }
  }

  // Update password
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
      print('Error updating password: $e');
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

  // UPDATED: Comprehensive form validation
  bool validateForm() {
    _setError(null);
    
    // Validate name/company name
    String nameText = usernameController.text.trim();
    if (nameText.isEmpty) {
      _setError('Name/Company name is required');
      return false;
    }
    if (nameText.length < 2) {
      _setError('Name must be at least 2 characters');
      return false;
    }
    
    // Validate email
    String emailText = emailController.text.trim();
    if (emailText.isEmpty) {
      _setError('Email is required');
      return false;
    }
    if (!_isValidEmail(emailText)) {
      _setError('Please enter a valid email address');
      return false;
    }
    
    // Validate phone
    String phoneText = phoneController.text.trim();
    if (phoneText.isEmpty) {
      _setError('Phone number is required');
      return false;
    }
    if (phoneText.length < 10) {
      _setError('Please enter a valid phone number');
      return false;
    }
    
    // Validate about field (optional but has max length)
    String aboutText = aboutController.text.trim();
    if (aboutText.length > 500) {
      _setError('About section cannot exceed 500 characters');
      return false;
    }
    
    return true;
  }

  // Validate only about field
  bool validateAboutField() {
    String aboutText = aboutController.text.trim();
    
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

  // Get user stats
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
      print('Error getting user stats: $e');
      return {};
    }
  }

  // UPDATED: Flexible editing permissions
  bool canEditPersonalInfo() {
    // Return true to allow direct editing
    // You can add role-based permissions here if needed
    return true;
  }

  // Contact support info (for cases where support is still needed)
  Map<String, String> getContactSupportInfo() {
    return {
      'email': 'support@yourapp.com',
      'phone': '+1 (555) 123-4567',
      'website': 'https://yourapp.com/support',
      'hours': '24/7 Support Available',
    };
  }

  // NEW: Reset form to original values
  void resetForm() {
    _populateFormControllers();
    _selectedImage = null;
    _setError(null);
    notifyListeners();
  }

  // NEW: Check if form has unsaved changes
  bool hasUnsavedChanges() {
    if (_userProfile == null) return false;
    
    return usernameController.text.trim() != (_userProfile!.companyName ?? '') ||
           aboutController.text.trim() != (_userProfile!.bio ?? '') ||
           emailController.text.trim() != _userProfile!.email ||
           phoneController.text.trim() != _userProfile!.phone ||
           _selectedImage != null;
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

// UPDATED: Enhanced UserModel extension
extension UserModelProfile on UserModel {
  String? get bio {
    // Add this field to your UserModel if it doesn't exist
    // For now, return empty string or add bio field to UserModel
    return ''; // Replace with actual bio field
  }
  
  UserModel copyWithProfile({
    String? name,
    String? companyName,
    String? bio,
    String? email,
    String? phone,
    String? profileImage,
  }) {
    return copyWith(
      companyName: companyName,
      email: email,
      phone: phone,
      profileImage: profileImage,
    );
  }
}

// UPDATED: Comprehensive validation helper
class ProfileValidator {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (value.trim().length < 10) {
      return 'Please enter a valid phone number';
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

  static String? validateAbout(String? value) {
    if (value != null && value.length > 500) {
      return 'About section cannot exceed 500 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.trim().isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}