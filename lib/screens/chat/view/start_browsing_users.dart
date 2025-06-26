// screens/start_browsing_page.dart - Localized
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:arabicmarketplace/screens/chat/controller/chat_provider.dart';
import 'package:arabicmarketplace/screens/chat/view/messages_screen.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart'; // Add this import
import 'package:easy_localization/easy_localization.dart'; // Add this import

class StartBrowsingUsersPage extends StatefulWidget {
  const StartBrowsingUsersPage({Key? key}) : super(key: key);

  @override
  State<StartBrowsingUsersPage> createState() => _StartBrowsingUsersPageState();
}

class _StartBrowsingUsersPageState extends State<StartBrowsingUsersPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late StartBrowsingProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = StartBrowsingProvider();
    _provider.loadUsers();

    // Setup scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _provider.loadMoreUsers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.browseUsers.tr(), // Using existing key
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        body: Consumer<StartBrowsingProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => provider.searchUsers(value),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.search
                          .tr(), // Using existing key
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                // Users List
                Expanded(child: _buildUsersList(provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUsersList(StartBrowsingProvider provider) {
    if (provider.isLoading && provider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              AppLocalizations.loading.tr(), // Using existing key
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    log('error is ${provider.error}');

    if (provider.error != null && provider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(provider.error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadUsers(),
              child: Text('Retry'), // Simple word
            ),
          ],
        ),
      );
    }

    if (provider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              AppLocalizations.noReviewsYet
                  .tr(), // Using existing key creatively
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshUsers(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.users.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.users.length) {
            return _buildLoadingItem();
          }

          final user = provider.users[index];
          return _buildUserItem(user);
        },
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    final userName = user['type'] == 'company'
        ? (user['companyName'] ?? 'Unknown Company')
        : (user['name'] ?? 'Unknown User');
    final userImage = user['profileImage'] ?? '';
    final userType = user['type'] ?? 'individual';
    final isOnline = user['isOnline'] ?? false;
    final lastSeen = user['lastSeen'] as Timestamp?;

    return InkWell(
      onTap: () => _startChatWithUser(user),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Profile Image with Online Indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  child: userImage.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            userImage,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.grey[600],
                              );
                            },
                          ),
                        )
                      : Icon(Icons.person, size: 32, color: Colors.grey[600]),
                ),
                // Online indicator
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: 16),

            // User Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Type
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: userType == 'company'
                              ? Colors.blue[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          userType == 'company'
                              ? AppLocalizations.company.tr()
                              : AppLocalizations.individual
                                    .tr(), // Using existing keys
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: userType == 'company'
                                ? Colors.blue[800]
                                : Colors.green[800],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),

                  // Last Seen
                  Text(
                    _getLastSeenText(isOnline, lastSeen),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isOnline ? Colors.green : Colors.grey[600],
                    ),
                  ),

                  // User Stats
                  if (user['activeAdsCount'] != null ||
                      user['averageRating'] != null) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        if (user['activeAdsCount'] != null) ...[
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${user['activeAdsCount']} ${AppLocalizations.myAds.tr().toLowerCase()}', // Using existing key
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (user['activeAdsCount'] != null &&
                            user['averageRating'] != null)
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        if (user['averageRating'] != null) ...[
                          Icon(Icons.star, size: 12, color: Colors.amber),
                          SizedBox(width: 2),
                          Text(
                            '${user['averageRating'].toStringAsFixed(1)}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Chat Button
            IconButton(
              onPressed: () => _startChatWithUser(user),
              icon: Icon(Icons.chat_bubble_outline, color: Color(0xff014700)),
              tooltip: AppLocalizations.chat.tr(), // Using existing key
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  String _getLastSeenText(bool isOnline, Timestamp? lastSeen) {
    if (isOnline) return AppLocalizations.online.tr(); // Using existing key

    if (lastSeen == null)
      return AppLocalizations.lastSeenRecently.tr(); // Using existing key

    final now = DateTime.now();
    final lastSeenDate = lastSeen.toDate();
    final difference = now.difference(lastSeenDate);

    if (difference.inMinutes < 1) {
      return AppLocalizations.online.tr(); // Using existing key
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${AppLocalizations.mAgo.tr()}'; // Using existing key
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${AppLocalizations.hAgo.tr()}'; // Using existing key
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${AppLocalizations.dAgo.tr()}'; // Using existing key
    } else {
      return AppLocalizations.lastSeenRecently.tr(); // Using existing key
    }
  }

  Future<void> _startChatWithUser(Map<String, dynamic> user) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      // Show loading
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
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.loading.tr(), // Using existing key
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final chatId = await chatProvider.createOrGetChatEnhanced(
        otherUserId: user['uid'],
        otherUserName: user['type'] == 'company'
            ? (user['companyName'] ?? 'Unknown Company')
            : (user['name'] ?? 'Unknown User'),
        otherUserImage: user['profileImage'],
      );

      // Close loading dialog
      Navigator.pop(context);

      if (chatId != null) {
        // Navigate to chat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesScreen(chatId: chatId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.error.tr()),
          ), // Using existing key
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.error.tr()}: $e'),
        ), // Using existing key
      );
    }
  }
}

// Provider for managing users list and pagination
class StartBrowsingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  DocumentSnapshot? _lastDocument;
  String _searchQuery = '';

  static const int _pageSize = 20;

  // Getters
  List<Map<String, dynamic>> get users =>
      _searchQuery.isEmpty ? _users : _filteredUsers;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // Load initial users
  Future<void> loadUsers() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _users.clear();
    _filteredUsers.clear();
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _error = 'Please login to view users';
        return;
      }

      Query query = _firestore
          .collection('users')
          .where('uid', isNotEqualTo: currentUser.uid)
          .orderBy('uid')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _users = await _processUsers(snapshot.docs);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _error = 'Failed to load users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more users (pagination)
  Future<void> loadMoreUsers() async {
    if (_isLoading ||
        !_hasMore ||
        _lastDocument == null ||
        _searchQuery.isNotEmpty)
      return;

    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      Query query = _firestore
          .collection('users')
          .where('uid', isNotEqualTo: currentUser.uid)
          .orderBy('uid')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final newUsers = await _processUsers(snapshot.docs);
        _users.addAll(newUsers);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print('Error loading more users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh users list
  Future<void> refreshUsers() async {
    await loadUsers();
  }

  // Search users
  void searchUsers(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredUsers.clear();
    } else {
      _filteredUsers = _users.where((user) {
        final userName =
            (user['type'] == 'company'
                    ? (user['companyName'] ?? '')
                    : (user['name'] ?? ''))
                .toLowerCase();
        final userEmail = (user['email'] ?? '').toLowerCase();

        return userName.contains(_searchQuery) ||
            userEmail.contains(_searchQuery);
      }).toList();
    }

    notifyListeners();
  }

  // Process users data and add additional info
  Future<List<Map<String, dynamic>>> _processUsers(
    List<QueryDocumentSnapshot> docs,
  ) async {
    List<Map<String, dynamic>> processedUsers = [];

    for (var doc in docs) {
      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

      // Add user ID
      userData['uid'] = doc.id;

      // Get user's active ads count
      try {
        final adsSnapshot = await _firestore
            .collection('items')
            .where('sellerId', isEqualTo: doc.id)
            .where('status', isEqualTo: 'active')
            .get();
        userData['activeAdsCount'] = adsSnapshot.docs.length;
      } catch (e) {
        userData['activeAdsCount'] = 0;
      }

      // Get user's rating
      try {
        final ratingsSnapshot = await _firestore
            .collection('ratings')
            .where('sellerId', isEqualTo: doc.id)
            .get();

        if (ratingsSnapshot.docs.isNotEmpty) {
          double totalRating = 0;
          for (var rating in ratingsSnapshot.docs) {
            totalRating += (rating.data()['rating'] ?? 0.0).toDouble();
          }
          userData['averageRating'] = totalRating / ratingsSnapshot.docs.length;
        } else {
          userData['averageRating'] = 0.0;
        }
      } catch (e) {
        userData['averageRating'] = 0.0;
      }

      // Check online status
      userData['isOnline'] = await _isUserOnline(doc.id);

      processedUsers.add(userData);
    }

    return processedUsers;
  }

  // Check if user is online
  Future<bool> _isUserOnline(String userId) async {
    try {
      final presenceDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('presence')
          .doc('status')
          .get();

      if (presenceDoc.exists) {
        final data = presenceDoc.data() as Map<String, dynamic>;
        final lastSeen = data['lastSeen'] as Timestamp?;
        final isOnline = data['isOnline'] as bool? ?? false;

        if (isOnline && lastSeen != null) {
          final now = DateTime.now();
          final lastSeenDate = lastSeen.toDate();
          return now.difference(lastSeenDate).inMinutes < 5;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
