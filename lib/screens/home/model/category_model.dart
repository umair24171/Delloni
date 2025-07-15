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
  
  // NEW: City/District support for enhanced location
  final String? cityId;
  final String? cityName;
  final String? districtId;
  final String? districtName;
  
  final String status; // 'active', 'sold', 'inactive'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int viewCount;
  final int favoriteCount;
  final bool isFeatured;
  final bool isPromoted;
  final DateTime? promotedUntil;
  
  // NEW: Category-specific fields for edit support
  final Map<String, dynamic>? categorySpecificFields;
  final List<Map<String, dynamic>>? categoryFieldTemplate;
  final String? categoryTemplateName;
  final bool? hasCustomFields;
  
  // NEW: Enhanced metadata
  final bool? isRealEstate;
  final int? photoCount;
  final bool? hasMultiplePhotos;
  final bool? isPremiumListing;

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
    // NEW: City/District fields
    this.cityId,
    this.cityName,
    this.districtId,
    this.districtName,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.isFeatured = false,
    this.isPromoted = false,
    this.promotedUntil,
    // NEW: Category-specific fields
    this.categorySpecificFields,
    this.categoryFieldTemplate,
    this.categoryTemplateName,
    this.hasCustomFields,
    // NEW: Enhanced metadata
    this.isRealEstate,
    this.photoCount,
    this.hasMultiplePhotos,
    this.isPremiumListing,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerType: data['sellerType'] ?? 'individual',
      
      // Support both 'title' and 'itemTitle' for backward compatibility
      title: data['title'] ?? data['itemTitle'] ?? '',
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
      
      // NEW: City/District fields
      cityId: data['cityId'],
      cityName: data['cityName'],
      districtId: data['districtId'],
      districtName: data['districtName'],
      
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      viewCount: data['viewCount'] ?? data['views'] ?? 0, // Support both field names
      favoriteCount: data['favoriteCount'] ?? data['likes'] ?? 0, // Support both field names
      isFeatured: data['isFeatured'] ?? false,
      isPromoted: data['isPromoted'] ?? false,
      promotedUntil: (data['promotedUntil'] as Timestamp?)?.toDate(),
      
      // NEW: Category-specific fields
      categorySpecificFields: data['categorySpecificFields'] != null 
          ? Map<String, dynamic>.from(data['categorySpecificFields'])
          : null,
      categoryFieldTemplate: data['categoryFieldTemplate'] != null
          ? List<Map<String, dynamic>>.from(data['categoryFieldTemplate'])
          : null,
      categoryTemplateName: data['categoryTemplateName'],
      hasCustomFields: data['hasCustomFields'],
      
      // NEW: Enhanced metadata
      isRealEstate: data['isRealEstate'],
      photoCount: data['photoCount'],
      hasMultiplePhotos: data['hasMultiplePhotos'],
      isPremiumListing: data['isPremiumListing'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerType': sellerType,
      'title': title,
      'itemTitle': title, // Store both for compatibility
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
      
      // NEW: City/District fields
      'cityId': cityId,
      'cityName': cityName,
      'districtId': districtId,
      'districtName': districtName,
      
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'viewCount': viewCount,
      'views': viewCount, // Store both for compatibility
      'favoriteCount': favoriteCount,
      'likes': favoriteCount, // Store both for compatibility
      'isFeatured': isFeatured,
      'isPromoted': isPromoted,
      'promotedUntil': promotedUntil != null ? Timestamp.fromDate(promotedUntil!) : null,
      
      // NEW: Category-specific fields
      'categorySpecificFields': categorySpecificFields,
      'categoryFieldTemplate': categoryFieldTemplate,
      'categoryTemplateName': categoryTemplateName,
      'hasCustomFields': hasCustomFields,
      
      // NEW: Enhanced metadata
      'isRealEstate': isRealEstate,
      'photoCount': photoCount,
      'hasMultiplePhotos': hasMultiplePhotos,
      'isPremiumListing': isPremiumListing,
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
    // NEW: City/District parameters
    String? cityId,
    String? cityName,
    String? districtId,
    String? districtName,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    int? favoriteCount,
    bool? isFeatured,
    bool? isPromoted,
    DateTime? promotedUntil,
    // NEW: Category-specific parameters
    Map<String, dynamic>? categorySpecificFields,
    List<Map<String, dynamic>>? categoryFieldTemplate,
    String? categoryTemplateName,
    bool? hasCustomFields,
    // NEW: Enhanced metadata parameters
    bool? isRealEstate,
    int? photoCount,
    bool? hasMultiplePhotos,
    bool? isPremiumListing,
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
      // NEW: City/District fields
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isPromoted: isPromoted ?? this.isPromoted,
      promotedUntil: promotedUntil ?? this.promotedUntil,
      // NEW: Category-specific fields
      categorySpecificFields: categorySpecificFields ?? this.categorySpecificFields,
      categoryFieldTemplate: categoryFieldTemplate ?? this.categoryFieldTemplate,
      categoryTemplateName: categoryTemplateName ?? this.categoryTemplateName,
      hasCustomFields: hasCustomFields ?? this.hasCustomFields,
      // NEW: Enhanced metadata
      isRealEstate: isRealEstate ?? this.isRealEstate,
      photoCount: photoCount ?? this.photoCount,
      hasMultiplePhotos: hasMultiplePhotos ?? this.hasMultiplePhotos,
      isPremiumListing: isPremiumListing ?? this.isPremiumListing,
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

  // NEW: Helper method to get full location string
  String getFullLocationString() {
    List<String> locationParts = [];
    
    if (districtName != null && districtName!.isNotEmpty) {
      locationParts.add(districtName!);
    }
    if (cityName != null && cityName!.isNotEmpty) {
      locationParts.add(cityName!);
    }
    if (locationParts.isEmpty && locationAddress != null && locationAddress!.isNotEmpty) {
      locationParts.add(locationAddress!);
    }
    
    return locationParts.join(', ');
  }

  // NEW: Helper method to check if item has category-specific data
  bool get hasCategorySpecificData {
    return categorySpecificFields != null && 
           categorySpecificFields!.isNotEmpty;
  }

  // NEW: Helper method to get category-specific field value
  dynamic getCategoryField(String fieldName) {
    return categorySpecificFields?[fieldName];
  }

  // NEW: Helper method to check if this is a premium listing
  bool get isPremium {
    return isPremiumListing == true || 
           isFeatured || 
           isPromoted ||
           (hasMultiplePhotos == true && (photoCount ?? 0) >= 10);
  }

  // NEW: Helper method to get display category name
  String get displayCategoryName {
    return categoryName ?? category;
  }

  // NEW: Helper method to check if location is complete
  bool get hasCompleteLocation {
    return latitude != null && 
           longitude != null && 
           (cityName != null || locationAddress != null);
  }

  // NEW: Helper method to validate required fields for editing
  bool get isValidForEdit {
    return title.isNotEmpty &&
           description.isNotEmpty &&
           category.isNotEmpty &&
           condition.isNotEmpty &&
           price > 0 &&
           imageUrls.isNotEmpty;
  }

  // NEW: Helper method to get short description
  String getShortDescription({int maxLength = 100}) {
    if (description.length <= maxLength) {
      return description;
    }
    return '${description.substring(0, maxLength)}...';
  }

  // NEW: Helper method to check if item is recently posted
  bool get isRecentlyPosted {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays <= 7; // Consider items posted within 7 days as recent
  }

  // NEW: Helper method to get status display text
  String getStatusDisplayText() {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'sold':
        return 'Sold';
      case 'inactive':
        return 'Inactive';
      default:
        return status;
    }
  }

  // NEW: Helper method to check if item can be edited
  bool get canBeEdited {
    return status.toLowerCase() != 'sold';
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