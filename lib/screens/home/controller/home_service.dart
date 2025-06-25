// services/home_service.dart
import 'dart:developer';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize default categories in Firestore (call this once during app setup)
  Future<void> initializeDefaultCategories() async {
    try {
      final categories = [
        {
          'name': 'Mobiles',
          'iconName': 'phone_android',
          'colorHex': '#2196F3',
          'priority': 5,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Property for Sale',
          'iconName': 'home',
          'colorHex': '#E91E63',
          'priority': 4,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Computer Accessories',
          'iconName': 'computer',
          'colorHex': '#FF9800',
          'priority': 3,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Home Appliances',
          'iconName': 'kitchen',
          'colorHex': '#607D8B',
          'priority': 2,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Computer & Laptop',
          'iconName': 'laptop',
          'colorHex': '#000000',
          'priority': 1,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      final batch = _firestore.batch();
      for (var category in categories) {
        final docRef = _firestore.collection('categories').doc();
        batch.set(docRef, category);
      }
      await batch.commit();
      
      log('Default categories initialized successfully');
    } catch (e) {
      log('Error initializing categories: $e');
      throw e;
    }
  }

  // Initialize sample ad banners
  Future<void> initializeDefaultAdBanners() async {
    try {
      final banners = [
        {
          'title': 'Summer Sale',
          'description': 'Get up to 50% off on electronics',
          'imageUrl': 'https://via.placeholder.com/800x200/FF6B6B/FFFFFF?text=Summer+Sale',
          'actionType': 'category',
          'actionUrl': 'Electronics',
          'isActive': true,
          'priority': 1,
          'startDate': Timestamp.now(),
          'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'New Arrivals',
          'description': 'Check out the latest products',
          'imageUrl': 'https://via.placeholder.com/800x200/4ECDC4/FFFFFF?text=New+Arrivals',
          'actionType': 'external',
          'actionUrl': 'https://example.com',
          'isActive': true,
          'priority': 2,
          'startDate': Timestamp.now(),
          'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 45))),
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      final batch = _firestore.batch();
      for (var banner in banners) {
        final docRef = _firestore.collection('adBanners').doc();
        batch.set(docRef, banner);
      }
      await batch.commit();
      
      log('Default ad banners initialized successfully');
    } catch (e) {
      log('Error initializing ad banners: $e');
      throw e;
    }
  }

  // Get trending products (high view count, recent)
  Future<List<ProductModel>> getTrendingProducts({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .where('viewCount', isGreaterThan: 5)
          .orderBy('viewCount', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting trending products: $e');
      return [];
    }
  }

  // Get products by price range
  Future<List<ProductModel>> getProductsByPriceRange({
    required double minPrice,
    required double maxPrice,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .where('price', isGreaterThanOrEqualTo: minPrice)
          .where('price', isLessThanOrEqualTo: maxPrice)
          .orderBy('price')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting products by price range: $e');
      return [];
    }
  }

  // Get nearby products based on location
  Future<List<ProductModel>> getNearbyProducts({
    required double latitude,
    required double longitude,
    double radiusInKm = 50.0,
    int limit = 20,
  }) async {
    try {
      // Note: This is a simplified approach. For better geo-queries,
      // consider using GeoFlutterFire or similar packages
      final snapshot = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .where('latitude', isNotEqualTo: null)
          .where('longitude', isNotEqualTo: null)
          .limit(limit * 2) // Get more to filter locally
          .get();

      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((product) {
            if (product.latitude == null || product.longitude == null) {
              return false;
            }
            
            // Simple distance calculation (not perfect for earth's curvature)
            final latDiff = (product.latitude! - latitude).abs();
            final lonDiff = (product.longitude! - longitude).abs();
            final distance = (latDiff * latDiff + lonDiff * lonDiff);
            
            // Rough approximation: 1 degree ≈ 111km
            final maxDistance = (radiusInKm / 111.0);
            return distance <= (maxDistance * maxDistance);
          })
          .take(limit)
          .toList();

      return products;
    } catch (e) {
      log('Error getting nearby products: $e');
      return [];
    }
  }

  // Get recently added products
  Future<List<ProductModel>> getRecentProducts({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting recent products: $e');
      return [];
    }
  }

  // Update product statistics
  Future<void> updateProductStats(String productId, {
    bool incrementView = false,
    bool incrementFavorite = false,
    bool decrementFavorite = false,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (incrementView) {
        updates['viewCount'] = FieldValue.increment(1);
      }
      
      if (incrementFavorite) {
        updates['favoriteCount'] = FieldValue.increment(1);
      }
      
      if (decrementFavorite) {
        updates['favoriteCount'] = FieldValue.increment(-1);
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('items').doc(productId).update(updates);
      }
    } catch (e) {
      log('Error updating product stats: $e');
      throw e;
    }
  }

  // Search products (basic text search)
  Future<List<ProductModel>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? condition,
    int limit = 20,
  }) async {
    try {
      Query queryRef = _firestore
          .collection('items')
          .where('status', isEqualTo: 'active');

      // Add category filter
      if (category != null && category.isNotEmpty) {
        queryRef = queryRef.where('category', isEqualTo: category);
      }

      // Add condition filter
      if (condition != null && condition.isNotEmpty) {
        queryRef = queryRef.where('condition', isEqualTo: condition);
      }

      // Add price filters
      if (minPrice != null) {
        queryRef = queryRef.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        queryRef = queryRef.where('price', isLessThanOrEqualTo: maxPrice);
      }

      final snapshot = await queryRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();

      // Filter by search query (client-side text search)
      if (query.isNotEmpty) {
        final searchTerms = query.toLowerCase().split(' ');
        return products.where((product) {
          final searchText = '${product.title} ${product.description} ${product.brand ?? ''}'
              .toLowerCase();
          return searchTerms.every((term) => searchText.contains(term));
        }).toList();
      }

      return products;
    } catch (e) {
      log('Error searching products: $e');
      return [];
    }
  }

  // Get featured/promoted products
  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting featured products: $e');
      return [];
    }
  }

  // Get products by seller
  Future<List<ProductModel>> getProductsBySeller({
    required String sellerId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('sellerId', isEqualTo: sellerId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting products by seller: $e');
      return [];
    }
  }

  // Analytics method - get popular categories
  Future<Map<String, int>> getPopularCategories() async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .get();

      final categoryCount = <String, int>{};
      for (var doc in snapshot.docs) {
        final product = ProductModel.fromFirestore(doc);
        categoryCount[product.category] = (categoryCount[product.category] ?? 0) + 1;
      }

      // Sort by count and return top categories
      final sortedEntries = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedEntries);
    } catch (e) {
      log('Error getting popular categories: $e');
      return {};
    }
  }
}