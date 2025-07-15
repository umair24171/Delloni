// notification_handler.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationHandler {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Initialize local notifications
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

    // Set up message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Handle notification when app is launched from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'saved_search_channel',
      'Saved Search Notifications',
      channelDescription: 'Notifications for saved search matches',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Match Found',
      message.notification?.body ?? 'A new item matches your saved search',
      platformChannelSpecifics,
      payload: message.data['type'],
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // Handle notification tap - navigate to appropriate screen
    final type = message.data['type'];
    final itemId = message.data['itemId'];
    final chatId = message.data['chatId'];
    final savedSearchId = message.data['savedSearchId'];

    // You can use a global navigator key or pass context
    // For now, just print the action
    print('Notification tapped: type=$type, itemId=$itemId, chatId=$chatId');
    
    // Navigate based on notification type
    if (type == 'savedSearch' && itemId != null) {
      // Navigate to product detail page
      _navigateToProductDetail(itemId);
    } else if (type == 'newMessage' && chatId != null) {
      // Navigate to chat page
      _navigateToChat(chatId);
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle local notification tap
    final payload = response.payload;
    if (payload != null) {
      print('Local notification tapped: $payload');
    }
  }

  static void _navigateToProductDetail(String itemId) {
    // Implement navigation to product detail
    // You might need to use a global navigator key for this
    print('Navigate to product: $itemId');
  }

  static void _navigateToChat(String chatId) {
    // Implement navigation to chat
    print('Navigate to chat: $chatId');
  }

  static Future<String?> getFirebaseToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting Firebase token: $e');
      return null;
    }
  }
}

// enhanced_notification_service.dart
class EnhancedNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Send saved search notification with push notification
  static Future<void> sendSavedSearchNotification({
    required String userId,
    required String itemTitle,
    required String itemId,
    required String savedSearchName,
    required String location,
    required double? price,
    required String? imageUrl,
  }) async {
    try {
      // Check if user has saved search notifications enabled
      final preferences = await _getUserNotificationPreferences(userId);
      if (preferences['savedSearch'] != true) {
        print('User has disabled saved search notifications');
        return;
      }

      // Store notification in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'savedSearch',
        'title': 'New item matches your search!',
        'body': 'A new "$itemTitle" matches your "$savedSearchName" search in $location',
        'data': {
          'itemId': itemId,
          'itemTitle': itemTitle,
          'savedSearchName': savedSearchName,
          'location': location,
          'price': price,
          'imageUrl': imageUrl,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send push notification
      await _sendPushNotification(
        userId: userId,
        title: '🔍 New match found!',
        body: '"$itemTitle" matches your "$savedSearchName" search',
        data: {
          'type': 'savedSearch',
          'itemId': itemId,
          'itemTitle': itemTitle,
          'savedSearchName': savedSearchName,
          'location': location,
          'price': price?.toString(),
          'imageUrl': imageUrl,
        },
      );

      print('Saved search notification sent to user: $userId');
    } catch (e) {
      print('Error sending saved search notification: $e');
    }
  }

  // Enhanced message notification
  static Future<void> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String messagePreview,
    required String chatId,
  }) async {
    try {
      // Check if user has message notifications enabled
      final preferences = await _getUserNotificationPreferences(recipientId);
      if (preferences['newMessage'] != true) return;

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
        },
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send push notification
      await _sendPushNotification(
        userId: recipientId,
        title: '💬 $senderName',
        body: messagePreview,
        data: {
          'type': 'newMessage',
          'chatId': chatId,
          'senderName': senderName,
        },
      );

      print('Message notification sent to user: $recipientId');
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }

  // Send push notification to specific user
  static Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        print('No FCM token found for user: $userId');
        return;
      }

      // Send notification using Firebase Admin SDK
      // Note: You'll need to implement this server-side or use Cloud Functions
      await _sendFCMNotification(
        token: fcmToken,
        title: title,
        body: body,
        data: data,
      );

    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // This would typically be implemented server-side with Firebase Admin SDK
  static Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // For client-side implementation, you'd need to call your backend API
    // that uses Firebase Admin SDK to send notifications
    
    try {
      // Example API call to your backend
      final response = await http.post(
        Uri.parse('https://your-backend-url.com/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        print('Push notification sent successfully');
      } else {
        print('Failed to send push notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling notification API: $e');
    }
  }

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
        };
      }

      return {
        'newMessage': true,
        'savedSearch': true,
      };
    } catch (e) {
      return {
        'newMessage': true,
        'savedSearch': true,
      };
    }
  }

  // Save FCM token for user
  static Future<void> saveUserFCMToken(String userId) async {
    try {
      final token = await NotificationHandler.getFirebaseToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('FCM token saved for user: $userId');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}

// Firebase Cloud Functions (functions/index.js)
/*
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Cloud Function to send notifications when new items are added
exports.checkSavedSearches = functions.firestore
  .document('items/{itemId}')
  .onCreate(async (snap, context) => {
    const newItem = snap.data();
    const itemId = context.params.itemId;
    
    try {
      // Get all active saved searches
      const savedSearchesSnapshot = await admin.firestore()
        .collection('savedSearches')
        .where('isActive', '==', true)
        .get();
      
      const notifications = [];
      
      for (const doc of savedSearchesSnapshot.docs) {
        const savedSearch = doc.data();
        
        // Check if item matches saved search
        if (await itemMatchesSavedSearch(newItem, savedSearch)) {
          // Prepare notification
          const notification = {
            userId: savedSearch.userId,
            itemId: itemId,
            itemTitle: newItem.itemTitle,
            savedSearchName: savedSearch.name,
            location: newItem.cityName || newItem.locationAddress || 'Unknown location',
            price: newItem.price,
            imageUrl: newItem.imageUrls && newItem.imageUrls.length > 0 ? newItem.imageUrls[0] : null,
          };
          
          notifications.push(notification);
        }
      }
      
      // Send all notifications
      for (const notification of notifications) {
        await sendSavedSearchNotification(notification);
      }
      
      console.log(`Sent ${notifications.length} saved search notifications`);
      
    } catch (error) {
      console.error('Error checking saved searches:', error);
    }
  });

async function itemMatchesSavedSearch(item, savedSearch) {
  try {
    // Text search match
    if (savedSearch.query) {
      const searchTerms = savedSearch.query.toLowerCase().split(' ');
      const searchableText = `${item.itemTitle || ''} ${item.description || ''} ${item.brand || ''} ${item.categoryName || ''} ${item.color || ''}`.toLowerCase();
      
      const hasTextMatch = searchTerms.some(term => searchableText.includes(term));
      if (!hasTextMatch) return false;
    }
    
    // Category match
    if (savedSearch.categoryId && item.category !== savedSearch.categoryId) {
      return false;
    }
    
    // Price range match
    if (savedSearch.minPrice && item.price < savedSearch.minPrice) return false;
    if (savedSearch.maxPrice && item.price > savedSearch.maxPrice) return false;
    
    // Location match
    if (savedSearch.cityId && item.cityId !== savedSearch.cityId) return false;
    if (savedSearch.districtId && item.districtId !== savedSearch.districtId) return false;
    
    return true;
  } catch (error) {
    console.error('Error matching item to saved search:', error);
    return false;
  }
}

async function sendSavedSearchNotification(notification) {
  try {
    // Get user's FCM token
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(notification.userId)
      .get();
    
    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log('No FCM token found for user:', notification.userId);
      return;
    }
    
    // Check notification preferences
    const notificationPrefs = await admin.firestore()
      .collection('users')
      .doc(notification.userId)
      .collection('settings')
      .doc('notifications')
      .get();
    
    const savedSearchEnabled = notificationPrefs.exists 
      ? notificationPrefs.data().savedSearch !== false 
      : true;
    
    if (!savedSearchEnabled) {
      console.log('User has disabled saved search notifications:', notification.userId);
      return;
    }
    
    // Create notification message
    const message = {
      token: fcmToken,
      notification: {
        title: '🔍 New match found!',
        body: `"${notification.itemTitle}" matches your "${notification.savedSearchName}" search`,
      },
      data: {
        type: 'savedSearch',
        itemId: notification.itemId,
        itemTitle: notification.itemTitle,
        savedSearchName: notification.savedSearchName,
        location: notification.location,
        price: notification.price ? notification.price.toString() : '',
        imageUrl: notification.imageUrl || '',
      },
    };
    
    // Send notification
    await admin.messaging().send(message);
    
    // Store notification in Firestore
    await admin.firestore()
      .collection('users')
      .doc(notification.userId)
      .collection('notifications')
      .add({
        type: 'savedSearch',
        title: 'New item matches your search!',
        body: `A new "${notification.itemTitle}" matches your "${notification.savedSearchName}" search in ${notification.location}`,
        data: {
          itemId: notification.itemId,
          itemTitle: notification.itemTitle,
          savedSearchName: notification.savedSearchName,
          location: notification.location,
          price: notification.price,
          imageUrl: notification.imageUrl,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      });
    
    // Update saved search match count and last notification time
    await admin.firestore()
      .collection('savedSearches')
      .doc(notification.savedSearchId)
      .update({
        matchCount: admin.firestore.FieldValue.increment(1),
        lastNotificationSent: admin.firestore.FieldValue.serverTimestamp(),
      });
    
    console.log('Saved search notification sent to user:', notification.userId);
    
  } catch (error) {
    console.error('Error sending saved search notification:', error);
  }
}
*/

// // user_provider.dart update - ADD this method to your UserProvider class:
// // Add this method to your existing UserProvider class:

// class UserProvider with ChangeNotifier {
//   // ... existing code ...

//   // ADD this method to save FCM token when user logs in
//   Future<void> saveFCMToken() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await EnhancedNotificationService.saveUserFCMToken(user.uid);
//       }
//     } catch (e) {
//       print('Error saving FCM token: $e');
//     }
//   }

//   // Call this method in your authentication flow
//   Future<void> onUserAuthenticated() async {
//     await saveFCMToken();
//     // ... other post-authentication tasks
//   }
// }

// // app_initialization.dart - Initialize notifications when app starts
// class AppInitialization {
//   static Future<void> initialize() async {
//     // Initialize notifications
//     await NotificationHandler.initialize();
    
//     // Save FCM token for current user
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       await EnhancedNotificationService.saveUserFCMToken(user.uid);
//     }
//   }
// }

// // Call this in your main.dart
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
  
//   // Initialize app services
//   await AppInitialization.initialize();
  
//   runApp(MyApp());
// }