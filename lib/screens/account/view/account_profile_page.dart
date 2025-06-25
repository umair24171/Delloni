// 1. Profile Service - Backend API calls
import 'package:arabicmarketplace/screens/chat/controller/chat_provider.dart';
import 'package:arabicmarketplace/screens/chat/view/messages_screen.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get user profile by ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        // Get user's active ads count
        QuerySnapshot adsSnapshot = await _firestore
            .collection('items')
            .where('sellerId', isEqualTo: userId)
            .where('status', isEqualTo: 'active')
            .get();
            
        userData['activeAdsCount'] = adsSnapshot.docs.length;
        
        // Get user's ratings
        QuerySnapshot ratingsSnapshot = await _firestore
            .collection('ratings')
            .where('sellerId', isEqualTo: userId)
            .get();
            
        if (ratingsSnapshot.docs.isNotEmpty) {
          double totalRating = 0;
          for (var rating in ratingsSnapshot.docs) {
            totalRating += (rating.data() as Map<String, dynamic>)['rating']?.toDouble() ?? 0;
          }
          userData['averageRating'] = totalRating / ratingsSnapshot.docs.length;
          userData['totalReviews'] = ratingsSnapshot.docs.length;
        } else {
          userData['averageRating'] = 0.0;
          userData['totalReviews'] = 0;
        }
        
        return userData;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get user's ads
  Future<List<Map<String, dynamic>>> getUserAds(String userId) async {
    try {
      QuerySnapshot adsSnapshot = await _firestore
          .collection('items')
          .where('sellerId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();
          
      return adsSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>
      }).toList();
    } catch (e) {
      print('Error getting user ads: $e');
      return [];
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(userId).update(updates);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Update profile image
  Future<String?> updateProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      
      await _firestore.collection('users').doc(userId).update({
        'profileImage': downloadUrl,
      });
      
      return downloadUrl;
    } catch (e) {
      print('Error updating profile image: $e');
      return null;
    }
  }

  // Check if user is online (you can implement this based on your online status logic)
  Future<bool> isUserOnline(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        Timestamp? lastSeen = userData['lastSeen'];
        if (lastSeen != null) {
          DateTime lastSeenDate = lastSeen.toDate();
          DateTime now = DateTime.now();
          return now.difference(lastSeenDate).inMinutes < 5; // Consider online if active in last 5 minutes
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}


class AccountProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _userAds = [];
  bool _isLoading = false;
  bool _isOnline = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get userProfile => _userProfile;
  List<Map<String, dynamic>> get userAds => _userAds;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get error => _error;

  // Load user profile
  Future<void> loadUserProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userProfile = await _profileService.getUserProfile(userId);
      _isOnline = await _profileService.isUserOnline(userId);
      
      if (_userProfile == null) {
        _error = 'User profile not found';
      }
    } catch (e) {
      _error = 'Failed to load profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user ads
  Future<void> loadUserAds(String userId) async {
    try {
      _userAds = await _profileService.getUserAds(userId);
      notifyListeners();
    } catch (e) {
      print('Error loading user ads: $e');
    }
  }

  // Update profile
  Future<bool> updateProfile(String userId, Map<String, dynamic> updates) async {
    _isLoading = true;
    notifyListeners();

    try {
      bool success = await _profileService.updateUserProfile(userId, updates);
      if (success) {
        // Update local data
        if (_userProfile != null) {
          _userProfile!.addAll(updates);
        }
      }
      return success;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profile image
  Future<bool> updateProfileImage(String userId, File imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? imageUrl = await _profileService.updateProfileImage(userId, imageFile);
      if (imageUrl != null && _userProfile != null) {
        _userProfile!['profileImage'] = imageUrl;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to update profile image: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods
  bool get isCompany => _userProfile?['type'] == 'company';
  bool get isIndividual => _userProfile?['type'] == 'individual';
  
  String get displayName {
    if (isCompany) {
      return _userProfile?['companyName'] ?? 'Unknown Company';
    } else {
      return _userProfile?['name'] ?? 'Unknown User';
    }
  }

  String get profileImageUrl {
    return _userProfile?['profileImage'] ?? '';
  }

  double get averageRating {
    return _userProfile?['averageRating']?.toDouble() ?? 0.0;
  }

  int get totalReviews {
    return _userProfile?['totalReviews'] ?? 0;
  }

  String get aboutMe {
    if (isCompany) {
      return _userProfile?['aboutUs'] ?? 'No company description available.';
    } else {
      return _userProfile?['aboutMe'] ?? 'No description available.';
    }
  }

  String get memberSince {
    if (_userProfile?['createdAt'] != null) {
      DateTime createdAt = (_userProfile!['createdAt'] as Timestamp).toDate();
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
    return 'Unknown';
  }

  String get responseTime {
    return _userProfile?['responseTime'] ?? 'Usually replies within a few hours';
  }

  String get phoneNumber {
    return _userProfile?['phone'] ?? '';
  }

  String get email {
    return _userProfile?['email'] ?? '';
  }

  int get activeAdsCount {
    return _userProfile?['activeAdsCount'] ?? 0;
  }

  // Clear data
  void clear() {
    _userProfile = null;
    _userAds.clear();
    _isLoading = false;
    _isOnline = false;
    _error = null;
    notifyListeners();
  }
}
class AccountProfilePage extends StatefulWidget {
  final String userId;
  final bool isMyProfile; // true if viewing own profile

  const AccountProfilePage({
    Key? key,
    required this.userId,
    this.isMyProfile = false,
  }) : super(key: key);

  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  bool _showMyAds = true;
  final TextEditingController _aboutController = TextEditingController();
  bool _isEditingAbout = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<AccountProfileProvider>(context, listen: false);
      profileProvider.loadUserProfile(widget.userId);
      profileProvider.loadUserAds(widget.userId);
    });
  }

  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpdateProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final profileProvider = Provider.of<AccountProfileProvider>(context, listen: false);
      await profileProvider.updateProfileImage(widget.userId, File(image.path));
    }
  }

  void _startEditingAbout() {
    final profileProvider = Provider.of<AccountProfileProvider>(context, listen: false);
    _aboutController.text = profileProvider.aboutMe;
    setState(() {
      _isEditingAbout = true;
    });
  }

  Future<void> _saveAbout() async {
    final profileProvider = Provider.of<AccountProfileProvider>(context, listen: false);
    String fieldName = profileProvider.isCompany ? 'aboutUs' : 'aboutMe';
    
    bool success = await profileProvider.updateProfile(widget.userId, {
      fieldName: _aboutController.text,
    });
    
    if (success) {
      setState(() {
        _isEditingAbout = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  // Make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      
      try {
        final Uri phoneUri = Uri(scheme: 'tel', path: '');
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        }
      } catch (e) {
        print('Error opening dialer: $e');
      }
      return;
    }

    try {
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      if (!cleanNumber.startsWith('+')) {
        if (cleanNumber.startsWith('0')) {
          cleanNumber = '+92' + cleanNumber.substring(1);
        } else if (cleanNumber.length >= 10) {
          cleanNumber = '+92' + cleanNumber;
        }
      }

      final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not make phone call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Start chat with user
  Future<void> _startChat(AccountProfileProvider profileProvider) async {
    if (profileProvider.userProfile == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff014700)),
                ),
                SizedBox(height: 16),
                Text(
                  'Starting chat...',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final chatProvider = ChatProvider();
      
      final chatId = await chatProvider.createOrGetChatEnhanced(
        otherUserId: widget.userId,
        otherUserName: profileProvider.displayName,
        otherUserImage: profileProvider.profileImageUrl,
      );

      Navigator.pop(context);

      if (chatId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesScreen(chatId: chatId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: Text(
          'Account',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<AccountProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(profileProvider.error!),
                  ElevatedButton(
                    onPressed: () => profileProvider.loadUserProfile(widget.userId),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (profileProvider.userProfile == null) {
            return const Center(child: Text('Profile not found'));
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      // Profile Image with Online Indicator
                      GestureDetector(
                        onTap: widget.isMyProfile ? _pickAndUpdateProfileImage : null,
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                border: Border.all(color: Colors.grey[300]!, width: 2),
                              ),
                              child: profileProvider.profileImageUrl.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        profileProvider.profileImageUrl,
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey[100],
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              size: 40,
                                              color: Colors.grey[400],
                                            ),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey[100],
                                            ),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[100],
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                            ),
                            // Online indicator
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: profileProvider.isOnline ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                              ),
                            ),
                            // Camera icon for edit (only show on own profile)
                            if (widget.isMyProfile)
                              Positioned(
                                bottom: 0,
                                right: 24,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Profile Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  profileProvider.displayName,
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (profileProvider.userProfile!['isEmailVerified'] == true)
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            
                            // FIXED: Add location for companies under company name
                            if (profileProvider.isCompany && profileProvider.userProfile!['address'] != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      profileProvider.userProfile!['address'],
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            // Star Rating
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < profileProvider.averageRating.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  '(${profileProvider.totalReviews})',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profileProvider.isCompany ? 'Company' : 'Private Seller',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Active since ${profileProvider.memberSince}',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              profileProvider.responseTime,
                              style: GoogleFonts.nunito(
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
                
                // Contact Buttons (only show if not my profile)
                if (!widget.isMyProfile) ...[
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _makePhoneCall(profileProvider.phoneNumber),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  profileProvider.phoneNumber.isNotEmpty 
                                    ? Icons.phone 
                                    : Icons.phone_disabled,
                                  color: profileProvider.phoneNumber.isNotEmpty 
                                    ? Color(0xff014700) 
                                    : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  profileProvider.phoneNumber.isNotEmpty 
                                    ? 'Call' 
                                    : 'No Phone',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: profileProvider.phoneNumber.isNotEmpty 
                                      ? Color(0xff014700) 
                                      : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _startChat(profileProvider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Color(0xff014700),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Chat',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
                
                // FIXED: Navigation Tabs - Show appropriate labels
                if (profileProvider.isCompany || (widget.isMyProfile && profileProvider.isIndividual)) ...[
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _showMyAds = true),
                        child: Text(
                          widget.isMyProfile ? 'My ads' : 'Ads', // FIXED: Show "Ads" when viewing someone else's profile
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: _showMyAds ? FontWeight.w600 : FontWeight.w400,
                            color: _showMyAds ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Only show Details tab for companies OR individual's own profile
                      if (profileProvider.isCompany || (widget.isMyProfile && profileProvider.isIndividual))
                        GestureDetector(
                          onTap: () => setState(() => _showMyAds = false),
                          child: Text(
                            'Details',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: !_showMyAds ? FontWeight.w600 : FontWeight.w400,
                              color: !_showMyAds ? Colors.black : Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ] else if (!widget.isMyProfile && profileProvider.isIndividual) ...[
                  // FIXED: For individual sellers (not own profile), show "Ads" instead of "My ads"
                  Text(
                    'Ads',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Content based on selected tab or default to ads for individuals
                Expanded(
                  child: _buildContent(profileProvider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(AccountProfileProvider profileProvider) {
    // For individual sellers (not own profile), always show ads
    if (!widget.isMyProfile && profileProvider.isIndividual) {
      return _buildAdsSection(profileProvider);
    }
    
    // For companies or own profile, switch based on tab
    return _showMyAds ? _buildAdsSection(profileProvider) : _buildDetailsSection(profileProvider);
  }

  // FIXED: Renamed from _buildMyAdsSection to _buildAdsSection for clarity
  Widget _buildAdsSection(AccountProfileProvider profileProvider) {
    if (profileProvider.userAds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.isMyProfile ? 'No active ads' : 'No ads posted yet',
              style: GoogleFonts.nunito(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isMyProfile 
                  ? 'Start selling to see your ads here'
                  : 'This user hasn\'t posted any ads yet',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: profileProvider.userAds.length,
      itemBuilder: (context, index) {
        final ad = profileProvider.userAds[index];
        return _buildAdItem(ad);
      },
    );
  }

  Widget _buildAdItem(Map<String, dynamic> ad) {
    return InkWell(
      onTap: () {
        // Navigate to product detail when ad is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: ad['id']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ad['imageUrls'] != null && (ad['imageUrls'] as List).isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ad['imageUrls'][0],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image, color: Colors.grey[400]);
                        },
                      ),
                    )
                  : Icon(Icons.image, color: Colors.grey[400]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad['itemTitle'] ?? 'No Title',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PKR ${ad['price']?.toStringAsFixed(0) ?? '0'}',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        ad['condition'] ?? 'Unknown',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTimeAgo(ad['createdAt']),
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get time ago
  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Recently';
    
    try {
      DateTime postDate;
      if (createdAt is Timestamp) {
        postDate = createdAt.toDate();
      } else if (createdAt is DateTime) {
        postDate = createdAt;
      } else {
        return 'Recently';
      }
      
      final now = DateTime.now();
      final difference = now.difference(postDate);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildDetailsSection(AccountProfileProvider profileProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.black, size: 24),
            const SizedBox(width: 12),
            Text(
              profileProvider.isCompany ? 'About us' : 'About me',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            if (widget.isMyProfile)
              IconButton(
                onPressed: _isEditingAbout ? _saveAbout : _startEditingAbout,
                icon: Icon(_isEditingAbout ? Icons.save : Icons.edit),
                color: Colors.blue,
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // ENHANCED: Show additional company details if available
        if (profileProvider.isCompany) ...[
          _buildDetailRow('Email', profileProvider.email),
          _buildDetailRow('Phone', profileProvider.phoneNumber),
          if (profileProvider.userProfile!['registerId'] != null)
            _buildDetailRow('Register ID', profileProvider.userProfile!['registerId']),
          if (profileProvider.userProfile!['address'] != null)
            _buildDetailRow('Address', profileProvider.userProfile!['address']),
          const SizedBox(height: 20),
        ],
        
        Expanded(
          child: _isEditingAbout
              ? TextField(
                  controller: _aboutController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: profileProvider.isCompany 
                        ? 'Tell customers about your company...'
                        : 'Tell others about yourself...',
                  ),
                )
              : SingleChildScrollView(
                  child: Text(
                    profileProvider.aboutMe,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}