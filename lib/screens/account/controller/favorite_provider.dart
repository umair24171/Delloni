
// providers/favorites_provider.dart
import 'dart:async';
import 'dart:developer' show log;

import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  bool _isLoading = true;
  String? _error;
  List<ProductModel> _favoriteAds = [];
  List<String> _favoriteIds = [];

  // Streams
  StreamSubscription? _favoritesSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProductModel> get favoriteAds => _favoriteAds;
  List<String> get favoriteIds => _favoriteIds;

  FavoritesProvider() {
    _initializeFavorites();
  }

  Future<void> _initializeFavorites() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('User not authenticated');
      return;
    }

    try {
      _setLoading(true);
      _setupFavoritesListener(currentUser.uid);
    } catch (e) {
      _setError('Failed to initialize favorites: $e');
      log('FavoritesProvider initialization error: $e');
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

  // Setup real-time favorites listener
  void _setupFavoritesListener(String userId) {
    _favoritesSubscription = _firestore
        .collection('userFavorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      _favoriteIds = snapshot.docs
          .map((doc) => doc.data()['productId'] as String)
          .toList();

      await _loadFavoriteProducts();
    }, onError: (e) {
      _setError('Error loading favorites: $e');
      log('Favorites stream error: $e');
    });
  }

  // Load favorite products details
  Future<void> _loadFavoriteProducts() async {
    if (_favoriteIds.isEmpty) {
      _favoriteAds = [];
      _setLoading(false);
      return;
    }

    try {
      // Load products in batches (Firestore 'in' query limit is 10)
      List<ProductModel> allFavorites = [];
      
      for (int i = 0; i < _favoriteIds.length; i += 10) {
        final batch = _favoriteIds.skip(i).take(10).toList();
        
        final snapshot = await _firestore
            .collection('items')
            .where(FieldPath.documentId, whereIn: batch)
            .where('status', isEqualTo: 'active') // Only show active ads
            .get();

        final batchFavorites = snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();
        
        allFavorites.addAll(batchFavorites);
      }

      _favoriteAds = allFavorites;
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load favorite products: $e');
      log('Error loading favorite products: $e');
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String productId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      if (_favoriteIds.contains(productId)) {
        // Remove from favorites
        final favoriteQuery = await _firestore
            .collection('userFavorites')
            .where('userId', isEqualTo: currentUser.uid)
            .where('productId', isEqualTo: productId)
            .get();

        for (var doc in favoriteQuery.docs) {
          await doc.reference.delete();
        }

        // Decrement favorite count in product
        await _firestore.collection('items').doc(productId).update({
          'favoriteCount': FieldValue.increment(-1),
        });
      } else {
        // Add to favorites
        await _firestore.collection('userFavorites').add({
          'userId': currentUser.uid,
          'productId': productId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Increment favorite count in product
        await _firestore.collection('items').doc(productId).update({
          'favoriteCount': FieldValue.increment(1),
        });
      }
      return true;
    } catch (e) {
      _setError('Failed to toggle favorite: $e');
      log('Error toggling favorite: $e');
      return false;
    }
  }

  // Check if product is favorite
  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  // Remove favorite
  Future<bool> removeFavorite(String productId) async {
    if (!_favoriteIds.contains(productId)) return true;
    
    return await toggleFavorite(productId);
  }

  // Clear all favorites
  Future<bool> clearAllFavorites() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final favoriteQuery = await _firestore
          .collection('userFavorites')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in favoriteQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Update favorite counts in products
      for (String productId in _favoriteIds) {
        final productRef = _firestore.collection('items').doc(productId);
        batch.update(productRef, {'favoriteCount': FieldValue.increment(-1)});
      }

      await batch.commit();
      return true;
    } catch (e) {
      _setError('Failed to clear favorites: $e');
      log('Error clearing favorites: $e');
      return false;
    }
  }

  // Search favorites
  List<ProductModel> searchFavorites(String query) {
    if (query.isEmpty) return _favoriteAds;

    return _favoriteAds.where((ad) {
      final title = ad.title.toLowerCase();
      final description = ad.description.toLowerCase();
      final category = ad.category.toLowerCase();
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) ||
             description.contains(searchQuery) ||
             category.contains(searchQuery);
    }).toList();
  }

  // Get favorites by category
  List<ProductModel> getFavoritesByCategory(String category) {
    return _favoriteAds.where((ad) => ad.category == category).toList();
  }

  // Get favorite statistics
  Map<String, dynamic> getFavoriteStats() {
    final categories = <String, int>{};
    for (var ad in _favoriteAds) {
      categories[ad.category] = (categories[ad.category] ?? 0) + 1;
    }

    return {
      'total': _favoriteAds.length,
      'categories': categories,
      'totalValue': _favoriteAds.fold(0.0, (sum, ad) => sum + ad.price),
    };
  }

  // Refresh favorites
  Future<void> refreshFavorites() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _setupFavoritesListener(currentUser.uid);
    }
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}