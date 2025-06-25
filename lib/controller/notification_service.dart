import 'dart:async';
import 'dart:developer';
import 'package:arabicmarketplace/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize notification service
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    await _setupForegroundNotificationHandling();
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission for notifications');
      
      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
    }
  }

  // Setup foreground notification handling
  Future<void> _setupForegroundNotificationHandling() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Received foreground message: ${message.messageId}');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('Notification opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });
  }

  // Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('tokens')
            .doc('fcm')
            .set({
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
          'platform': Theme.of(navigatorKey.currentContext!).platform.name,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      log('Error saving FCM token: $e');
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'delloni_notifications',
      'Delloni Notifications',
      channelDescription: 'Notifications for Delloni marketplace',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Delloni',
      message.notification?.body ?? 'You have a new notification',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    log('Notification tapped: ${response.payload}');
    // Navigate to appropriate screen based on payload
  }

  void _handleNotificationTap(RemoteMessage message) {
    log('Handling notification tap: ${message.data}');
    // Navigate to appropriate screen based on message data
  }

  // Get user notification preferences
  Future<Map<String, bool>> getUserNotificationPreferences(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'mobile': data['mobile'] ?? true,
          'cars': data['cars'] ?? true,
          'electronics': data['electronics'] ?? true,
          'furniture': data['furniture'] ?? true,
          'clothing': data['clothing'] ?? true,
          'books': data['books'] ?? true,
          'sports': data['sports'] ?? true,
          'beauty': data['beauty'] ?? true,
          'home': data['home'] ?? true,
          'toys': data['toys'] ?? true,
          'newFollower': data['newFollower'] ?? true,
          'itemSold': data['itemSold'] ?? true,
          'priceReduction': data['priceReduction'] ?? true,
          'newMessage': data['newMessage'] ?? true,
          'itemExpiring': data['itemExpiring'] ?? true,
        };
      }

      // Return default preferences if document doesn't exist
      return {
        'mobile': true,
        'cars': true,
        'electronics': true,
        'furniture': true,
        'clothing': true,
        'books': true,
        'sports': true,
        'beauty': true,
        'home': true,
        'toys': true,
        'newFollower': true,
        'itemSold': true,
        'priceReduction': true,
        'newMessage': true,
        'itemExpiring': true,
      };
    } catch (e) {
      log('Error getting notification preferences: $e');
      return {};
    }
  }

  // Update notification preference
  Future<bool> updateNotificationPreference(String userId, String preference, bool value) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .set({
        preference: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update FCM topic subscription based on preference
      await _updateTopicSubscription(preference, value);
      
      return true;
    } catch (e) {
      log('Error updating notification preference: $e');
      return false;
    }
  }

  // Update FCM topic subscription
  Future<void> _updateTopicSubscription(String topic, bool subscribe) async {
    try {
      if (subscribe) {
        await _messaging.subscribeToTopic(topic);
        log('Subscribed to topic: $topic');
      } else {
        await _messaging.unsubscribeFromTopic(topic);
        log('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      log('Error updating topic subscription: $e');
    }
  }

  // Send notification to user
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check if user has enabled this notification type
      Map<String, bool> preferences = await getUserNotificationPreferences(userId);
      if (preferences[type] == false) {
        log('User has disabled $type notifications');
        return false;
      }

      // Create notification document
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send push notification via FCM (would typically use your backend server)
      // For now, we'll just log it
      log('Notification sent to user $userId: $title');
      
      return true;
    } catch (e) {
      log('Error sending notification: $e');
      return false;
    }
  }

  // Get user notifications
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      log('Error marking notification as read: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      log('Error getting unread count: $e');
      return 0;
    }
  }

  // Send category-based notification
  Future<void> sendCategoryNotification({
    required String category,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // This would typically be done from your backend server
      // Here we'll create a notification document for tracking
      await _firestore.collection('notifications').add({
        'category': category,
        'title': title,
        'body': body,
        'data': data ?? {},
        'sentAt': FieldValue.serverTimestamp(),
        'type': 'category_broadcast',
      });

      log('Category notification sent for: $category');
    } catch (e) {
      log('Error sending category notification: $e');
    }
  }

  // Cleanup old notifications
  Future<void> cleanupOldNotifications(String userId) async {
    try {
      // Delete notifications older than 30 days
      DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      QuerySnapshot oldNotifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      log('Cleaned up ${oldNotifications.docs.length} old notifications');
    } catch (e) {
      log('Error cleaning up notifications: $e');
    }
  }
}