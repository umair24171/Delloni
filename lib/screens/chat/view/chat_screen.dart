// screens/chat_page.dart - Updated with Backend and Localization
import 'dart:developer';

import 'package:arabicmarketplace/screens/chat/controller/chat_provider.dart';
import 'package:arabicmarketplace/screens/chat/model/chat_model.dart';
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
  final bool isFromNotification;
  const ChatPage({Key? key, this.isFromNotification = false}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late ChatProvider _chatProvider;
  final TextEditingController _searchController = TextEditingController();
  List<EnhancedChatModel> _filteredChats = [];
  bool _isSearching = false;
  
  // FIXED: Track dismissing chats to prevent widget tree errors
  final Set<String> _dismissingChats = {};

  @override
  void initState() {
    super.initState();
    _chatProvider = ChatProvider();
    _searchController.addListener(_filterChats);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider.refreshChats();
    });
  }

  @override
  void dispose() {
    _chatProvider.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredChats.clear();
      });
    } else {
      setState(() {
        _isSearching = true;
        _filteredChats = _chatProvider.currentChats.where((chat) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) return false;
          
          final otherUserName = chat.getOtherParticipantName(currentUser.uid).toLowerCase();
          final lastMessage = chat.lastMessage.toLowerCase();
          final productTitle = (chat.productTitle ?? '').toLowerCase();
          
          return otherUserName.contains(query) || 
                 lastMessage.contains(query) || 
                 productTitle.contains(query);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatProvider,
      child: Scaffold(
        // backgroundColor: Colors.white,
        appBar: AppBar(
          // backgroundColor: Colors.white,
          // automaticallyImplyLeading: !widget.isFromNotification,
          elevation: 0,
           surfaceTintColor:Theme.of(context).appBarTheme.backgroundColor ,
          title: Text(
            AppLocalizations.chat.tr(),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              // color: Colors.black,
            ),
          ),
          leading: widget.isFromNotification ? const SizedBox.shrink() : IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          leadingWidth:widget.isFromNotification?0 :40,
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: ChatSearchDelegate(_chatProvider),
                );
              },
            ),
            SizedBox(width: 8),
          ],
        ),
        body: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            return Column(
              children: [
                // Tab Bar
                SizedBox(height: 20),
                Row(
                  children: [
                    _buildTabButton(AppLocalizations.all.tr(), 0, chatProvider),
                    _buildTabButton(AppLocalizations.buying.tr(), 1, chatProvider),
                    _buildTabButton(AppLocalizations.selling.tr(), 2, chatProvider),
                  ],
                ),
                SizedBox(height: 20),

                // Content Area
                Expanded(child: _buildChatContent(chatProvider)),
              ],
            );
          },
        ),
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
                color: isSelected ? Theme.of(context).colorScheme.onBackground : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 4,
              color: isSelected ? Theme.of(context).colorScheme.onBackground : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContent(ChatProvider provider) {
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
              AppLocalizations.loading.tr(),
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
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    final chats = _isSearching ? _filteredChats : provider.currentChats;
    
    // FIXED: Filter out chats that are being dismissed
    final visibleChats = chats.where((chat) => !_dismissingChats.contains(chat.id)).toList();

    if (visibleChats.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshChats(),
      color: Color(0xff014700),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: visibleChats.length,
        itemBuilder: (context, index) {
          final chat = visibleChats[index];
          return _buildSwipeableChatItem(chat, provider);
        },
      ),
    );
  }

  // FIXED: Enhanced swipeable chat item with proper dismissal handling
  Widget _buildSwipeableChatItem(dynamic chat, ChatProvider provider) {
    // FIXED: Don't create Dismissible for chats that are being dismissed
    if (_dismissingChats.contains(chat.id)) {
      return SizedBox.shrink();
    }

    return Dismissible(
      key: Key(chat.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left - Report/Delete actions
          return await _showLeftSwipeActions(chat, provider);
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe right - Mark as unread
          await provider.markChatAsUnread(chat.id);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Marked as unread'.tr()),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return false; // Don't dismiss
        }
        return false;
      },
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(Icons.mark_email_unread, color: Colors.white),
            SizedBox(width: 8),
            Text('Mark unread'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Options'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.more_horiz, color: Colors.white),
          ],
        ),
      ),
      child: _buildChatItem(chat),
    );
  }

  // FIXED: Enhanced left swipe actions with proper dismissal handling
  Future<bool> _showLeftSwipeActions(dynamic chat, ChatProvider provider) async {
    try {
      final result = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Theme.of(context).brightness != Brightness.dark
            ? Colors.white
            : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(width: 2,color: Colors.grey))
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Chat Options'.tr(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.report_outlined, color: Colors.orange),
                title: Text('Report Chat'.tr()),
                onTap: () => Navigator.pop(context, 'report'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete Chat'.tr()),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
              ListTile(
                leading: Icon(Icons.cancel_outlined, color: Colors.grey),
                title: Text('Cancel'.tr()),
                onTap: () => Navigator.pop(context, 'cancel'),
              ),
            ],
          ),
        ),
      );

      if (result == 'report') {
        await _showReportDialog(chat);
        return false;
      } else if (result == 'delete') {
        return await _handleDeleteChat(chat, provider);
      }
      
      return false;
    } catch (e) {
      log('Error in left swipe actions: $e');
      return false;
    }
  }

  // FIXED: Enhanced delete chat handling
  Future<bool> _handleDeleteChat(dynamic chat, ChatProvider provider) async {
    try {
      final shouldDelete = await _showDeleteConfirmation(chat);
      
      if (shouldDelete) {
        // FIXED: Add to dismissing set to prevent widget tree errors
        setState(() {
          _dismissingChats.add(chat.id);
        });

        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Deleting chat...'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Delete the chat
        final success = await provider.deleteChat(chat.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Chat deleted successfully'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            return true; // This will dismiss the Dismissible
          } else {
            // Remove from dismissing set if deletion failed
            setState(() {
              _dismissingChats.remove(chat.id);
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Failed to delete chat'),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
      
      return false;
    } catch (e) {
      log('Error handling delete chat: $e');
      
      // Clean up dismissing state on error
      setState(() {
        _dismissingChats.remove(chat.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return false;
    }
  }

Future<void> _showReportDialog(dynamic chat) async {
  final TextEditingController _reasonController = TextEditingController();

  try {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness != Brightness.dark
            ? Colors.white
            : Colors.black,
        title: Text('Report Chat'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Report this chat for inappropriate content?'.tr()),
            SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for reporting'.tr(),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Report'.tr(), style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        log('Error: User not authenticated');
        return;
      }

      // Save report to Firestore chat_reports collection
      try {
        await FirebaseFirestore.instance.collection('chat_reports').add({
          'chatId': chat.id,
          'reportedBy': currentUser.uid,
          'reason': _reasonController.text.trim(),
          'reportedAt': FieldValue.serverTimestamp(),
          'productId': chat.productId ?? '',
          'productOwnerId': chat.productOwnerId ?? '',
          'participants': chat.participants ?? [],
          'status': 'pending', // Initial status of the report
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat reported successfully'.tr()),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        log('Error saving report to Firestore: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report chat: $e'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    log('Error showing report dialog: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error showing report dialog: $e'.tr()),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    _reasonController.dispose();
  }
}
  Future<bool> _showDeleteConfirmation(dynamic chat) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).brightness != Brightness.dark
              ? Colors.white
              : Colors.black,
          title: Text('Delete Chat'.tr()),
          content: Text('Are you sure you want to delete this chat? This action cannot be undone.'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete'.tr(), style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      return result ?? false;
    } catch (e) {
      log('Error showing delete confirmation: $e');
      return false;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          Text(
            'No conversations yet'.tr(),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start browsing products and connect with sellers'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Keep your existing _buildChatItem method unchanged
  Widget _buildChatItem(dynamic chat) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return SizedBox.shrink();

    final otherUserName = chat.getOtherParticipantName(currentUser.uid);
    final otherUserImage = chat.getOtherParticipantImage(currentUser.uid);
    final unreadCount = chat.getUnreadCount(currentUser.uid);
    final isTyping = chat.isOtherUserTyping(currentUser.uid);

    return InkWell(
      onTap: () {
        _chatProvider.markChatAsRead(chat.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesScreen(chatId: chat.id),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isTyping
                              ? 'Typing...'.tr()
                              : chat.lastMessage.isEmpty
                              ? 'No messages yet'.tr()
                              : chat.lastMessage,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isTyping
                                ? Colors.green
                                : unreadCount > 0
                                ?null:null,
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
                  if (chat.productTitle != null) ...[
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () {
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
                                        errorBuilder: (context, error, stackTrace) {
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

  bool _isUserOnline(dynamic chat) {
    return false; // Placeholder
  }
}

// Keep your existing ChatSearchDelegate and extensions unchanged...
// UPDATED: Search delegate for existing chats
class ChatSearchDelegate extends SearchDelegate<String> {
  final ChatProvider chatProvider;

  ChatSearchDelegate(this.chatProvider);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Search your conversations'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return SizedBox.shrink();

    final filteredChats = chatProvider.allChats.where((chat) {
      final otherUserName = chat.getOtherParticipantName(currentUser.uid).toLowerCase();
      final lastMessage = chat.lastMessage.toLowerCase();
      final productTitle = (chat.productTitle ?? '').toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return otherUserName.contains(searchQuery) || 
             lastMessage.contains(searchQuery) || 
             productTitle.contains(searchQuery);
    }).toList();

    if (filteredChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No conversations found'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredChats.length,
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
        return _buildSearchResultItem(context, chat, currentUser);
      },
    );
  }

  Widget _buildSearchResultItem(BuildContext context, dynamic chat, currentUser) {
    final otherUserName = chat.getOtherParticipantName(currentUser.uid);
    final otherUserImage = chat.getOtherParticipantImage(currentUser.uid);
    final unreadCount = chat.getUnreadCount(currentUser.uid);

    return InkWell(
      onTap: () {
        close(context, '');
        chatProvider.markChatAsRead(chat.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesScreen(chatId: chat.id),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: unreadCount > 0 ? Colors.blue.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: otherUserImage.isNotEmpty ? NetworkImage(otherUserImage) : null,
              child: otherUserImage.isEmpty ? Icon(Icons.person, size: 28, color: Colors.grey[600]) : null,
              backgroundColor: Colors.grey[200],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,

                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    chat.lastMessage.isEmpty ? 'No messages yet'.tr() : chat.lastMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: unreadCount > 0
                          ? Colors.grey[600]
                          : Colors.grey[600],
                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (chat.productTitle != null) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Product: ${chat.productTitle}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      ),
    );
  }
}
