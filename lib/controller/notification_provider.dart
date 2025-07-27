import 'dart:async';
import 'dart:developer';
import 'package:arabicmarketplace/controller/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  StreamSubscription<User?>? _authSubscription;

  // Notification preferences
  Map<String, bool> _preferences = {
    'newMessage': true,
    'savedSearch': true,
    'itemSold': true,
    'newFollower': true,
    'priceReduction': true,
    'itemExpiring': true,
  };

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  Map<String, bool> get preferences => _preferences;

  // Individual preference getters for easy access
  bool get newMessageNotifications => _preferences['newMessage'] ?? true;
  bool get savedSearchNotifications => _preferences['savedSearch'] ?? true;
  bool get itemSoldNotifications => _preferences['itemSold'] ?? true;
  bool get newFollowerNotifications => _preferences['newFollower'] ?? true;
  bool get priceReductionNotifications => _preferences['priceReduction'] ?? true;
  bool get itemExpiringNotifications => _preferences['itemExpiring'] ?? true;

  NotificationProvider() {
    _initializeProvider();
  }

  // Initialize provider
  void _initializeProvider() {

    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _setupNotificationListener(user.uid);
        loadNotificationPreferences();
      } else {
        _clearNotifications();
      }
      // sendTestNotification();
    });
  }

  // Setup real-time notification listener
  void _setupNotificationListener(String userId) {
    _notificationsSubscription?.cancel();
    
    _notificationsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          _notifications = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          // Calculate unread count
          _unreadCount = _notifications.where((n) => n['read'] != true).length;

          _setError(null);
          notifyListeners();
        } catch (e) {
          _setError('Error loading notifications: $e');
        }
      },
      onError: (error) {
        _setError('Notification stream error: $error');
      },
    );
  }

  // Clear notifications when user logs out
  void _clearNotifications() {
    _notificationsSubscription?.cancel();
    _notifications.clear();
    _unreadCount = 0;
    _preferences = {
      'newMessage': true,
      'savedSearch': true,
      'itemSold': true,
      'newFollower': true,
      'priceReduction': true,
      'itemExpiring': true,
    };
    notifyListeners();
  }

  // Load notification preferences
  Future<void> loadNotificationPreferences() async {
    try {
      _setLoading(true);

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _preferences = {
          'newMessage': data['newMessage'] ?? true,
          'savedSearch': data['savedSearch'] ?? true,
          'itemSold': data['itemSold'] ?? true,
          'newFollower': data['newFollower'] ?? true,
          'priceReduction': data['priceReduction'] ?? true,
          'itemExpiring': data['itemExpiring'] ?? true,
        };
      }

      _setLoading(false);
      _setError(null);
    } catch (e) {
      _setError('Error loading preferences: $e');
      _setLoading(false);
    }
  }

  // Update notification preference
  Future<bool> updateNotificationPreference(String type, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        return false;
      }

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .set({
        type: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update local state
      _preferences[type] = value;
      notifyListeners();

      // Update in NotificationService
      await NotificationService.instance.updateNotificationPreference(
        user.uid, 
        type, 
        value
      );

      return true;
    } catch (e) {
      _setError('Error updating preference: $e');
      return false;
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      final notificationIndex = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (notificationIndex != -1) {
        _notifications[notificationIndex]['read'] = true;
        _unreadCount = _notifications.where((n) => n['read'] != true).length;
        notifyListeners();
      }

    } catch (e) {
      log('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _setLoading(true);

      // Get all unread notifications
      final unreadNotifications = _notifications.where((n) => n['read'] != true).toList();

      if (unreadNotifications.isEmpty) {
        _setLoading(false);
        return;
      }

      // Update in Firestore using batch
      final batch = _firestore.batch();
      for (final notification in unreadNotifications) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notification['id']);
        
        batch.update(docRef, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Update local state
      for (final notification in _notifications) {
        notification['read'] = true;
      }
      _unreadCount = 0;

      _setLoading(false);
      notifyListeners();

    } catch (e) {
      _setError('Error marking all as read: $e');
      _setLoading(false);
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Update local state
      _notifications.removeWhere((n) => n['id'] == notificationId);
      _unreadCount = _notifications.where((n) => n['read'] != true).length;
      notifyListeners();

    } catch (e) {
      log('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _setLoading(true);

      // Delete all notifications in Firestore
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Update local state
      _notifications.clear();
      _unreadCount = 0;

      _setLoading(false);
      notifyListeners();

    } catch (e) {
      _setError('Error clearing notifications: $e');
      _setLoading(false);
    }
  }

  // Get notifications by type
  List<Map<String, dynamic>> getNotificationsByType(String type) {
    return _notifications.where((n) => n['type'] == type).toList();
  }

  // Get recent notifications (last 24 hours)
  List<Map<String, dynamic>> getRecentNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    return _notifications.where((n) {
      final createdAt = n['createdAt'] as Timestamp?;
      if (createdAt == null) return false;
      return createdAt.toDate().isAfter(yesterday);
    }).toList();
  }

  // Get notification statistics
  Map<String, int> getNotificationStats() {
    final stats = <String, int>{
      'total': _notifications.length,
      'unread': _unreadCount,
      'read': _notifications.length - _unreadCount,
    };

    // Count by type
    for (final notification in _notifications) {
      final type = notification['type'] as String? ?? 'unknown';
      stats[type] = (stats[type] ?? 0) + 1;
    }

    return stats;
  }

  // Handle notification tap (navigation)
  void handleNotificationTap(Map<String, dynamic> notification) {
    try {
      final type = notification['type'] as String?;
      final data = notification['data'] as Map<String, dynamic>? ?? {};

      // Mark as read if not already
      if (notification['read'] != true) {
        markNotificationAsRead(notification['id']);
      }

      // Navigate based on notification type
      switch (type) {
        case 'newMessage':
          _navigateToChat(data['chatId']);
          break;
        case 'savedSearch':
          _navigateToItem(data['itemId']);
          break;
        case 'itemSold':
          _navigateToMyItems();
          break;
        case 'newFollower':
          _navigateToProfile(data['followerId']);
          break;
        default:
          log('Unknown notification type: $type');
      }

    } catch (e) {
      log('Error handling notification tap: $e');
    }
  }

  // Navigation methods (implement based on your app's navigation)
  void _navigateToChat(String? chatId) {
    if (chatId != null) {
      // TODO: Implement navigation to chat
      log('Navigate to chat: $chatId');
    }
  }

  void _navigateToItem(String? itemId) {
    if (itemId != null) {
      // TODO: Implement navigation to item details
      log('Navigate to item: $itemId');
    }
  }

  void _navigateToMyItems() {
    // TODO: Implement navigation to user's items
    log('Navigate to my items');
  }

  void _navigateToProfile(String? userId) {
    if (userId != null) {
      // TODO: Implement navigation to user profile
      log('Navigate to profile: $userId');
    }
  }

  // Test notification sending
  Future<void> sendTestNotification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await NotificationService.instance.sendSavedSearchNotification(
        userId: user.uid,
        itemTitle: 'Test iPhone 14 Pro',
        itemId: 'test_item_123',
        savedSearchName: 'Test Search',
        location: 'Test City, Test Country',
        price: '999',
      );

      log('Test notification sent');
    } catch (e) {
      log('Error sending test notification: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}

// Enhanced NotificationService that actually sends push notifications
class SimpleNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send message notification with actual push notification
  static Future<bool> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String messagePreview,
    required String chatId,
    String? senderAvatar,
  }) async {
    try {
      // Check if user has message notifications enabled
      final preferences = await _getUserNotificationPreferences(recipientId);
      if (preferences['newMessage'] != true) {
        log('User has disabled message notifications');
        return false;
      }

      // Store notification in Firestore
      await _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .add({
        'type': 'newMessage',
        'title': 'New Message',
        'body': '$senderName: $messagePreview',
        'data': {
          'chatId': chatId,
          'senderName': senderName,
          'senderAvatar': senderAvatar,
          'messagePreview': messagePreview,
          'action': 'open_chat',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send actual push notification using the comprehensive NotificationService
      final success = await NotificationService.instance.sendMessageNotification(
        recipientId: recipientId,
        senderName: senderName,
        messagePreview: messagePreview,
        chatId: chatId,
        senderAvatar: senderAvatar,
      );

      log('Message notification sent: $success');
      return success;

    } catch (e) {
      log('Error sending message notification: $e');
      return false;
    }
  }

  // Send saved search notification with actual push notification
  static Future<bool> sendSavedSearchNotification({
    required String userId,
    required String itemTitle,
    required String itemId,
    required String savedSearchName,
    required String location,
    String? price,
    String? imageUrl,
  }) async {
    try {
      // Check if user has saved search notifications enabled
      final preferences = await _getUserNotificationPreferences(userId);
      if (preferences['savedSearch'] != true) {
        log('User has disabled saved search notifications');
        return false;
      }

      // Store notification in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'savedSearch',
        'title': 'New Match for "$savedSearchName"',
        'body': '$itemTitle${price != null ? ' • \$$price' : ''} • $location',
        'data': {
          'itemId': itemId,
          'itemTitle': itemTitle,
          'savedSearchName': savedSearchName,
          'location': location,
          'price': price,
          'imageUrl': imageUrl,
          'action': 'view_item',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send actual push notification using the comprehensive NotificationService
      final success = await NotificationService.instance.sendSavedSearchNotification(
        userId: userId,
        itemTitle: itemTitle,
        itemId: itemId,
        savedSearchName: savedSearchName,
        location: location,
        price: price,
        imageUrl: imageUrl,
      );

      log('Saved search notification sent: $success');
      return success;

    } catch (e) {
      log('Error sending saved search notification: $e');
      return false;
    }
  }

  // Send item sold notification
  static Future<void> sendItemSoldNotification({
    required String sellerId,
    required String itemTitle,
    required String itemId,
    required String buyerName,
    String? price,
  }) async {
    try {
      final preferences = await _getUserNotificationPreferences(sellerId);
      if (preferences['itemSold'] != true) {
        log('User has disabled item sold notifications');
        // return false;
      }

      final title = 'Item Sold!';
      final body = 'Your "$itemTitle" was sold to $buyerName${price != null ? ' for \$$price' : ''}';

      // Store notification in Firestore
      await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('notifications')
          .add({
        'type': 'itemSold',
        'title': title,
        'body': body,
        'data': {
          'itemId': itemId,
          'itemTitle': itemTitle,
          'buyerName': buyerName,
          'price': price,
          'action': 'view_sold_items',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send actual push notification
      final success = await NotificationService.instance.sendNotificationToUser(
        userId: sellerId,
        title: title,
        body: body,
        type: 'itemSold',
        data: {
          'itemId': itemId,
          'itemTitle': itemTitle,
          'buyerName': buyerName,
          'price': price,
        },
      );

      log('Item sold notification sent: ');
      // return success;

    } catch (e) {
      log('Error sending item sold notification: $e');
      // return false;
    }
  }

  // Send new follower notification
  static Future<bool> sendNewFollowerNotification({
    required String userId,
    required String followerName,
    required String followerId,
    String? followerAvatar,
  }) async {
    try {
      final preferences = await _getUserNotificationPreferences(userId);
      if (preferences['newFollower'] != true) {
        log('User has disabled new follower notifications');
        return false;
      }

      final title = 'New Follower';
      final body = '$followerName started following you';

      // Store notification in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'newFollower',
        'title': title,
        'body': body,
        'data': {
          'followerId': followerId,
          'followerName': followerName,
          'followerAvatar': followerAvatar,
          'action': 'view_profile',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send actual push notification
      await NotificationService.instance.sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        type: 'newFollower',
        data: {
          'followerId': followerId,
          'followerName': followerName,
          'followerAvatar': followerAvatar,
        },
        imageUrl: followerAvatar,
      );

      log('New follower notification sent');
      return true;

    } catch (e) {
      log('Error sending new follower notification: $e');
      return false;
    }
  }

  // Send price reduction notification
  static Future<bool> sendPriceReductionNotification({
    required String userId,
    required String itemTitle,
    required String itemId,
    required String oldPrice,
    required String newPrice,
    String? imageUrl,
  }) async {
    try {
      final preferences = await _getUserNotificationPreferences(userId);
      if (preferences['priceReduction'] != true) {
        log('User has disabled price reduction notifications');
        return false;
      }

      final title = 'Price Drop Alert!';
      final body = '$itemTitle price dropped from \$$oldPrice to \$$newPrice';

      // Store notification in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'priceReduction',
        'title': title,
        'body': body,
        'data': {
          'itemId': itemId,
          'itemTitle': itemTitle,
          'oldPrice': oldPrice,
          'newPrice': newPrice,
          'imageUrl': imageUrl,
          'action': 'view_item',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send actual push notification
      await NotificationService.instance.sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        type: 'priceReduction',
        data: {
          'itemId': itemId,
          'itemTitle': itemTitle,
          'oldPrice': oldPrice,
          'newPrice': newPrice,
        },
        imageUrl: imageUrl,
      );

      log('Price reduction notification sent');
      return true;

    } catch (e) {
      log('Error sending price reduction notification: $e');
      return false;
    }
  }

  // Send notification to multiple users (bulk notification)
  static Future<void> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      // Use the comprehensive NotificationService for bulk sending
      await NotificationService.instance.sendNotificationToMultipleUsers(
        userIds: userIds,
        title: title,
        body: body,
        type: type,
        data: data,
        imageUrl: imageUrl,
      );

      log('Bulk notification sent to ${userIds.length} users');
    } catch (e) {
      log('Error sending bulk notification: $e');
    }
  }

  // Get user notification preferences
  static Future<Map<String, bool>> _getUserNotificationPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'newMessage': data['newMessage'] ?? true,
          'savedSearch': data['savedSearch'] ?? true,
          'itemSold': data['itemSold'] ?? true,
          'newFollower': data['newFollower'] ?? true,
          'priceReduction': data['priceReduction'] ?? true,
          'itemExpiring': data['itemExpiring'] ?? true,
        };
      }

      return {
        'newMessage': true,
        'savedSearch': true,
        'itemSold': true,
        'newFollower': true,
        'priceReduction': true,
        'itemExpiring': true,
      };
    } catch (e) {
      log('Error getting notification preferences: $e');
      return {
        'newMessage': true,
        'savedSearch': true,
        'itemSold': true,
        'newFollower': true,
        'priceReduction': true,
        'itemExpiring': true,
      };
    }
  }

  // Helper method to send custom notification
  static Future<bool> sendCustomNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      // Store in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': type,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send push notification
      await NotificationService.instance.sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
        imageUrl: imageUrl,
      );

      return true;
    } catch (e) {
      log('Error sending custom notification: $e');
      return false;
    }
  }
}