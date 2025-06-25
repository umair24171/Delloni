import 'dart:async';
import 'dart:developer';
import 'package:arabicmarketplace/screens/auth/model/auth_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  StreamSubscription? _authSubscription;
  StreamSubscription? _userSubscription;
  StreamSubscription? _locationSubscription;
  bool _isLoading = false;
  String? _error;

  UserProvider() {
    _init();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? firebaseUser) async {
        if (firebaseUser == null) {
          _clearUser();
        } else {
          await _fetchUserData(firebaseUser.uid);
        }
      },
      onError: (error) {
        _setError('Authentication error: $error');
      },
    );
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Cancel existing subscriptions
      await _cancelSubscriptions();

      // Listen to user document
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen(
        (userDoc) async {
          if (userDoc.exists) {
            try {
              // Fetch location data
              DocumentSnapshot locationDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('location')
                  .doc('current')
                  .get();

              Map<String, dynamic>? locationData = 
                  locationDoc.exists ? locationDoc.data() as Map<String, dynamic> : null;

              _currentUser = UserModel.fromFirestore(
                userDoc.data() as Map<String, dynamic>,
                locationData,
              );
              
              _setLoading(false);
              notifyListeners();
              log('User data updated: ${_currentUser?.email}');
            } catch (e) {
              _setError('Error processing user data: $e');
              _setLoading(false);
            }
          } else {
            _setError('User document not found');
            _clearUser();
          }
        },
        onError: (error) {
          _setError('User data stream error: $error');
          _setLoading(false);
        },
      );

      // Listen to location document for real-time updates
      _locationSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('location')
          .doc('current')
          .snapshots()
          .listen(
        (locationDoc) {
          if (_currentUser != null && locationDoc.exists) {
            try {
              final data = locationDoc.data() as Map<String, dynamic>;
              _currentUser = _currentUser!.copyWith(
                latitude: data['latitude']?.toDouble(),
                longitude: data['longitude']?.toDouble(),
                locationAddress: data['address'],
              );
              notifyListeners();
            } catch (e) {
              log('Error updating location: $e');
            }
          }
        },
        onError: (error) {
          log('Location stream error: $error');
        },
      );
    } catch (e) {
      _setError('Failed to fetch user data: $e');
      _setLoading(false);
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _userSubscription?.cancel();
    await _locationSubscription?.cancel();
    _userSubscription = null;
    _locationSubscription = null;
  }

  void _clearUser() {
    _currentUser = null;
    _isLoading = false;
    _error = null;
    _cancelSubscriptions();
    notifyListeners();
  }

  // Update user location
  Future<bool> updateUserLocation(double latitude, double longitude, String address) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('location')
          .doc('current')
          .set({
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      _setError('Failed to update location: $e');
      return false;
    }
  }

  // Manual refresh with error handling
  Future<void> refreshUser() async {
    try {
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.getIdToken(true);
        await _fetchUserData(firebaseUser.uid);
      }
    } catch (e) {
      _setError('Failed to refresh user: $e');
    }
  }
   // Public method to clear user data (for logout/delete account)
  void clearUser() {
    _clearUser();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelSubscriptions();
    super.dispose();
  }
}