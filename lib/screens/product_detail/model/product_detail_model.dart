// models/product_detail_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerType;
  final String title;
  final String description;
  final String category;
  final String condition;
  final double price;
  final bool allowPriceNegotiation;
  final String shippingOption;
  final List<String> imageUrls;
  final String? brand;
  final String? dimensions;
  final String? color;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int viewCount;
  final int favoriteCount;
  final bool isFeatured;
  final bool isPromoted;
  
  // Vehicle/Product specific details
  final Map<String, dynamic> specifications;
  final List<String> features;
  final ProductStats stats;

  ProductDetailModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerType,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.price,
    required this.allowPriceNegotiation,
    required this.shippingOption,
    required this.imageUrls,
    this.brand,
    this.dimensions,
    this.color,
    this.latitude,
    this.longitude,
    this.locationAddress,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.isFeatured = false,
    this.isPromoted = false,
    required this.specifications,
    required this.features,
    required this.stats,
  });

  factory ProductDetailModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductDetailModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerType: data['sellerType'] ?? 'individual',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      condition: data['condition'] ?? 'Used',
      price: (data['price'] ?? 0.0).toDouble(),
      allowPriceNegotiation: data['allowPriceNegotiation'] ?? true,
      shippingOption: data['shippingOption'] ?? 'Both',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      brand: data['brand'],
      dimensions: data['dimensions'],
      color: data['color'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      locationAddress: data['locationAddress'],
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      viewCount: data['viewCount'] ?? 0,
      favoriteCount: data['favoriteCount'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      isPromoted: data['isPromoted'] ?? false,
      specifications: Map<String, dynamic>.from(data['specifications'] ?? {}),
      features: List<String>.from(data['features'] ?? []),
      stats: ProductStats.fromMap(data['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerType': sellerType,
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'price': price,
      'allowPriceNegotiation': allowPriceNegotiation,
      'shippingOption': shippingOption,
      'imageUrls': imageUrls,
      'brand': brand,
      'dimensions': dimensions,
      'color': color,
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'viewCount': viewCount,
      'favoriteCount': favoriteCount,
      'isFeatured': isFeatured,
      'isPromoted': isPromoted,
      'specifications': specifications,
      'features': features,
      'stats': stats.toMap(),
    };
  }

  String getFormattedPrice() {
    if (price >= 10000000) {
      return 'PKR ${(price / 10000000).toStringAsFixed(1)} Crore';
    } else if (price >= 100000) {
      return 'PKR ${(price / 100000).toStringAsFixed(1)} Lac';
    } else if (price >= 1000) {
      return 'PKR ${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return 'PKR ${price.toStringAsFixed(0)}';
    }
  }

  String getTimeSincePosted() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class ProductStats {
  final String? year;
  final String? mileage;
  final String? fuelType;
  final String? transmission;
  final String? engineCapacity;
  final String? bodyType;
  final String? assembly;
  final String? registeredIn;

  ProductStats({
    this.year,
    this.mileage,
    this.fuelType,
    this.transmission,
    this.engineCapacity,
    this.bodyType,
    this.assembly,
    this.registeredIn,
  });

  factory ProductStats.fromMap(Map<String, dynamic> map) {
    return ProductStats(
      year: map['year'],
      mileage: map['mileage'],
      fuelType: map['fuelType'],
      transmission: map['transmission'],
      engineCapacity: map['engineCapacity'],
      bodyType: map['bodyType'],
      assembly: map['assembly'],
      registeredIn: map['registeredIn'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'mileage': mileage,
      'fuelType': fuelType,
      'transmission': transmission,
      'engineCapacity': engineCapacity,
      'bodyType': bodyType,
      'assembly': assembly,
      'registeredIn': registeredIn,
    };
  }
}

// models/seller_model.dart
class SellerModel {
  final String id;
  final String name;
  final String type; // 'individual' or 'company'
  final String email;
  final String phone;
  final String? profileImageUrl;
  final String? companyName;
  final String? address;
  final DateTime memberSince;
  final int totalAds;
  final int activeAds;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isOnline;
  final DateTime? lastSeen;
  final List<String> verificationDocuments;

  SellerModel({
    required this.id,
    required this.name,
    required this.type,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.companyName,
    this.address,
    required this.memberSince,
    this.totalAds = 0,
    this.activeAds = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
    this.verificationDocuments = const [],
  });

  factory SellerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SellerModel(
      id: doc.id,
      name: data['companyName'] ?? data['name'] ?? 'Unknown',
      type: data['type'] ?? 'individual',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profileImageUrl: data['profileImage'],
      companyName: data['companyName'],
      address: data['address'],
      memberSince: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAds: data['totalAds'] ?? 0,
      activeAds: data['activeAds'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      verificationDocuments: List<String>.from(data['verificationDocuments'] ?? []),
    );
  }

  String getDisplayName() {
    return companyName ?? name;
  }

  String getMemberSinceFormatted() {
    return '${memberSince.day}/${memberSince.month}/${memberSince.year}';
  }

  String getOnlineStatus() {
    if (isOnline) return 'Online now';
    if (lastSeen != null) {
      final difference = DateTime.now().difference(lastSeen!);
      if (difference.inMinutes < 60) {
        return 'Active ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Active ${difference.inHours}h ago';
      } else {
        return 'Active ${difference.inDays}d ago';
      }
    }
    return 'Last seen unknown';
  }
}


// models/user_favorite_model.dart
class UserFavoriteModel {
  final String id;
  final String userId;
  final String productId;
  final DateTime createdAt;

  UserFavoriteModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
  });

  factory UserFavoriteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserFavoriteModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'productId': productId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}