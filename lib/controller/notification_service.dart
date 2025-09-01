import 'dart:async';
import 'dart:developer';
import 'package:arabicmarketplace/main.dart';
import 'package:arabicmarketplace/screens/chat/view/chat_screen.dart';
import 'package:arabicmarketplace/screens/notifications/view/notification_saved_search_page.dart';
import 'package:arabicmarketplace/screens/notifications/view/notifications_page.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
// Background message handler (must be top-level function)
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;


// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling background message: ${message.messageId}');
  // Handle background notifications here
  await NotificationService.instance.handleBackgroundMessage(message);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _currentToken;
  StreamSubscription<User?>? _authSubscription;
  
  // Firebase service account credentials
  Map<String, dynamic>? _serviceAccountCredentials;
  String? _accessToken;
  DateTime? _tokenExpiry;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      log('Initializing notification service...');
      
      // Load service account credentials
      await _loadServiceAccountCredentials();
      
      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
      await _initializeLocalNotifications();
      await _initializeFirebaseMessaging();
      await _setupForegroundNotificationHandling();
      await _setupAuthListener();
      await _updateFCMToken();
      
      _isInitialized = true;
      log('Notification service initialized successfully');
      
    } catch (e) {
      log('Error initializing notification service: $e');
    }
  }
  Future<void> clearAppBadge() async {
  try {
    // Clear all local notifications
    await _localNotifications.cancelAll();
    
    // For iOS: Reset badge count to 0
    if (Platform.isIOS) {
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: true,
        presentSound: false,
        badgeNumber: 0,
      );
      
      const NotificationDetails details = NotificationDetails(
        iOS: iOSDetails,
      );
      
      // Show a silent notification to reset badge
      await _localNotifications.show(
        -1, // Use negative ID for badge reset
        null,
        null,
        details,
      );
      
      // Immediately cancel it
      await _localNotifications.cancel(-1);
    }
    
    // For Android: Cancel all notifications (this clears the badge)
    if (Platform.isAndroid) {
      await _localNotifications.cancelAll();
    }
    
    log('App badge cleared successfully');
  } catch (e) {
    log('Error clearing app badge: $e');
  }
}


  // Load Firebase service account credentials from assets
  Future<void> _loadServiceAccountCredentials() async {
    try {
      // Place your service-account-key.json in assets folder
      final String credentialsJson = await rootBundle.loadString('assets/service-account-key.json');
      _serviceAccountCredentials = json.decode(credentialsJson);
      log('Service account credentials loaded successfully');
    } catch (e) {
      log('Error loading service account credentials: $e');
      log('Make sure to place your service-account-key.json in assets folder');
    }
  }

  // Get access token for Firebase Admin API
  Future<String?> _getAccessToken() async {
    try {
      // Check if token is still valid
      if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
        return _accessToken;
      }

      if (_serviceAccountCredentials == null) {
        log('Service account credentials not loaded');
        return null;
      }

      // Create service account credentials
      final credentials = auth.ServiceAccountCredentials.fromJson(_serviceAccountCredentials!);
      
      // Get access token
      final client = await auth.clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging']
      );

      _accessToken = client.credentials.accessToken.data;
      _tokenExpiry = client.credentials.accessToken.expiry;
      
      client.close();
      
      log('Access token obtained successfully');
      return _accessToken;
    } catch (e) {
      log('Error getting access token: $e');
      return null;
    }
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

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Messages channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'messages',
          'Messages',
          description: 'Notifications for new messages',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('message_sound'),
        ),
      );

      // Saved searches channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'saved_searches',
          'Saved Searches',
          description: 'Notifications for saved search matches',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('search_sound'),
        ),
      );

      // General channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'general',
          'General Notifications',
          description: 'General app notifications',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  // Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission for iOS and Android 13+
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );

      log('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Get and save FCM token
        await _updateFCMToken();
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
        
        // Configure message handling
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        
        log('FCM initialized successfully');
      } else {
        log('Notification permission denied');
      }
    } catch (e) {
      log('Error initializing FCM: $e');
    }
  }

  // Setup auth listener to handle token updates
  Future<void> _setupAuthListener() async {
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // User logged in, save/update token
        await _updateFCMToken();
      } else {
        // User logged out, clear token
        await _clearUserToken();
      }
    });
  }

  // Update FCM token
  Future<void> _updateFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String? token = await _messaging.getToken();
      if (token != null && token != _currentToken) {
        _currentToken = token;
        log('FCM token: $token');
        await _saveTokenToFirestore(token);
        log('FCM token updated: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      log('Error updating FCM token: $e');
    }
  }

  // Enhanced token saving function
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        log('No authenticated user, skipping token save');
        return;
      }

      final tokenData = {
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'appVersion': '1.0.0', // You can get this from package_info_plus
        'isActive': true,
      };

      // Save to user's tokens subcollection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc('fcm')
          .set(tokenData, SetOptions(merge: true));

      // Also save to main user document for easy access
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      log('Token saved successfully for user: ${user.uid}');
    } catch (e) {
      log('Error saving FCM token: $e');
    }
  }

  // Clear user token on logout
  Future<void> _clearUserToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('tokens')
            .doc('fcm')
            .update({'isActive': false});
        
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': FieldValue.delete()});
      }
      
      _currentToken = null;
      log('User token cleared');
    } catch (e) {
      log('Error clearing token: $e');
    }
  }

  // Setup foreground notification handling
  Future<void> _setupForegroundNotificationHandling() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('Notification opened app from background: ${message.messageId}');
      // Add small delay to ensure navigation context is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(message, isFromBackground: true);
      });
    });

    // Note: Initial message handling is now done in main.dart
    // This prevents race conditions during app startup
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      // Check notification preferences
      final user = _auth.currentUser;
      if (user == null) return;

      final preferences = await getUserNotificationPreferences(user.uid);
      final messageType = message.data['type'] ?? 'general';

      // Check if user has enabled this notification type
      if (!_shouldShowNotification(messageType, preferences)) {
        log('Notification disabled by user preferences: $messageType');
        return;
      }

      // Store notification in Firestore
      await _storeNotificationInFirestore(user.uid, message);

      // Show local notification
      await _showLocalNotification(message);

    } catch (e) {
      log('Error handling foreground message: $e');
    }
  }

  // Handle background messages
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      log('Processing background message: ${message.messageId}');
      
      // Store notification in Firestore
      final userId = message.data['userId'];
      if (userId != null) {
        await _storeNotificationInFirestore(userId, message);
      }
      
    } catch (e) {
      log('Error handling background message: $e');
    }
  }

  // Store notification in Firestore
  Future<void> _storeNotificationInFirestore(String userId, RemoteMessage message) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': message.notification?.title ?? 'Notification',
        'body': message.notification?.body ?? '',
        'type': message.data['type'] ?? 'general',
        'data': message.data,
        'messageId': message.messageId,
        'sentTime': message.sentTime != null 
            ? Timestamp.fromDate(message.sentTime!) 
            : FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      log('Error storing notification: $e');
    }
  }

  // Check if notification should be shown based on preferences
  bool _shouldShowNotification(String type, Map<String, bool> preferences) {
    switch (type) {
      case 'newMessage':
        return preferences['newMessage'] ?? true;
      case 'savedSearch':
        return preferences['savedSearch'] ?? true;
      case 'itemSold':
        return preferences['itemSold'] ?? true;
      case 'newFollower':
        return preferences['newFollower'] ?? true;
      default:
        return true;
    }
  }

  // Show local notification with enhanced styling
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final type = message.data['type'] ?? 'general';
      final channelId = _getChannelId(type);
      
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF014700),
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: _getNotificationStyle(message),
        actions: _getNotificationActions(type),
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Delloni',
        message.notification?.body ?? 'You have a new notification',
        details,
        payload: _createPayload(message),
      );

    } catch (e) {
      log('Error showing local notification: $e');
    }
  }

  // Get notification channel ID based on type
  String _getChannelId(String type) {
    switch (type) {
      case 'newMessage':
        return 'messages';
      case 'savedSearch':
        return 'saved_searches';
      default:
        return 'general';
    }
  }

  // Get channel name
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'messages':
        return 'Messages';
      case 'saved_searches':
        return 'Saved Searches';
      default:
        return 'General Notifications';
    }
  }

  // Get channel description
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'messages':
        return 'Notifications for new messages';
      case 'saved_searches':
        return 'Notifications for saved search matches';
      default:
        return 'General app notifications';
    }
  }

  // Get notification style based on message
  BigTextStyleInformation? _getNotificationStyle(RemoteMessage message) {
    final type = message.data['type'];
    
    if (type == 'newMessage') {
      return BigTextStyleInformation(
        message.notification?.body ?? '',
        htmlFormatContent: true,
        htmlFormatTitle: true,
      );
    }
    
    return null;
  }

  // Get notification actions
  List<AndroidNotificationAction>? _getNotificationActions(String type) {
    switch (type) {
      case 'newMessage':
        return [
          const AndroidNotificationAction(
            'reply',
            'Reply',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'mark_read',
            'Mark as Read',
          ),
        ];
      case 'savedSearch':
        return [
          const AndroidNotificationAction(
            'view_item',
            'View Item',
            showsUserInterface: true,
          ),
        ];
      default:
        return null;
    }
  }

  // Create notification payload
 String _createPayload(RemoteMessage message) {
    try {
      if (message.data.isNotEmpty) {
        // Create a simple key=value format that's easy to parse
        List<String> pairs = [];
        message.data.forEach((key, value) {
          pairs.add('$key=$value');
        });
        return pairs.join(',');
      }
      return message.messageId ?? '';
    } catch (e) {
      log('Error creating payload: $e');
      return message.messageId ?? '';
    }
  }
  // Handle notification tap from local notifications
 void _onNotificationTapped(NotificationResponse response) {
    log('Local notification tapped: ${response.payload}');
    
    // Parse payload to extract data
    Map<String, dynamic> data = {};
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // If payload is a simple string with key=value pairs
        if (response.payload!.contains('=')) {
          final pairs = response.payload!.split(',');
          for (String pair in pairs) {
            final keyValue = pair.split('=');
            if (keyValue.length == 2) {
              data[keyValue[0].trim()] = keyValue[1].trim();
            }
          }
        }
      } catch (e) {
        log('Error parsing payload: $e');
      }
    }
    
    _handleNotificationNavigation(data, response.actionId);
  }


  // Handle notification tap from FCM
  void _handleNotificationTap(RemoteMessage message, {bool isFromBackground = false}) {
    log('FCM notification tapped: ${message.data}');
    
    final context = navigatorKey.currentContext;
    if (context == null) {
      log('Navigation context not available, retrying...');
      // Retry after delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(message, isFromBackground: isFromBackground);
      });
      return;
    }

    _handleNotificationNavigation(message.data, null, isFromBackground: isFromBackground);
  }
  // Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data, String? actionId, {bool isFromBackground = false}) {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        log('Navigation context not available');
        return;
      }

      // Extract navigation parameters
      final String? chatId = data['chatId'];
      final String? itemId = data['itemId'];
      final String? productId = data['productId'];
      final String? savedSearchName = data['savedSearchName'];
      final String type = data['type'] ?? 'general';

      Widget? targetScreen;
      
      // Determine target screen based on data
      if (chatId != null) {
        targetScreen = ChatPage();
        log('Navigating to chat: $chatId');
      } else if (productId != null) {
        targetScreen = ProductDetailScreen(productId: productId);
        log('Navigating to product: $productId');
      } else if (itemId != null) {
        targetScreen = ProductDetailScreen(productId: itemId);
        log('Navigating to item: $itemId');
      } else if (savedSearchName != null) {
        targetScreen = const SavedSearchesPage();
        log('Navigating to saved searches');
      } else {
        targetScreen = const NotificationsPage();
        log('Navigating to notifications page');
      }

      // Navigate to target screen
      if (targetScreen != null) {
        if (isFromBackground) {
          // For background/foreground transitions, use regular push
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => targetScreen!),
          );
        } else {
          // For terminated state (handled in main.dart), this won't be called
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => targetScreen!),
          );
        }
      }
      
    } catch (e) {
      log('Error handling notification navigation: $e');
      // Fallback navigation
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const NotificationsPage()),
        );
      }
    }
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

  // DIRECT PUSH NOTIFICATION METHODS

  // Send push notification directly using Firebase Admin API
  Future<bool> _sendPushNotificationDirect({
    required String fcmToken,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        log('Failed to get access token');
        return false;
      }

      if (_serviceAccountCredentials == null) {
        log('Service account credentials not available');
        return false;
      }

      final projectId = _serviceAccountCredentials!['project_id'];
      final url = 'https://fcm.googleapis.com/v1/projects/delloni/messages:send';

      final message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
            if (imageUrl != null) 'image': imageUrl,
          },
          'data': {
            'type': type,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            ...?data?.map((key, value) => MapEntry(key, value.toString())),
          },
          'android': {
            'notification': {
              'channel_id': _getChannelId(type),
              'sound': type == 'newMessage' ? 'message_sound' : 'default',
              // 'priority': 'high',
              'notification_priority': 'PRIORITY_HIGH',
            },
            'priority': 'high',
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
                'alert': {
                  'title': title,
                  'body': body,
                },
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        log('Push notification sent successfully');
        return true;
      } else {
        log('Failed to send push notification: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      log('Error sending push notification: $e');
      return false;
    }
  }

  // Send saved search notification
  Future<bool> sendSavedSearchNotification({
    required String userId,
    required String itemTitle,
    required String itemId,
    required String savedSearchName,
    required String location,
    String? price,
    String? imageUrl,
  }) async {
    try {
      // Check preferences
      final preferences = await getUserNotificationPreferences(userId);
      if (preferences['savedSearch'] != true) {
        log('User has disabled saved search notifications');
        return false;
      }

      final title = 'New Match for "$savedSearchName"';
      final body = '$itemTitle${price != null ? ' • \$$price' : ''} • $location';

      // Create notification document
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': 'savedSearch',
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

      // Send push notification directly
      return await _sendPushNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        type: 'savedSearch',
        data: {
          'itemId': itemId,
          'itemTitle': itemTitle,
          'savedSearchName': savedSearchName,
          'location': location,
          'price': price,
          'imageUrl': imageUrl,
        },
        imageUrl: imageUrl,
      );
    } catch (e) {
      log('Error sending saved search notification: $e');
      return false;
    }
  }

  // Send message notification
  Future<bool> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String messagePreview,
    required String chatId,
    String? senderAvatar,
  }) async {
    try {
      // Check preferences
      final preferences = await getUserNotificationPreferences(recipientId);
      if (preferences['newMessage'] != true) {
        log('User has disabled message notifications');
        return false;
      }

      final title = 'New Message';
      final body = '$senderName: $messagePreview';

      // Create notification document
      await _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': 'newMessage',
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

      // Send push notification directly
      return await _sendPushNotificationToUser(
        userId: recipientId,
        title: title,
        body: body,
        type: 'newMessage',
        data: {
          'chatId': chatId,
          'senderName': senderName,
          'senderAvatar': senderAvatar,
          'messagePreview': messagePreview,
        },
        imageUrl: senderAvatar,
      );
    } catch (e) {
      log('Error sending message notification: $e');
      return false;
    }
  }

  // Generic method to send a notification to a user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      // Store notification in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send push notification directly
      await _sendPushNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
        imageUrl: imageUrl,
      );

      log('Notification sent to user: $userId');
    } catch (e) {
      log('Error sending notification to user: $e');
    }
  }

  // Send push notification to a specific user
  Future<bool> _sendPushNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        log('No FCM token found for user: $userId');
        return false;
      }

      // Send push notification directly
      return await _sendPushNotificationDirect(
        fcmToken: fcmToken,
        title: title,
        body: body,
        type: type,
        data: data,
        imageUrl: imageUrl,
      );
    } catch (e) {
      log('Error sending push notification to user: $e');
      return false;
    }
  }

  // Send notification to multiple users
  Future<void> sendNotificationToMultipleUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      for (String userId in userIds) {
        await sendNotificationToUser(
          userId: userId,
          title: title,
          body: body,
          type: type,
          data: data,
          imageUrl: imageUrl,
        );
        
        // Add small delay to prevent rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      log('Notifications sent to ${userIds.length} users');
    } catch (e) {
      log('Error sending notifications to multiple users: $e');
    }
  }

  // Get user notifications stream
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
          .update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
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

      log('Updated notification preference: $preference = $value');
      return true;
    } catch (e) {
      log('Error updating notification preference: $e');
      return false;
    }
  }

  // Cleanup old notifications
  Future<void> cleanupOldNotifications(String userId) async {
    try {
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

  // Dispose resources
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
  }
}