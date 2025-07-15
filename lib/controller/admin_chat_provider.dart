import 'dart:async';
import 'dart:developer';
import 'package:arabicmarketplace/screens/chat/model/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // State variables
  bool _isLoading = true;
  String? _error;
  List<EnhancedChatModel> _allChats = [];
  List<EnhancedChatModel> _filteredChats = [];
  String _searchQuery = '';
  
  // Streams
  StreamSubscription? _chatsSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<EnhancedChatModel> get allChats => _allChats;
  List<EnhancedChatModel> get currentChats => _searchQuery.isEmpty ? _allChats : _filteredChats;
  String get searchQuery => _searchQuery;

  AdminChatProvider() {
    initializeChats();
  }

  Future<void> initializeChats() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('Admin not authenticated');
      return;
    }

    try {
      _setLoading(true);
      await _ensureAdminUserDocument(currentUser);
      _setupChatsListener(currentUser.uid);
    } catch (e) {
      _setError('Failed to initialize chats: $e');
      log('AdminChatProvider initialization error: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  // Ensure admin user document exists
  Future<void> _ensureAdminUserDocument(User currentUser) async {
    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (!userDoc.exists) {
        // Create admin user document
        await _firestore.collection('users').doc(currentUser.uid).set({
          'uid': currentUser.uid,
          'type': 'admin',
          'email': currentUser.email ?? '',
          'companyName': 'Admin',
          'name': 'Administrator',
          'phone': '',
          'language': 'English',
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': true,
          'profileImage': currentUser.photoURL,
        });
        log('Admin user document created');
      }
    } catch (e) {
      log('Error ensuring admin user document: $e');
    }
  }

  // Setup real-time chat listener for admin
  void _setupChatsListener(String adminId) {
    _chatsSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: adminId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen((snapshot) {
      try {
        _allChats = snapshot.docs
            .map((doc) => EnhancedChatModel.fromFirestore(doc))
            .toList();

        _filterChats();
        _setLoading(false);
        log('Admin chats loaded: ${_allChats.length}');
      } catch (e) {
        log('Error processing chat snapshots: $e');
      }
    }, onError: (e) {
      _setError('Error loading chats: $e');
      log('Chats stream error: $e');
    });
  }

  // Create or get existing chat with a user
  Future<String?> createOrGetChatWithUser({
    required String otherUserId,
    required String otherUserName,
    String? otherUserImage,
    String? productId,
    String? productTitle,
    String? productImage,
    double? productPrice,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('Admin not authenticated');
      return null;
    }

    try {
      final chatId = _generateChatId(currentUser.uid, otherUserId);
      
      // Check if chat already exists
      final existingChat = await _firestore.collection('chats').doc(chatId).get();
      
      if (existingChat.exists) {
        return chatId;
      }

      // Get other user info
      final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
      if (!otherUserDoc.exists) {
        throw Exception('User not found');
      }

      final otherUserData = otherUserDoc.data() as Map<String, dynamic>;
      final actualOtherUserName = otherUserData['companyName'] ?? 
                                  otherUserData['name'] ?? 
                                  otherUserName;

      // Create new chat
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUser.uid, otherUserId],
        'participantNames': {
          currentUser.uid: 'Admin',
          otherUserId: actualOtherUserName,
        },
        'participantImages': {
          currentUser.uid: currentUser.photoURL ?? '',
          otherUserId: otherUserData['profileImage'] ?? otherUserImage ?? '',
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'productId': productId,
        'productTitle': productTitle,
        'productImage': productImage,
        'productPrice': productPrice,
        'unreadCount': {
          currentUser.uid: 0,
          otherUserId: 0,
        },
        'isTyping': {
          currentUser.uid: false,
          otherUserId: false,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'chatType': productId != null ? 'support' : 'admin_chat',
      });

      log('Chat created with user: $otherUserId');
      return chatId;
    } catch (e) {
      _setError('Failed to create chat: $e');
      log('Error creating chat: $e');
      return null;
    }
  }

  // Search chats
  void searchChats(String query) {
    _searchQuery = query.toLowerCase();
    _filterChats();
  }

  // Filter chats based on search query
  void _filterChats() {
    if (_searchQuery.isEmpty) {
      _filteredChats = _allChats;
    } else {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      _filteredChats = _allChats.where((chat) {
        final otherUserName = chat.getOtherParticipantName(currentUser.uid).toLowerCase();
        final productTitle = chat.productTitle?.toLowerCase() ?? '';
        final lastMessage = chat.lastMessage.toLowerCase();

        return otherUserName.contains(_searchQuery) ||
               productTitle.contains(_searchQuery) ||
               lastMessage.contains(_searchQuery);
      }).toList();
    }
    notifyListeners();
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.${currentUser.uid}': 0,
      });
    } catch (e) {
      log('Error marking chat as read: $e');
    }
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isActive': false,
      });
      log('Chat deleted: $chatId');
    } catch (e) {
      _setError('Failed to delete chat: $e');
      log('Error deleting chat: $e');
    }
  }

  // Archive chat
  Future<void> archiveChat(String chatId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'archivedBy.${currentUser.uid}': true,
      });
      log('Chat archived: $chatId');
    } catch (e) {
      log('Error archiving chat: $e');
    }
  }

  // Block user
  Future<void> blockUser(String chatId, String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'blockedBy.${currentUser.uid}': userId,
        'isActive': false,
      });
      log('User blocked: $userId');
    } catch (e) {
      log('Error blocking user: $e');
    }
  }

  // Generate consistent chat ID
  String _generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Get total unread count
  int getTotalUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    return _allChats.fold(0, (total, chat) => total + chat.getUnreadCount(currentUser.uid));
  }

  // Get chats by type
  List<EnhancedChatModel> getChatsByType(String type) {
    return _allChats.where((chat) => chat.chatType == type).toList();
  }

  // Get support chats
  List<EnhancedChatModel> getSupportChats() {
    return _allChats.where((chat) =>
        chat.chatType == 'support' || 
        chat.lastMessage.toLowerCase().contains('help') ||
        chat.lastMessage.toLowerCase().contains('support')
    ).toList();
  }

  // Refresh chats
  Future<void> refreshChats() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _setupChatsListener(currentUser.uid);
    }
  }

  // Get all users for admin to start chats
  Stream<QuerySnapshot> getAllUsers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUser.uid)
        .where('type', whereIn: ['individual', 'company'])
        .snapshots();
  }

  // Send broadcast message to multiple users
  Future<bool> sendBroadcastMessage({
    required List<String> userIds,
    required String message,
    String? productTitle,
    String? productId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      for (String userId in userIds) {
        final chatId = await createOrGetChatWithUser(
          otherUserId: userId,
          otherUserName: 'User',
        );
        
        if (chatId != null) {
          // Send message to this chat
          await _sendMessageToChat(chatId, message, productTitle, productId);
        }
      }
      
      log('Broadcast message sent to ${userIds.length} users');
      return true;
    } catch (e) {
      _setError('Failed to send broadcast message: $e');
      log('Error sending broadcast message: $e');
      return false;
    }
  }

  // Helper method to send message to a specific chat
  Future<void> _sendMessageToChat(
    String chatId,
    String message,
    String? productTitle,
    String? productId,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final messageId = _firestore.collection('chats').doc(chatId).collection('messages').doc().id;
      
      // Create message
      final messageData = {
        'id': messageId,
        'chatId': chatId,
        'senderId': currentUser.uid,
        'senderName': 'Admin',
        'message': message,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'productId': productId,
        'productTitle': productTitle,
      };

      // Add message to Firestore
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);

      // Update chat last message
      final chat = await _firestore.collection('chats').doc(chatId).get();
      if (chat.exists) {
        final chatData = chat.data() as Map<String, dynamic>;
        final participants = List<String>.from(chatData['participants'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != currentUser.uid);

        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': message,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': currentUser.uid,
          'unreadCount.$otherUserId': FieldValue.increment(1),
        });
      }
    } catch (e) {
      log('Error sending message to chat $chatId: $e');
    }
  }

  // Get chat statistics for admin dashboard
  Map<String, dynamic> getChatStatistics() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return {};

    final totalChats = _allChats.length;
    final totalUnread = getTotalUnreadCount();
    final supportChats = getSupportChats().length;
    final activeChats = _allChats.where((chat) => 
        chat.lastMessageTime != null && 
        DateTime.now().difference(chat.lastMessageTime!).inHours < 24
    ).length;

    return {
      'totalChats': totalChats,
      'totalUnread': totalUnread,
      'supportChats': supportChats,
      'activeChats': activeChats,
      'averageResponseTime': _calculateAverageResponseTime(),
    };
  }

  // Calculate average response time
  String _calculateAverageResponseTime() {
    // This is a simplified calculation
    // You can implement more sophisticated logic based on your needs
    return '< 1 hour';
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    super.dispose();
  }
}