// models/category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? image;
  final int level;
  final String? parentId;
  final int order;
  final int priority;
  final bool isActive;
  final DateTime? createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.image,
    required this.level,
    this.parentId,
    required this.order,
    required this.priority,
    required this.isActive,
    this.createdAt,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel.fromMap(data, doc.id);
  }

  factory CategoryModel.fromMap(Map<String, dynamic> data, String id) {
    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'],
      icon: data['icon'],
      image: data['image'],
      level: data['level'] ?? 0,
      parentId: data['parentId'],
      order: data['order'] ?? 0,
      priority: data['priority'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'image': image,
      'level': level,
      'parentId': parentId,
      'order': order,
      'priority': priority,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
// models/product_model.dart
class ProductModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerType; // 'individual' or 'company'
  final String title;
  final String description;
  final String category;
  final String? categoryName;
  final String condition; // 'New', 'Used', 'Refurbished'
  final double price;
  final bool allowPriceNegotiation;
  final String shippingOption; // 'Pickup', 'Delivery', 'Both'
  final List<String> imageUrls;
  final String? brand;
  final String? dimensions;
  final String? color;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final String status; // 'active', 'sold', 'inactive'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int viewCount;
  final int favoriteCount;
  final bool isFeatured;
  final bool isPromoted;
  final DateTime? promotedUntil;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerType,
    required this.title,
    required this.description,
    required this.category,
    this.categoryName,
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
    this.promotedUntil,

  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',

      sellerType: data['sellerType'] ?? 'individual',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      categoryName: data['categoryName'],
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
      promotedUntil: (data['promotedUntil'] as Timestamp?)?.toDate(),
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
      'categoryName': categoryName,
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
      'promotedUntil': promotedUntil != null ? Timestamp.fromDate(promotedUntil!) : null,
    };
  }

  ProductModel copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? sellerType,
    String? title,
    String? description,
    String? category,
    String? categoryName,
    String? condition,
    double? price,
    bool? allowPriceNegotiation,
    String? shippingOption,
    List<String>? imageUrls,
    String? brand,
    String? dimensions,
    String? color,
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    int? favoriteCount,
    bool? isFeatured,
    bool? isPromoted,
    DateTime? promotedUntil,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerType: sellerType ?? this.sellerType,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryName: categoryName ?? this.categoryName,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      allowPriceNegotiation: allowPriceNegotiation ?? this.allowPriceNegotiation,
      shippingOption: shippingOption ?? this.shippingOption,
      imageUrls: imageUrls ?? this.imageUrls,
      brand: brand ?? this.brand,
      dimensions: dimensions ?? this.dimensions,
      color: color ?? this.color,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isPromoted: isPromoted ?? this.isPromoted,
      promotedUntil: promotedUntil ?? this.promotedUntil,
    );
  }

  // Helper method to get time since posted
  String getTimeSincePosted() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to format price
  String getFormattedPrice() {
    if (price >= 100000) {
      return 'Rs ${(price / 100000).toStringAsFixed(1)}L';
    } else if (price >= 1000) {
      return 'Rs ${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return 'Rs ${price.toStringAsFixed(0)}';
    }
  }
}

// models/ad_banner_model.dart
class AdBannerModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? actionUrl;
  final String actionType; // 'product', 'category', 'external'
  final bool isActive;
  final int priority;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  AdBannerModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.actionUrl,
    required this.actionType,
    required this.isActive,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  factory AdBannerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AdBannerModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      actionUrl: data['actionUrl'],
      actionType: data['actionType'] ?? 'external',
      isActive: data['isActive'] ?? true,
      priority: data['priority'] ?? 0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(Duration(days: 30)),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionType': actionType,
      'isActive': isActive,
      'priority': priority,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }
}