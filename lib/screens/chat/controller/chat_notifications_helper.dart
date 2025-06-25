// Chat-specific notification helpers
import 'dart:developer';
import 'package:arabicmarketplace/controller/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatNotificationHelpers {
  static final NotificationService _notificationService = NotificationService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send notification when new message is received
  static Future<void> sendNewMessageNotification({
    required String recipientId,
    required String senderName,
    required String senderId,
    required String messageText,
    required String chatId,
    String? productTitle,
    String? productId,
  }) async {
    try {
      // Check if recipient has message notifications enabled
      final preferences = await _notificationService.getUserNotificationPreferences(recipientId);
      if (preferences['newMessage'] != true) {
        log('User has disabled message notifications');
        return;
      }

      // Check if user is currently active in this chat
      final isUserActive = await _isUserActiveInChat(recipientId, chatId);
      if (isUserActive) {
        log('User is active in chat, skipping notification');
        return;
      }

      // Create notification title and body
      String notificationTitle = senderName;
      String notificationBody = _getMessagePreview(messageText);

      // Add product context if available
      if (productTitle != null) {
        notificationTitle = '$senderName • $productTitle';
      }

      await _notificationService.sendNotificationToUser(
        userId: recipientId,
        title: notificationTitle,
        body: notificationBody,
        type: 'newMessage',
        data: {
          'chatId': chatId,
          'senderId': senderId,
          'senderName': senderName,
          'messagePreview': notificationBody,
          'productId': productId,
          'productTitle': productTitle,
          'notificationType': 'chat_message',
        },
      );

      log('New message notification sent to $recipientId');
    } catch (e) {
      log('Error sending message notification: $e');
    }
  }

  // Send notification for image messages
  static Future<void> sendImageMessageNotification({
    required String recipientId,
    required String senderName,
    required String senderId,
    required String chatId,
    String? productTitle,
    String? productId,
  }) async {
    try {
      final preferences = await _notificationService.getUserNotificationPreferences(recipientId);
      if (preferences['newMessage'] != true) return;

      final isUserActive = await _isUserActiveInChat(recipientId, chatId);
      if (isUserActive) return;

      String notificationTitle = senderName;
      if (productTitle != null) {
        notificationTitle = '$senderName • $productTitle';
      }

      await _notificationService.sendNotificationToUser(
        userId: recipientId,
        title: notificationTitle,
        body: '📸 Photo',
        type: 'newMessage',
        data: {
          'chatId': chatId,
          'senderId': senderId,
          'senderName': senderName,
          'messageType': 'image',
          'productId': productId,
          'productTitle': productTitle,
          'notificationType': 'chat_image',
        },
      );

      log('Image message notification sent to $recipientId');
    } catch (e) {
      log('Error sending image notification: $e');
    }
  }

  // Send notification for location messages
  static Future<void> sendLocationMessageNotification({
    required String recipientId,
    required String senderName,
    required String senderId,
    required String chatId,
    required String locationAddress,
    String? productTitle,
    String? productId,
  }) async {
    try {
      final preferences = await _notificationService.getUserNotificationPreferences(recipientId);
      if (preferences['newMessage'] != true) return;

      final isUserActive = await _isUserActiveInChat(recipientId, chatId);
      if (isUserActive) return;

      String notificationTitle = senderName;
      if (productTitle != null) {
        notificationTitle = '$senderName • $productTitle';
      }

      await _notificationService.sendNotificationToUser(
        userId: recipientId,
        title: notificationTitle,
        body: '📍 Location: ${_getLocationPreview(locationAddress)}',
        type: 'newMessage',
        data: {
          'chatId': chatId,
          'senderId': senderId,
          'senderName': senderName,
          'messageType': 'location',
          'locationAddress': locationAddress,
          'productId': productId,
          'productTitle': productTitle,
          'notificationType': 'chat_location',
        },
      );

      log('Location message notification sent to $recipientId');
    } catch (e) {
      log('Error sending location notification: $e');
    }
  }

  // Send notification when product offer is made
  static Future<void> sendProductOfferNotification({
    required String recipientId,
    required String senderName,
    required String senderId,
    required String chatId,
    required String productTitle,
    required String productId,
    required double offerPrice,
    required double originalPrice,
  }) async {
    try {
      // For offers, we might want to send even if user is active
      final preferences = await _notificationService.getUserNotificationPreferences(recipientId);
      if (preferences['newMessage'] != true) return;

      final discountPercentage = ((originalPrice - offerPrice) / originalPrice * 100).round();

      await _notificationService.sendNotificationToUser(
        userId: recipientId,
        title: '💰 New Offer - $productTitle',
        body: '$senderName offered \$${offerPrice.toStringAsFixed(2)} (${discountPercentage}% off)',
        type: 'offerReceived',
        data: {
          'chatId': chatId,
          'senderId': senderId,
          'senderName': senderName,
          'productId': productId,
          'productTitle': productTitle,
          'offerPrice': offerPrice,
          'originalPrice': originalPrice,
          'discountPercentage': discountPercentage,
          'notificationType': 'product_offer',
        },
      );

      log('Product offer notification sent to $recipientId');
    } catch (e) {
      log('Error sending offer notification: $e');
    }
  }

  // Send notification when offer is accepted/rejected
  static Future<void> sendOfferResponseNotification({
    required String recipientId,
    required String senderName,
    required String senderId,
    required String chatId,
    required String productTitle,
    required String productId,
    required double offerPrice,
    required bool isAccepted,
  }) async {
    try {
      final preferences = await _notificationService.getUserNotificationPreferences(recipientId);
      if (preferences['newMessage'] != true) return;

      String title = isAccepted ? '✅ Offer Accepted!' : '❌ Offer Declined';
      String body = isAccepted 
          ? '$senderName accepted your offer of \$${offerPrice.toStringAsFixed(2)} for $productTitle'
          : '$senderName declined your offer for $productTitle';

      await _notificationService.sendNotificationToUser(
        userId: recipientId,
        title: title,
        body: body,
        type: isAccepted ? 'offerAccepted' : 'offerDeclined',
        data: {
          'chatId': chatId,
          'senderId': senderId,
          'senderName': senderName,
          'productId': productId,
          'productTitle': productTitle,
          'offerPrice': offerPrice,
          'isAccepted': isAccepted,
          'notificationType': 'offer_response',
        },
      );

      log('Offer response notification sent to $recipientId');
    } catch (e) {
      log('Error sending offer response notification: $e');
    }
  }

  // Send notification when user starts/stops typing (optional)
  static Future<void> sendTypingNotification({
    required String recipientId,
    required String senderName,
    required String chatId,
    required bool isTyping,
  }) async {
    try {
      // This is typically handled in real-time via WebSocket/Firestore listeners
      // But you can send push notifications for typing indicators if needed
      
      if (isTyping) {
        // Only send if user is not active in chat
        final isUserActive = await _isUserActiveInChat(recipientId, chatId);
        if (!isUserActive) {
          await _notificationService.sendNotificationToUser(
            userId: recipientId,
            title: senderName,
            body: 'is typing...',
            type: 'typing',
            data: {
              'chatId': chatId,
              'senderId': FirebaseAuth.instance.currentUser?.uid ?? '',
              'senderName': senderName,
              'isTyping': isTyping,
              'notificationType': 'typing_indicator',
            },
          );
        }
      }
    } catch (e) {
      log('Error sending typing notification: $e');
    }
  }

  // Send notification when chat is archived/deleted
  static Future<void> sendChatStatusNotification({
    required String recipientId,
    required String senderName,
    required String chatId,
    required String status, // 'archived', 'deleted', 'blocked'
    String? productTitle,
  }) async {
    try {
      String title = '';
      String body = '';

      switch (status) {
        case 'archived':
          title = 'Chat Archived';
          body = 'Your conversation with $senderName has been archived';
          break;
        case 'deleted':
          title = 'Chat Deleted';
          body = 'Your conversation with $senderName has been deleted';
          break;
        case 'blocked':
          title = 'User Blocked';
          body = 'You have been blocked by $senderName';
          break;
      }

      if (productTitle != null) {
        body += ' regarding "$productTitle"';
      }

      await _notificationService.sendNotificationToUser(
        userId: recipientId,
        title: title,
        body: body,
        type: 'chatStatus',
        data: {
          'chatId': chatId,
          'senderName': senderName,
          'status': status,
          'productTitle': productTitle,
          'notificationType': 'chat_status',
        },
      );

      log('Chat status notification sent to $recipientId');
    } catch (e) {
      log('Error sending chat status notification: $e');
    }
  }

  // Check if user is currently active in chat
  static Future<bool> _isUserActiveInChat(String userId, String chatId) async {
    try {
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
        final isOnline = data['isOnline'] as bool? ?? false;
        
        // If user is online and was active in this chat within last 30 seconds
        if (isOnline && currentChat == chatId && lastSeen != null) {
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

  // Get message preview for notification (truncate long messages)
  static String _getMessagePreview(String message) {
    if (message.length > 100) {
      return '${message.substring(0, 100)}...';
    }
    return message;
  }

  // Get location preview for notification
  static String _getLocationPreview(String address) {
    if (address.length > 50) {
      return '${address.substring(0, 50)}...';
    }
    return address;
  }

  // Update user presence when entering/leaving chat
  static Future<void> updateUserPresence(String chatId, {bool isActive = true}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
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
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      log('User presence updated for chat: $chatId, active: $isActive');
    } catch (e) {
      log('Error updating presence: $e');
    }
  }

  // Batch send notifications for multiple users (e.g., group chats)
  static Future<void> sendBatchChatNotifications({
    required List<String> recipientIds,
    required String senderName,
    required String senderId,
    required String chatId,
    required String message,
    String? productTitle,
    String? productId,
  }) async {
    try {
      for (String recipientId in recipientIds) {
        if (recipientId != senderId) { // Don't send to sender
          await sendNewMessageNotification(
            recipientId: recipientId,
            senderName: senderName,
            senderId: senderId,
            messageText: message,
            chatId: chatId,
            productTitle: productTitle,
            productId: productId,
          );
        }
      }
      
      log('Batch notifications sent to ${recipientIds.length} users');
    } catch (e) {
      log('Error sending batch notifications: $e');
    }
  }

  // Schedule delayed notifications (e.g., for unread messages)
  static Future<void> scheduleUnreadMessageReminder({
    required String recipientId,
    required String senderName,
    required String chatId,
    required int unreadCount,
    String? productTitle,
  }) async {
    try {
      // This would typically be handled by a cloud function
      // For now, we'll just log it
      log('Scheduled reminder for $recipientId: $unreadCount unread messages from $senderName');
      
      // You can implement this with Cloud Functions or a background service
      // that checks for unread messages after a certain time period
    } catch (e) {
      log('Error scheduling reminder: $e');
    }
  }

  // Send notification for missed calls (if you implement voice/video calls)
  static Future<void> sendMissedCallNotification({
    required String recipientId,
    required String callerName,
    required String callerId,
    required String chatId,
    required String callType, // 'voice' or 'video'
    String? productTitle,
  }) async {
    try {
      final preferences = await _notificationService.getUserNotificationPreferences(recipientId);
      if (preferences['newMessage'] != true) return;

      String callIcon = callType == 'video' ? '📹' : '📞';
      String title = 'Missed $callType call';
      String body = '$callIcon $callerName tried to call you';

      if (productTitle != null) {
        body += ' about "$productTitle"';
      }

      await _notificationService.sendNotificationToUser(
        userId: recipientId,
        title: title,
        body: body,
        type: 'missedCall',
        data: {
          'chatId': chatId,
          'callerId': callerId,
          'callerName': callerName,
          'callType': callType,
          'productTitle': productTitle,
          'notificationType': 'missed_call',
        },
      );

      log('Missed call notification sent to $recipientId');
    } catch (e) {
      log('Error sending missed call notification: $e');
    }
  }
}