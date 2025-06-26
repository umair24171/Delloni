// screens/chat_page.dart - Updated with Backend and Localization
import 'package:arabicmarketplace/screens/chat/controller/chat_provider.dart';
import 'package:arabicmarketplace/screens/chat/view/messages_screen.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart'; // Add this import

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = ChatProvider();

    // FIXED: Initialize after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider.refreshChats();
    });
  }

  @override
  void dispose() {
    _chatProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatProvider,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            AppLocalizations.chat.tr(), // Using existing key
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          leading: const SizedBox.shrink(),
          leadingWidth: 0,
        ),
        body: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            return Column(
              children: [
                // Tab Bar
                SizedBox(height: 20),
                Row(
                  children: [
                    _buildTabButton(
                      AppLocalizations.all.tr(),
                      0,
                      chatProvider,
                    ), // Using existing key
                    _buildTabButton(
                      AppLocalizations.buying.tr(),
                      1,
                      chatProvider,
                    ), // Using existing key
                    _buildTabButton(
                      AppLocalizations.selling.tr(),
                      2,
                      chatProvider,
                    ), // Using existing key
                  ],
                ),
                SizedBox(height: 20),

                // Content Area
                Expanded(child: _buildChatContent(chatProvider)),
              ],
            );
          },
        ),
        // ADDED: Floating Action Button for browsing users
        floatingActionButton: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            // Only show FAB when not loading and there are no chats or when chats are empty
            if (chatProvider.isLoading) return SizedBox.shrink();

            return FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StartBrowsingUsersPage(),
                  ),
                );
              },
              backgroundColor: Color(0xff014700),
              foregroundColor: Colors.white,
              icon: Icon(Icons.search),
              label: Text(
                AppLocalizations.browseUsers.tr(), // Using existing key
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildTabButton(String title, int index, ChatProvider provider) {
    final isSelected = provider.selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => provider.changeTab(index),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.black : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 4,
              color: isSelected ? Colors.black : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContent(ChatProvider provider) {
    // FIXED: Better loading state management
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff014700)),
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.loading.tr(), // Using existing key
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
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
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              provider.error!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.refreshChats(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff014700),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Retry',
              ), // Could use existing keys but this is simple
            ),
          ],
        ),
      );
    }

    final chats = provider.currentChats;

    if (chats.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshChats(),
      color: Color(0xff014700),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return _buildChatItem(chat);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Image.asset(
            'assets/images/chat_image.png',
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // Main text - Using existing key creatively
          Text(
            AppLocalizations.noReviewsYet.tr(), // Using existing key creatively
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle - Using existing key
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppLocalizations.sendMessage.tr(), // Using existing key
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Start Messaging Button
          Container(
            width: 200,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StartBrowsingUsersPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff014700),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                AppLocalizations.browseUsers.tr(), // Using existing key
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Updated to work with both ChatModel and EnhancedChatModel
  Widget _buildChatItem(dynamic chat) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return SizedBox.shrink();

    // Handle both ChatModel and EnhancedChatModel
    final otherUserName = chat.getOtherParticipantName(currentUser.uid);
    final otherUserImage = chat.getOtherParticipantImage(currentUser.uid);
    final unreadCount = chat.getUnreadCount(currentUser.uid);
    final isTyping = chat.isOtherUserTyping(currentUser.uid);

    return InkWell(
      onTap: () {
        // Mark as read when tapping
        _chatProvider.markChatAsRead(chat.id);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MessagesScreen(chatId: chat.id), // Use MessagesPage
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: unreadCount > 0
              ? Colors.blue.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Profile Image
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: otherUserImage.isNotEmpty
                      ? NetworkImage(otherUserImage)
                      : null,
                  child: otherUserImage.isEmpty
                      ? Icon(Icons.person, size: 28, color: Colors.grey[600])
                      : null,
                  backgroundColor: Colors.grey[200],
                ),
                // ADDED: Online indicator
                if (_isUserOnline(chat))
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(width: 12),

            // Chat Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        chat.getFormattedTime(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: unreadCount > 0
                              ? Color(0xff014700)
                              : Colors.grey[600],
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),

                  // Last Message and Unread Count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isTyping
                              ? AppLocalizations.typing
                                    .tr() // Using existing key
                              : chat.lastMessage.isEmpty
                              ? AppLocalizations.noReviewsYet
                                    .tr() // Using existing key creatively
                              : chat.lastMessage,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isTyping
                                ? Colors.green
                                : unreadCount > 0
                                ? Colors.black87
                                : Colors.grey[600],
                            fontStyle: isTyping
                                ? FontStyle.italic
                                : FontStyle.normal,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xff014700),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Product Info (if available)
                  if (chat.productTitle != null) ...[
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        // Navigate to product detail when product card is tapped
                        if (chat.productId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                productId: chat.productId!,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey[300],
                              ),
                              child: chat.productImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        chat.productImage!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Icon(
                                                Icons.image,
                                                size: 16,
                                                color: Colors.grey,
                                              );
                                            },
                                      ),
                                    )
                                  : Icon(
                                      Icons.image,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chat.productTitle!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (chat.productPrice != null)
                                    Text(
                                      chat.getFormattedPrice(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to check if user is online
  bool _isUserOnline(dynamic chat) {
    // You can implement this based on your chat model
    // For now, returning false as a placeholder
    return false;
  }
}

// =====================================================
// ENHANCED START BROWSING USERS PAGE - LOCALIZED
// =====================================================

class StartBrowsingUsersPage extends StatefulWidget {
  @override
  _StartBrowsingUsersPageState createState() => _StartBrowsingUsersPageState();
}

class _StartBrowsingUsersPageState extends State<StartBrowsingUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: currentUser.uid)
          .limit(50)
          .get();

      _users = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      _filteredUsers = List.from(_users);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '${AppLocalizations.error.tr()}: $e'; // Using existing key
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final name = (user['companyName'] ?? user['name'] ?? '').toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.browseUsers.tr(), // Using existing key
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.search.tr(), // Using existing key
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
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

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff014700)),
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.loading.tr(), // Using existing key
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff014700),
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'), // Simple word, could use existing key
            ),
          ],
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            SizedBox(height: 20),
            Text(
              _searchController.text.isNotEmpty
                  ? '${AppLocalizations.search.tr()}: "${_searchController.text}"' // Using existing key
                  : AppLocalizations.noReviewsYet
                        .tr(), // Using existing key creatively
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isNotEmpty) ...[
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _filterUsers();
                },
                child: Text(
                  AppLocalizations.clearAll.tr(), // Using existing key
                  style: GoogleFonts.poppins(
                    color: Color(0xff014700),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserItem(user);
      },
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    final userName = user['companyName'] ?? user['name'] ?? 'Unknown User';
    final userImage = user['profileImage'] ?? '';
    final userType = user['type'] ?? 'individual';
    final memberSince = user['createdAt'] as Timestamp?;

    return InkWell(
      onTap: () => _startChat(user),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: userImage.isNotEmpty
                  ? NetworkImage(userImage)
                  : null,
              child: userImage.isEmpty ? Icon(Icons.person, size: 28) : null,
              backgroundColor: Colors.grey[200],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    userType == 'company'
                        ? AppLocalizations.company.tr()
                        : AppLocalizations.individual
                              .tr(), // Using existing keys
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (memberSince != null)
                    Text(
                      '${AppLocalizations.memberSince.tr()} ${DateFormat('MMM yyyy').format(memberSince.toDate())}', // Using existing key
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chat_outlined, color: Color(0xff014700), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    try {
      final chatProvider = ChatProvider();

      final chatId = await chatProvider.createOrGetChatEnhanced(
        otherUserId: user['uid'] ?? user['id'],
        otherUserName: user['companyName'] ?? user['name'] ?? 'Unknown User',
        otherUserImage: user['profileImage'],
      );

      if (chatId != null) {
        Navigator.pop(context); // Go back to chat list
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesScreen(chatId: chatId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.error.tr()), // Using existing key
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.error.tr()}: $e',
          ), // Using existing key
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
