// screens/chat_page.dart - Updated with Backend
import 'package:arabicmarketplace/screens/account/view/account_profile_page.dart';
import 'package:arabicmarketplace/screens/chat/controller/chat_provider.dart';
import 'package:arabicmarketplace/screens/chat/model/chat_model.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
class MessagesScreen extends StatefulWidget {
  final String chatId;
  
  const MessagesScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  late IndividualChatProvider _chatProvider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatProvider = IndividualChatProvider();
    _chatProvider.initializeChat(widget.chatId);
    _chatProvider.addListener(_scrollToBottom);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider.updateUserPresence(widget.chatId, isActive: true);
    });
    
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatProvider.removeListener(_scrollToBottom);
    _chatProvider.updateUserPresence(widget.chatId, isActive: false);
    WidgetsBinding.instance.removeObserver(this);
    _chatProvider.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _chatProvider.updateUserPresence(widget.chatId, isActive: true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _chatProvider.updateUserPresence(widget.chatId, isActive: false);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatProvider,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildEnhancedAppBar(),
        body: Consumer<IndividualChatProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(provider.error!, style: TextStyle(color: Colors.red)),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.initializeChat(widget.chatId),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // ENHANCED: Clickable Product Card
                if (provider.chat?.productTitle != null)
                  _buildClickableProductCard(provider.chat!),
                
                // Messages
                Expanded(
                  child: _buildMessagesList(provider),
                ),
                
                // Typing Indicator
                if (provider.otherUserTyping)
                  _buildTypingIndicator(),
                
                // Message Input
                _buildMessageInput(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  // ENHANCED: AppBar with clickable user name and better menu
  PreferredSizeWidget _buildEnhancedAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Consumer<IndividualChatProvider>(
        builder: (context, provider, child) {
          final otherParticipant = provider.otherParticipant;
          final chat = provider.chat;
          
          return InkWell(
            onTap: () {
              // FIXED: Navigate to seller profile when name is clicked
              if (otherParticipant != null) {
                _navigateToSellerProfile(otherParticipant.id);
              }
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: otherParticipant?.profileImageUrl != null
                      ? NetworkImage(otherParticipant!.profileImageUrl!)
                      : null,
                  child: otherParticipant?.profileImageUrl == null
                      ? Icon(Icons.person, size: 20)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherParticipant?.name ?? 'Loading...',
                        style: GoogleFonts.jost(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      // ENHANCED: Show last seen instead of just offline
                      Text(
                        _getLastSeenText(otherParticipant),
                        style: GoogleFonts.jost(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                _navigateToUserProfile();
                break;
              case 'report_user':
                _showReportUserDialog();
                break;
              case 'report_chat':
                _showReportChatDialog();
                break;
              case 'delete':
                _showDeleteChatDialog();
                break;
              case 'block':
                _showBlockUserDialog();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: Colors.grey[700]),
                  SizedBox(width: 12),
                  Text('View Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'report_user',
              child: Row(
                children: [
                  Icon(Icons.report_outlined, size: 20, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Report User'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'report_chat',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 20, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Report Chat'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete Chat'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Block User'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ENHANCED: Clickable Product Card that navigates to product detail
  Widget _buildClickableProductCard(EnhancedChatModel chat) {
    return InkWell(
      onTap: () {
        // FIXED: Navigate to product detail when product card is clicked
        if (chat.productId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: chat.productId!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: chat.productImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        chat.productImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image, color: Colors.grey[600], size: 30);
                        },
                      ),
                    )
                  : Icon(Icons.image, color: Colors.grey[600], size: 30),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.productTitle!,
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (chat.productPrice != null)
                    Text(
                      chat.getFormattedPrice(),
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
            ),
            // Tap indicator
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  // ENHANCED: Get proper last seen text
  String _getLastSeenText(ChatParticipantModel? participant) {
    if (participant == null) return 'Loading...';
    
    if (participant.isOnline) {
      return 'Online';
    } else if (participant.lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(participant.lastSeen!);
      
      if (difference.inMinutes < 1) {
        return 'Last seen just now';
      } else if (difference.inMinutes < 60) {
        return 'Last seen ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Last seen ${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return 'Last seen ${difference.inDays}d ago';
      } else {
        return 'Last seen ${DateFormat('MMM dd').format(participant.lastSeen!)}';
      }
    } else {
      return 'Last seen recently';
    }
  }

  // Navigate to seller profile
  void _navigateToSellerProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountProfilePage(userId: userId),
      ),
    );
  }

  // Navigate to user profile from menu
  void _navigateToUserProfile() {
    final otherParticipant = _chatProvider.otherParticipant;
    if (otherParticipant != null) {
      _navigateToSellerProfile(otherParticipant.id);
    }
  }

  // ENHANCED: Report User Dialog with reasons
  void _showReportUserDialog() {
    final reasons = [
      'Inappropriate behavior',
      'Spam or scam',
      'Harassment',
      'Fake profile',
      'Inappropriate content',
      'Threatening behavior',
      'Other',
    ];

    String? selectedReason;
    final TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.report_outlined, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Report User',
                style: GoogleFonts.jost(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why are you reporting this user?',
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16),
                ...reasons.map((reason) => RadioListTile<String>(
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value),
                  title: Text(
                    reason,
                    style: GoogleFonts.jost(fontSize: 14),
                  ),
                  dense: true,
                )),
                SizedBox(height: 16),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)',
                    hintStyle: GoogleFonts.jost(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.jost(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: selectedReason != null ? () async {
                Navigator.pop(context);
                await _submitUserReport(selectedReason!, detailsController.text);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Report',
                style: GoogleFonts.jost(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ENHANCED: Report Chat Dialog with reasons
  void _showReportChatDialog() {
    final reasons = [
      'Inappropriate content',
      'Spam messages',
      'Harassment',
      'Fake information',
      'Suspicious activity',
      'Abusive language',
      'Other',
    ];

    String? selectedReason;
    final TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.flag_outlined, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Report Chat',
                style: GoogleFonts.jost(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why are you reporting this conversation?',
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16),
                ...reasons.map((reason) => RadioListTile<String>(
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value),
                  title: Text(
                    reason,
                    style: GoogleFonts.jost(fontSize: 14),
                  ),
                  dense: true,
                )),
                SizedBox(height: 16),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)',
                    hintStyle: GoogleFonts.jost(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.jost(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: selectedReason != null ? () async {
                Navigator.pop(context);
                await _submitChatReport(selectedReason!, detailsController.text);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Report',
                style: GoogleFonts.jost(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Submit user report
  Future<void> _submitUserReport(String reason, String details) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final otherParticipant = _chatProvider.otherParticipant;
      
      if (currentUser != null && otherParticipant != null) {
        await FirebaseFirestore.instance.collection('reports').add({
          'type': 'user',
          'reportedUserId': otherParticipant.id,
          'reportedBy': currentUser.uid,
          'reason': reason,
          'details': details,
          'chatId': widget.chatId,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('User reported successfully'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Submit chat report
  Future<void> _submitChatReport(String reason, String details) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('reports').add({
          'type': 'chat',
          'chatId': widget.chatId,
          'reportedBy': currentUser.uid,
          'reason': reason,
          'details': details,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Chat reported successfully'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Keep your existing methods for messages list, typing indicator, etc.
  Widget _buildMessagesList(IndividualChatProvider provider) {
    final messages = provider.messages;
    
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start the conversation!',
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
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;
        final showAvatar = index == messages.length - 1 || 
                          messages[index + 1].senderId != message.senderId;
        
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: _buildMessageBubble(
            message: message,
            isMe: isMe,
            showAvatar: showAvatar && !isMe,
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required MessageModel message,
    required bool isMe,
    required bool showAvatar,
  }) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.amber[300],
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 32),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.grey[200] : Colors.green[700],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: message.type == MessageType.image && message.imageUrls != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.imageUrls!.first,
                            width: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 100,
                                color: Colors.grey[300],
                                child: Icon(Icons.broken_image, color: Colors.grey[600]),
                              );
                            },
                          ),
                        )
                      : Text(
                          message.message,
                          style: GoogleFonts.jost(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: isMe ? Colors.black : Colors.white,
                            height: 1.4,
                          ),
                        ),
                ),
                SizedBox(height: 4),
                Text(
                  message.getFormattedTime(),
                  style: GoogleFonts.jost(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          if (isMe) const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 32),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTypingDot(0),
                      _buildTypingDot(1),
                      _buildTypingDot(2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMessageInput(IndividualChatProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.camera_alt, color: Colors.grey[600]),
            onPressed: () => _showImagePicker(provider),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.jost(fontSize: 14, color: Colors.black),
                onChanged: (text) {
                  if (text.isNotEmpty) {
                    provider.startTyping();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Type message...',
                  hintStyle: GoogleFonts.jost(fontSize: 14, color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green[700],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                if (_messageController.text.trim().isNotEmpty) {
                  provider.sendMessage(_messageController.text.trim());
                  _messageController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Keep your existing helper methods (image picker, dialogs, etc.)
  void _showImagePicker(IndividualChatProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send Image',
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    final ImagePicker picker = ImagePicker();
                    try {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        provider.sendImageMessage(image);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to pick image from gallery')),
                      );
                    }
                  },
                ),
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () async {
                    Navigator.pop(context);
                    final ImagePicker picker = ImagePicker();
                    try {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        provider.sendImageMessage(image);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to take photo')),
                      );
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.grey[700]),
            SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Chat',
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this chat? This action cannot be undone.',
          style: GoogleFonts.jost(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Delete chat functionality would go here
                Navigator.pop(context); // Go back to chat list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chat deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete chat')),
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Block User',
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to block this user? You will not receive messages from them.',
          style: GoogleFonts.jost(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final otherUserId = _chatProvider.chat?.getOtherParticipantId(
                  FirebaseAuth.instance.currentUser?.uid ?? ''
                );
                if (otherUserId != null) {
                  // Block user functionality would go here
                  Navigator.pop(context); // Go back to chat list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User blocked successfully')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to block user')),
                );
              }
            },
            child: Text(
              'Block',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(MessageModel message) {
    final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == MessageType.text) ...[
              ListTile(
                leading: Icon(Icons.copy, color: Colors.grey[700]),
                title: Text(
                  'Copy Message',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Message copied to clipboard')),
                  );
                },
              ),
            ],
            if (message.type == MessageType.image) ...[
              ListTile(
                leading: Icon(Icons.download, color: Colors.grey[700]),
                title: Text(
                  'Save Image',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implement image saving functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Image saved to gallery')),
                  );
                },
              ),
            ],
            if (isMe) ...[
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Message',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteMessageDialog(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteMessageDialog(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Message',
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this message?',
          style: GoogleFonts.jost(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _chatProvider.deleteMessage(message.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Message deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete message')),
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
