import 'dart:async';
import 'dart:developer';
import 'package:arabicmarketplace/controller/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  // Notification preferences
  Map<String, bool> _preferences = {};
  bool _isLoading = false;
  String? _error;
  
  // Notifications data
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  StreamSubscription? _notificationsSubscription;

  // Getters
  Map<String, bool> get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  // Category preferences getters
  bool get mobileNotifications => _preferences['mobile'] ?? true;
  bool get carsNotifications => _preferences['cars'] ?? true;
  bool get electronicsNotifications => _preferences['electronics'] ?? true;
  bool get furnitureNotifications => _preferences['furniture'] ?? true;
  bool get clothingNotifications => _preferences['clothing'] ?? true;
  bool get booksNotifications => _preferences['books'] ?? true;
  bool get sportsNotifications => _preferences['sports'] ?? true;
  bool get beautyNotifications => _preferences['beauty'] ?? true;
  bool get homeNotifications => _preferences['home'] ?? true;
  bool get toysNotifications => _preferences['toys'] ?? true;
  
  // Activity preferences getters
  bool get newFollowerNotifications => _preferences['newFollower'] ?? true;
  bool get itemSoldNotifications => _preferences['itemSold'] ?? true;
  bool get priceReductionNotifications => _preferences['priceReduction'] ?? true;
  bool get newMessageNotifications => _preferences['newMessage'] ?? true;
  bool get itemExpiringNotifications => _preferences['itemExpiring'] ?? true;

  NotificationProvider() {
    _initialize();
  }

  void _initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      loadNotificationPreferences();
      _subscribeToNotifications(user.uid);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Load notification preferences
  Future<void> loadNotificationPreferences() async {
    try {
      _setLoading(true);
      _setError(null);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        return;
      }

      _preferences = await _notificationService.getUserNotificationPreferences(user.uid);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load preferences: $e');
      _setLoading(false);
    }
  }

  // Update notification preference
  Future<bool> updateNotificationPreference(String preference, bool value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        return false;
      }

      // Update locally first for immediate UI feedback
      _preferences[preference] = value;
      notifyListeners();

      // Update in backend
      bool success = await _notificationService.updateNotificationPreference(
        user.uid,
        preference,
        value,
      );

      if (!success) {
        // Revert local change if backend update failed
        _preferences[preference] = !value;
        notifyListeners();
        _setError('Failed to update preference');
        return false;
      }

      _setError(null);
      return true;
    } catch (e) {
      // Revert local change on error
      _preferences[preference] = !value;
      notifyListeners();
      _setError('Error updating preference: $e');
      return false;
    }
  }

  // Subscribe to user notifications
  void _subscribeToNotifications(String userId) {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _notificationService
        .getUserNotifications(userId)
        .listen(
      (QuerySnapshot snapshot) {
        _notifications = snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      },
      onError: (error) {
        _setError('Error loading notifications: $error');
      },
    );
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _notificationService.markNotificationAsRead(user.uid, notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      _setError('Error marking notification as read: $e');
    }
  }

  // Send test notification (for debugging)
  Future<void> sendTestNotification(String type) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _notificationService.sendNotificationToUser(
        userId: user.uid,
        title: 'Test Notification',
        body: 'This is a test notification for $type',
        type: type,
        data: {'test': true},
      );
    } catch (e) {
      _setError('Error sending test notification: $e');
    }
  }

  // Cleanup old notifications
  Future<void> cleanupOldNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _notificationService.cleanupOldNotifications(user.uid);
    } catch (e) {
      log('Error cleaning up notifications: $e');
    }
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}

// Notification model
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}