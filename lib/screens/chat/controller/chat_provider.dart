// providers/chat_provider.dart
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:arabicmarketplace/controller/notification_service.dart';
import 'package:arabicmarketplace/screens/chat/model/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  bool _isLoading = true;
  String? _error;
  List<EnhancedChatModel> _allChats = [];
  List<EnhancedChatModel> _buyingChats = [];
  List<EnhancedChatModel> _sellingChats = [];
  int _selectedTabIndex = 0;
  
  // Streams
  StreamSubscription? _chatsSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<EnhancedChatModel> get allChats => _allChats;
  List<EnhancedChatModel> get buyingChats => _buyingChats;
  List<EnhancedChatModel> get sellingChats => _sellingChats;
  int get selectedTabIndex => _selectedTabIndex;

  List<EnhancedChatModel> get currentChats {
    switch (_selectedTabIndex) {
      case 0: return _allChats;
      case 1: return _buyingChats;
      case 2: return _sellingChats;
      default: return _allChats;
    }
  }

  ChatProvider() {
    _initializeChats();
  }

  Future<void> _initializeChats() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('User not authenticated');
      return;
    }

    try {
      _setLoading(true);
      _setupChatsListener(currentUser.uid);
    } catch (e) {
      _setError('Failed to initialize chats: $e');
      log('ChatProvider initialization error: $e');
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

  // FIXED: Enhanced chat listener with better error handling
  void _setupChatsListener(String userId) {
    _chatsSubscription?.cancel(); // Cancel existing subscription
    
    _chatsSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen((snapshot) {
      try {
        log('📱 Processing ${snapshot.docs.length} chats from Firestore');
        
        // Filter out chats that this user has deleted
        final filteredChats = <EnhancedChatModel>[];
        
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          
          // FIXED: Better handling of deletedBy field
          final deletedByData = data['deletedBy'];
          List<String> deletedBy = [];
          
          if (deletedByData != null) {
            if (deletedByData is List) {
              deletedBy = List<String>.from(deletedByData);
            } else if (deletedByData is String) {
              deletedBy = [deletedByData];
            }
          }
          
          // Check if current user has deleted this chat
          if (!deletedBy.contains(userId)) {
            try {
              final chat = EnhancedChatModel.fromFirestore(doc);
              filteredChats.add(chat);
              log('✅ Added chat: ${chat.id} (deleted by: $deletedBy)');
            } catch (e) {
              log('❌ Error parsing chat ${doc.id}: $e');
            }
          } else {
            log('🗑️ Skipping deleted chat: ${doc.id}');
          }
        }
        
        _allChats = filteredChats;
        log('📊 Total active chats: ${_allChats.length}');
        
        _categorizeChatsFixed(userId);
        _setLoading(false);
      } catch (e) {
        log('❌ Error processing chats: $e');
        _setError('Error processing chats: $e');
      }
    }, onError: (e) {
      log('❌ Chats stream error: $e');
      _setError('Error loading chats: $e');
    });
  }

  // FIXED: Proper categorization based on who initiated chat about which product
  void _categorizeChatsFixed(String userId) {
    _buyingChats.clear();
    _sellingChats.clear();
    
    for (var chat in _allChats) {
      log('=== Processing Chat ${chat.id} ===');
      log('Product Owner: ${chat.productOwnerId}');
      log('Current User: $userId');
      log('Product Title: ${chat.productTitle}');
      log('Participants: ${chat.participants}');
      
      try {
        if (chat.productId != null && chat.productOwnerId != null) {
          // Primary logic: Use productOwnerId to determine buyer/seller
          if (chat.productOwnerId == userId) {
            // Current user owns the product → they are SELLING
            _sellingChats.add(chat);
            log('✓ Added to SELLING (user owns product)');
          } else {
            // Current user doesn't own the product → they are BUYING
            _buyingChats.add(chat);
            log('✓ Added to BUYING (user doesn\'t own product)');
          }
        } else {
          // Fallback logic for chats without clear product ownership
          log('⚠️ No product owner info, using fallback logic');
          
          // Check if we can determine from chat type
          String chatType = chat.chatType.toLowerCase();
          if (chatType.contains('buying')) {
            _buyingChats.add(chat);
            log('✓ Added to BUYING (chatType: $chatType)');
          } else if (chatType.contains('selling')) {
            _sellingChats.add(chat);
            log('✓ Added to SELLING (chatType: $chatType)');
          } else {
            // Default fallback: add to buying
            _buyingChats.add(chat);
            log('✓ Added to BUYING (default fallback)');
          }
        }
      } catch (e) {
        log('❌ Error categorizing chat ${chat.id}: $e');
        // Safe fallback
        _buyingChats.add(chat);
      }
    }
    
    log('📊 Final categorization:');
    log('   Buying: ${_buyingChats.length} chats');
    log('   Selling: ${_sellingChats.length} chats');
    log('   Total: ${_allChats.length} chats');
    
    notifyListeners();
  }

  // FIXED: Enhanced chat creation with proper field initialization
  Future<String?> createOrGetChatEnhanced({
    required String otherUserId,
    required String otherUserName,
    String? otherUserImage,
    String? productId,
    String? productTitle,
    String? productImage,
    double? productPrice,
    String? productOwnerId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('User not authenticated');
      return null;
    }

    try {
      final chatId = _generateChatId(currentUser.uid, otherUserId);
      
      // Check if chat already exists
      final existingChat = await _firestore.collection('chats').doc(chatId).get();
      
      if (existingChat.exists) {
        // Update existing chat with current product info
        Map<String, dynamic> updateData = {
          'lastMessageTime': FieldValue.serverTimestamp(),
          'isActive': true, // Ensure chat is active
        };
        
        if (productId != null) {
          updateData.addAll({
            'productId': productId,
            'productTitle': productTitle,
            'productImage': productImage,
            'productPrice': productPrice,
            'productOwnerId': productOwnerId,
          });
        }
        
        await _firestore.collection('chats').doc(chatId).update(updateData);
        return chatId;
      }

      // Get current user info
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserData = currentUserDoc.data() ?? {};
      final currentUserName = currentUserData['companyName'] ?? 
                             currentUserData['name'] ?? 
                             currentUser.displayName ?? 
                             'Unknown User';

      // Determine chat type based on product ownership
      String chatType = 'general';
      if (productId != null && productOwnerId != null) {
        chatType = productOwnerId == currentUser.uid ? 'selling' : 'buying';
      }

      // FIXED: Create new chat with proper field initialization
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUser.uid, otherUserId],
        'participantNames': {
          currentUser.uid: currentUserName,
          otherUserId: otherUserName,
        },
        'participantImages': {
          currentUser.uid: currentUserData['profileImage'] ?? currentUser.photoURL ?? '',
          otherUserId: otherUserImage ?? '',
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'productId': productId,
        'productTitle': productTitle,
        'productImage': productImage,
        'productPrice': productPrice,
        'productOwnerId': productOwnerId,
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
        'chatType': chatType,
        'deletedBy': [], // FIXED: Initialize as empty array
      });

      log('✅ Created new chat: $chatId');
      return chatId;
    } catch (e) {
      _setError('Failed to create chat: $e');
      log('❌ Error creating enhanced chat: $e');
      return null;
    }
  }

  // Rest of your existing methods...
  void changeTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  String _generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  int getTotalUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    return _allChats.fold(0, (total, chat) => total + chat.getUnreadCount(currentUser.uid));
  }

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

  // FIXED: Mark chat as unread
  Future<void> markChatAsUnread(String chatId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.${currentUser.uid}': 1,
      });
    } catch (e) {
      log('Error marking chat as unread: $e');
    }
  }

  // FIXED: Enhanced delete chat with better error handling
  Future<bool> deleteChat(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        log('❌ Cannot delete chat: User not authenticated');
        return false;
      }

      log('🗑️ Deleting chat: $chatId for user: ${currentUser.uid}');

      // Add current user to deletedBy array
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy': FieldValue.arrayUnion([currentUser.uid]),
      });

      // FIXED: Remove from local lists immediately for better UX
      _allChats.removeWhere((chat) => chat.id == chatId);
      _buyingChats.removeWhere((chat) => chat.id == chatId);
      _sellingChats.removeWhere((chat) => chat.id == chatId);
      
      log('✅ Chat deleted successfully: $chatId');
      notifyListeners();
      return true;
    } catch (e) {
      log('❌ Error deleting chat: $e');
      _setError('Failed to delete chat: $e');
      return false;
    }
  }

  // FIXED: Enhanced refresh with proper error handling
  Future<void> refreshChats() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _setLoading(true);
        _setError(null);
        _setupChatsListener(currentUser.uid);
      }
    } catch (e) {
      _setError('Failed to refresh chats: $e');
      log('❌ Error refreshing chats: $e');
    }
  }

  // FIXED: Check if chat exists and is accessible
  Future<bool> isChatAccessible(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) return false;
      
      final data = chatDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      final deletedBy = List<String>.from(data['deletedBy'] ?? []);
      final isActive = data['isActive'] ?? true;
      
      return participants.contains(currentUser.uid) && 
             !deletedBy.contains(currentUser.uid) && 
             isActive;
    } catch (e) {
      log('❌ Error checking chat accessibility: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    super.dispose();
  }
}

class IndividualChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // State variables
  bool _isLoading = true;
  String? _error;
  EnhancedChatModel? _chat;
  List<MessageModel> _messages = [];
  ChatParticipantModel? _otherParticipant;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  
  // Streams
  StreamSubscription? _chatSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _typingTimer;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  EnhancedChatModel? get chat => _chat;
  List<MessageModel> get messages => _messages;
  ChatParticipantModel? get otherParticipant => _otherParticipant;
  bool get isTyping => _isTyping;
  bool get otherUserTyping => _otherUserTyping;

  // Initialize individual chat
  Future<void> initializeChat(String chatId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      _setupChatListener(chatId);
      _setupMessagesListener(chatId);
      await _markChatAsRead(chatId);
      
    } catch (e) {
      _setError('Failed to initialize chat: $e');
      log('IndividualChatProvider initialization error: $e');
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

  // Setup chat info listener
  void _setupChatListener(String chatId) {
    _chatSubscription = _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        _chat = EnhancedChatModel.fromFirestore(snapshot);
        await _loadOtherParticipant();
        _setLoading(false);
      }
    }, onError: (e) {
      _setError('Error loading chat: $e');
      log('Chat stream error: $e');
    });
  }

  // Setup messages listener
  void _setupMessagesListener(String chatId) {
    _messagesSubscription = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _messages = snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
      notifyListeners();
    }, onError: (e) => log('Messages stream error: $e'));
  }

  // Load other participant info
  Future<void> _loadOtherParticipant() async {
    if (_chat == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final otherUserId = _chat!.getOtherParticipantId(currentUser.uid);
      final userDoc = await _firestore.collection('users').doc(otherUserId).get();
      
      if (userDoc.exists) {
        _otherParticipant = ChatParticipantModel.fromUserModel(userDoc.data()!);
        notifyListeners();
      }
    } catch (e) {
      log('Error loading other participant: $e');
    }
  }

  // Enhanced send text message with push notifications
  Future<void> sendMessage(String messageText) async {
    if (_chat == null || messageText.trim().isEmpty) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Get current user info
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserData = currentUserDoc.data() ?? {};
      final currentUserName = currentUserData['companyName'] ?? 
                             currentUserData['name'] ?? 
                             currentUser.displayName ?? 
                             'Unknown User';

      final messageId = _firestore.collection('chats').doc(_chat!.id).collection('messages').doc().id;
      
      // Create message
      final message = MessageModel(
        id: messageId,
        chatId: _chat!.id,
        senderId: currentUser.uid,
        senderName: currentUserName,
        message: messageText.trim(),
        type: MessageType.text,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      );

      // Add message to Firestore
      await _firestore
          .collection('chats')
          .doc(_chat!.id)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      // Update chat last message
      final otherUserId = _chat!.getOtherParticipantId(currentUser.uid);
      await _firestore.collection('chats').doc(_chat!.id).update({
        'lastMessage': messageText.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });

      // Send push notification to other user
      await _sendNewMessageNotification(
        recipientId: otherUserId,
        senderName: currentUserName,
        messagePreview: _getMessagePreview(messageText.trim()),
        chatId: _chat!.id,
      );

      // Stop typing
      _stopTyping();

    } catch (e) {
      _setError('Failed to send message: $e');
      log('Error sending message: $e');
    }
  }

  // Enhanced send image message with push notifications
  Future<void> sendImageMessage(XFile imageFile) async {
    if (_chat == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Upload image to Firebase Storage
      final imageUrl = await _uploadImage(imageFile);
      if (imageUrl == null) return;

      // Get current user info
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserData = currentUserDoc.data() ?? {};
      final currentUserName = currentUserData['companyName'] ?? 
                             currentUserData['name'] ?? 
                             currentUser.displayName ?? 
                             'Unknown User';

      final messageId = _firestore.collection('chats').doc(_chat!.id).collection('messages').doc().id;
      
      // Create image message
      final message = MessageModel(
        id: messageId,
        chatId: _chat!.id,
        senderId: currentUser.uid,
        senderName: currentUserName,
        message: 'Image',
        type: MessageType.image,
        timestamp: DateTime.now(),
        imageUrls: [imageUrl],
        status: MessageStatus.sending,
      );

      // Add message to Firestore
      await _firestore
          .collection('chats')
          .doc(_chat!.id)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      // Update chat last message
      final otherUserId = _chat!.getOtherParticipantId(currentUser.uid);
      await _firestore.collection('chats').doc(_chat!.id).update({
        'lastMessage': 'Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });

      // Send push notification for image
      await _sendNewMessageNotification(
        recipientId: otherUserId,
        senderName: currentUserName,
        messagePreview: '📸 Photo',
        chatId: _chat!.id,
      );

    } catch (e) {
      _setError('Failed to send image: $e');
      log('Error sending image: $e');
    }
  }

  // Send location message with push notification
  Future<void> sendLocationMessage(double latitude, double longitude, String address) async {
    if (_chat == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Get current user info
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserData = currentUserDoc.data() ?? {};
      final currentUserName = currentUserData['companyName'] ?? 
                             currentUserData['name'] ?? 
                             currentUser.displayName ?? 
                             'Unknown User';

      final messageId = _firestore.collection('chats').doc(_chat!.id).collection('messages').doc().id;
      
      // Create location message
      final message = MessageModel(
        id: messageId,
        chatId: _chat!.id,
        senderId: currentUser.uid,
        senderName: currentUserName,
        message: address,
        type: MessageType.location,
        timestamp: DateTime.now(),
        // latitude: latitude,
        // longitude: longitude,
        status: MessageStatus.sending,
      );

      // Add message to Firestore
      await _firestore
          .collection('chats')
          .doc(_chat!.id)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      // Update chat last message
      final otherUserId = _chat!.getOtherParticipantId(currentUser.uid);
      await _firestore.collection('chats').doc(_chat!.id).update({
        'lastMessage': '📍 Location',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });

      // Send push notification for location
      await _sendNewMessageNotification(
        recipientId: otherUserId,
        senderName: currentUserName,
        messagePreview: '📍 Location: ${_getLocationPreview(address)}',
        chatId: _chat!.id,
      );

    } catch (e) {
      _setError('Failed to send location: $e');
      log('Error sending location: $e');
    }
  }

  // Send product offer message with push notification
  Future<void> sendProductOfferMessage({
    required String productId,
    required String productTitle,
    required double offerPrice,
    required double originalPrice,
  }) async {
    if (_chat == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserData = currentUserDoc.data() ?? {};
      final currentUserName = currentUserData['companyName'] ?? 
                             currentUserData['name'] ?? 
                             currentUser.displayName ?? 
                             'Unknown User';

      final messageId = _firestore.collection('chats').doc(_chat!.id).collection('messages').doc().id;
      final offerText = 'I\'d like to offer \$${offerPrice.toStringAsFixed(2)} for "$productTitle"';
      
      // Create offer message
      final message = MessageModel(
        id: messageId,
        chatId: _chat!.id,
        senderId: currentUser.uid,
        senderName: currentUserName,
        message: offerText,
        type: MessageType.product,
        timestamp: DateTime.now(),
        // offerData: {
        //   'productId': productId,
        //   'productTitle': productTitle,
        //   'offerPrice': offerPrice,
        //   'originalPrice': originalPrice,
        //   'status': 'pending',
        // },
        status: MessageStatus.sending,
      );

      // Add message to Firestore
      await _firestore
          .collection('chats')
          .doc(_chat!.id)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      // Update chat last message
      final otherUserId = _chat!.getOtherParticipantId(currentUser.uid);
      await _firestore.collection('chats').doc(_chat!.id).update({
        'lastMessage': '💰 Offer: \$${offerPrice.toStringAsFixed(2)}',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });

      // Send special offer notification
      await _sendOfferNotification(
        recipientId: otherUserId,
        senderName: currentUserName,
        productTitle: productTitle,
        offerPrice: offerPrice,
        originalPrice: originalPrice,
        chatId: _chat!.id,
      );

    } catch (e) {
      _setError('Failed to send offer: $e');
      log('Error sending offer: $e');
    }
  }

  // Send new message notification
  Future<void> _sendNewMessageNotification({
    required String recipientId,
    required String senderName,
    required String messagePreview,
    required String chatId,
  }) async {
    try {
      // Check if recipient has message notifications enabled
      final preferences = await _notificationService.getUserNotificationPreferences(recipientId);
      if (preferences['newMessage'] != true) {
        log('User has disabled message notifications');
        return;
      }

      // Check if user is currently in this chat (to avoid notifying active users)
      final isUserActive = await _isUserActiveInChat(recipientId, chatId);
      if (isUserActive) {
        log('User is active in chat, skipping notification');
        return;
      }

      await _notificationService.sendNotificationToUser(
        userId: recipientId,
        title: senderName,
        body: messagePreview,
        type: 'newMessage',
        data: {
          'chatId': chatId,
          'senderId': _auth.currentUser!.uid,
          'senderName': senderName,
          'messagePreview': messagePreview,
          'productId': _chat?.productId,
          'productTitle': _chat?.productTitle,
        },
      );

      log('New message notification sent to $recipientId');
    } catch (e) {
      log('Error sending message notification: $e');
    }
  }

  // Send offer notification
  Future<void> _sendOfferNotification({
    required String recipientId,
    required String senderName,
    required String productTitle,
    required double offerPrice,
    required double originalPrice,
    required String chatId,
  }) async {
    try {
      final discountPercentage = ((originalPrice - offerPrice) / originalPrice * 100).round();
      
      await _notificationService.sendNotificationToUser(
        userId: recipientId,
        title: '💰 New Offer Received',
        body: '$senderName offered \$${offerPrice.toStringAsFixed(2)} for "$productTitle" (${discountPercentage}% off)',
        type: 'offerReceived',
        data: {
          'chatId': chatId,
          'senderId': _auth.currentUser!.uid,
          'senderName': senderName,
          'productTitle': productTitle,
          'offerPrice': offerPrice,
          'originalPrice': originalPrice,
          'discountPercentage': discountPercentage,
        },
      );

      log('Offer notification sent to $recipientId');
    } catch (e) {
      log('Error sending offer notification: $e');
    }
  }

  // Check if user is currently active in chat
  Future<bool> _isUserActiveInChat(String userId, String chatId) async {
    try {
      // Check user's last activity timestamp (you can implement this)
      final userPresence = await _firestore
          .collection('users')
          .doc(userId)
          .collection('presence')
          .doc('status')
          .get();

      if (userPresence.exists) {
        final data = userPresence.data() as Map<String, dynamic>;
        final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
        final currentChat = data['currentChat'] as String?;
        
        // If user was active in this chat within last 30 seconds, don't send notification
        if (currentChat == chatId && lastSeen != null) {
          final timeDiff = DateTime.now().difference(lastSeen).inSeconds;
          return timeDiff < 30;
        }
      }
      
      return false;
    } catch (e) {
      log('Error checking user activity: $e');
      return false;
    }
  }

  // Update user presence when entering chat
  Future<void> updateUserPresence(String chatId, {bool isActive = true}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('presence')
          .doc('status')
          .set({
        'lastSeen': FieldValue.serverTimestamp(),
        'currentChat': isActive ? chatId : null,
        'isOnline': isActive,
      }, SetOptions(merge: true));
    } catch (e) {
      log('Error updating presence: $e');
    }
  }

  // Get message preview for notification
  String _getMessagePreview(String message) {
    if (message.length > 50) {
      return '${message.substring(0, 50)}...';
    }
    return message;
  }

  // Get location preview for notification
  String _getLocationPreview(String address) {
    if (address.length > 30) {
      return '${address.substring(0, 30)}...';
    }
    return address;
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final Reference ref = _storage.ref().child('chat_images/$fileName');
      
      final UploadTask uploadTask = ref.putFile(File(imageFile.path));
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      log('Error uploading image: $e');
      return null;
    }
  }

  // Start typing indicator
  void startTyping() {
    if (_chat == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (!_isTyping) {
      _isTyping = true;
      
      // Update typing status in Firestore
      _firestore.collection('chats').doc(_chat!.id).update({
        'isTyping.${currentUser.uid}': true,
      });
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 3), () {
      _stopTyping();
    });
  }

  // Stop typing indicator
  void _stopTyping() {
    if (_chat == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (_isTyping) {
      _isTyping = false;
      
      // Update typing status in Firestore
      _firestore.collection('chats').doc(_chat!.id).update({
        'isTyping.${currentUser.uid}': false,
      });
      
      notifyListeners();
    }
    
    _typingTimer?.cancel();
  }

  // Mark chat as read
  Future<void> _markChatAsRead(String chatId) async {
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

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    if (_chat == null) return;

    try {
      await _firestore
          .collection('chats')
          .doc(_chat!.id)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      log('Error deleting message: $e');
    }
  }

  // Get message groups by date
  Map<String, List<MessageModel>> getMessagesByDate() {
    Map<String, List<MessageModel>> groupedMessages = {};
    
    for (var message in _messages) {
      final dateKey = _getDateKey(message.timestamp);
      
      if (!groupedMessages.containsKey(dateKey)) {
        groupedMessages[dateKey] = [];
      }
      
      groupedMessages[dateKey]!.add(message);
    }
    
    return groupedMessages;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    
    // Update presence when leaving chat
    if (_chat != null) {
      updateUserPresence(_chat!.id, isActive: false);
    }
    
    super.dispose();
  }

}
