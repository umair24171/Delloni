// models/product_detail_model.dart
import 'package:arabicmarketplace/screens/home/controller/home_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../main.dart';
class ProductDetailModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerType;
  final String title;
  final String description;
  final String category;
  final String? categoryName;
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
  final String? cityId;
  final String? districtId;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int viewCount;
  final int favoriteCount;
  final bool isFeatured;
  final bool isPromoted;
  
  // Enhanced category-based fields
  final Map<String, dynamic> categorySpecificFields;
  final List<CategoryFieldDisplay> categoryFieldsDisplay;
  final Map<String, dynamic> specifications;
  final List<String> features;
  final ProductStats stats;
  final bool hasCategoryFields;

  ProductDetailModel({
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
    this.cityId,
    this.districtId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.isFeatured = false,
    this.isPromoted = false,
    required this.categorySpecificFields,
    required this.categoryFieldsDisplay,
    required this.specifications,
    required this.features,
    required this.stats,
    this.hasCategoryFields = false,
  });

  factory ProductDetailModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    print('=== ProductDetailModel.fromFirestore DEBUG ===');
    print('Document ID: ${doc.id}');
    print('categorySpecificFields: ${data['categorySpecificFields']}');
    print('categoryFieldTemplate: ${data['categoryFieldTemplate']}');
    print('hasCategoryFields: ${data['hasCategoryFields']}');
    
    // Extract category-specific fields
    final categorySpecificFields = <String, dynamic>{};
    final categoryFieldsDisplay = <CategoryFieldDisplay>[];
    
    // Parse categoryFieldTemplate for metadata
    final fieldTemplateMap = <String, Map<String, dynamic>>{};
    if (data['categoryFieldTemplate'] != null) {
      final template = data['categoryFieldTemplate'];
      print('Found categoryFieldTemplate: $template');
      
      if (template is List) {
        for (final fieldConfig in template) {
          if (fieldConfig is Map) {
            final fieldName = fieldConfig['fieldName'] ?? fieldConfig['name'];
            if (fieldName != null) {
              fieldTemplateMap[fieldName] = Map<String, dynamic>.from(fieldConfig);
              print('Added template for field $fieldName: $fieldConfig');
            }
          }
        }
      }
    }
    
    if (data['categorySpecificFields'] != null) {
      final categoryFields = data['categorySpecificFields'];
      print('Found categorySpecificFields: $categoryFields');
      
      if (categoryFields is Map) {
        categoryFields.forEach((key, value) {
          if (key is String && value != null) {
            categorySpecificFields[key] = value;
            
            // Get metadata from template
            final template = fieldTemplateMap[key];
            final label = template?['label'] ?? _formatFieldName(key);
            final fieldType = template?['type'] ?? _inferFieldType(value);
            final hasIcon = template?['showFieldIcon'] == true;
            final iconUrl = template?['fieldIconUrl'];
            
            // Create display object for UI rendering
            categoryFieldsDisplay.add(CategoryFieldDisplay(
              fieldName: key,
              value: value,
              displayLabel: label,
              fieldType: fieldType,
              hasIcon: hasIcon,
              iconUrl: iconUrl,
            ));
            
            print('Added category field: $key = $value (hasIcon: $hasIcon)');
          }
        });
      }
    }
    
    // Build specifications from multiple sources for backward compatibility
    Map<String, dynamic> specifications = Map<String, dynamic>.from(categorySpecificFields);
    
    // Add the template data to specifications so it's accessible in UI
    if (fieldTemplateMap.isNotEmpty) {
      specifications['categoryFieldTemplate'] = data['categoryFieldTemplate'];
    }
    
    // Add legacy fields for backward compatibility
    if (data['flattenedFields'] != null) {
      final flattenedFields = data['flattenedFields'];
      if (flattenedFields is Map) {
        flattenedFields.forEach((key, value) {
          if (key is String && value != null) {
            if (key.startsWith('cf_')) {
              final fieldName = key.substring(3);
              if (!specifications.containsKey(fieldName)) {
                specifications[fieldName] = value;
              }
            } else {
              specifications[key] = value;
            }
          }
        });
      }
    }
    
    // Direct legacy fields
    final directFields = [
      'storage', 'ram', 'screen_size', 'battery_capacity', 'network_type', 'dual_sim',
      'year', 'kilometers', 'mileage', 'fuel_type', 'transmission', 'engine_capacity',
      'processor', 'storage_type', 'storage_capacity', 'graphics_card', 'operating_system',
      'property_type', 'area', 'bedrooms', 'bathrooms', 'furnished', 'parking'
    ];
    
    for (final field in directFields) {
      if (data[field] != null && !specifications.containsKey(field)) {
        specifications[field] = data[field];
      }
    }
    
    // Build features from category fields + legacy
    List<String> features = [];
    
    // Legacy features
    if (data['features'] is List) {
      features.addAll(List<String>.from(data['features']));
    }
    
    // Extract boolean features from categorySpecificFields
    categorySpecificFields.forEach((key, value) {
      if (value is bool && value == true) {
        final template = fieldTemplateMap[key];
        final featureName = template?['label'] ?? _formatFieldName(key);
        if (!features.contains(featureName)) {
          features.add(featureName);
        }
      }
    });
    
    // Build stats
    Map<String, dynamic> statsData = {};
    
    if (data['stats'] is Map) {
      statsData.addAll(Map<String, dynamic>.from(data['stats']));
    }
    
    // Extract stats from specifications
    final statFields = ['year', 'mileage', 'fuel_type', 'transmission', 'engine_capacity', 'body_type'];
    for (final field in statFields) {
      if (specifications.containsKey(field) && !statsData.containsKey(field)) {
        statsData[field] = specifications[field];
      }
    }
    
    // Handle field name mapping
    if (specifications.containsKey('kilometers') && !statsData.containsKey('mileage')) {
      statsData['mileage'] = specifications['kilometers'];
    }
    if (specifications.containsKey('fuel_type') && !statsData.containsKey('fuelType')) {
      statsData['fuelType'] = specifications['fuel_type'];
    }
    
    print('Final categorySpecificFields: $categorySpecificFields');
    print('Final categoryFieldsDisplay count: ${categoryFieldsDisplay.length}');
    print('Final specifications: $specifications');
    print('=== END DEBUG ===');
    
    return ProductDetailModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerType: data['sellerType'] ?? 'individual',
      title: data['itemTitle'] ?? data['title'] ?? '',
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
      cityId: data['cityId'],
      districtId: data['districtId'],
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      viewCount: data['viewCount'] ?? 0,
      favoriteCount: data['favoriteCount'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      isPromoted: data['isPromoted'] ?? false,
      categorySpecificFields: categorySpecificFields,
      categoryFieldsDisplay: categoryFieldsDisplay,
      specifications: specifications,
      features: features,
      stats: ProductStats.fromMap(statsData),
      hasCategoryFields: data['hasCategoryFields'] ?? categorySpecificFields.isNotEmpty,
    );
  }

  // Helper method to infer field type from value
  static String _inferFieldType(dynamic value) {
    if (value is bool) return 'boolean';
    if (value is num) return 'number';
    if (value is DateTime) return 'date';
    if (value is String) {
      // Try to detect color values
      if (value.toLowerCase().contains(RegExp(r'^(red|blue|green|yellow|black|white|gray|grey|purple|pink|orange|brown)$'))) {
        return 'color_picker';
      }
      // Try to detect date strings
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(value)) {
        return 'date';
      }
      return 'text';
    }
    return 'text';
  }

  // Helper method to format field names
  static String _formatFieldName(String fieldName) {
    return fieldName.split('_').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
    ).join(' ');
  }

  // Get all non-empty category fields for display
  List<CategoryFieldDisplay> getNonEmptyFields() {
    return categoryFieldsDisplay.where((field) {
      final value = field.value;
      if (value == null) return false;
      if (value is String && value.trim().isEmpty) return false;
      if (value is List && value.isEmpty) return false;
      return true;
    }).toList();
  }

  // Check if product has specific field
  bool hasField(String fieldName) {
    return categorySpecificFields.containsKey(fieldName);
  }

  // Get field value with type safety
  T? getFieldValue<T>(String fieldName) {
    final value = categorySpecificFields[fieldName];
    if (value is T) {
      return value;
    }
    return null;
  }

  // Get category path display
  String getCategoryPath() {
    return categoryName ?? 'Unknown Category';
  }

  String getFormattedPrice() {
    if (price >= 10000000) {
      return 'SYP ${(price / 10000000).toStringAsFixed(1)} Crore';
    } else if (price >= 100000) {
      return 'SYP ${(price / 100000).toStringAsFixed(1)} Lac';
    } else if (price >= 1000) {
      return 'SYP ${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return 'SYP ${price.toStringAsFixed(0)}';
    }
  }

  String getTimeSincePosted() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    final locale = EasyLocalization.of(navigatorKey.currentContext!)?.locale.languageCode ?? 'en';

    if (difference.inDays > 0) {
      final days = difference.inDays;
      return locale == 'ar'
          ? 'منذ $days ${days == 1 ? 'يوم' : 'أيام'}'
          : '$days day${days > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      return locale == 'ar'
          ? 'منذ $hours ${hours == 1 ? 'ساعة' : 'ساعات'}'
          : '$hours hour${hours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      return locale == 'ar'
          ? 'منذ $minutes ${minutes == 1 ? 'دقيقة' : 'دقائق'}'
          : '$minutes minute${minutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now'.tr();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerType': sellerType,
      'itemTitle': title,
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
      'cityId': cityId,
      'districtId': districtId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'viewCount': viewCount,
      'favoriteCount': favoriteCount,
      'isFeatured': isFeatured,
      'isPromoted': isPromoted,
      'categorySpecificFields': categorySpecificFields,
      'hasCategoryFields': hasCategoryFields,
      'specifications': specifications,
      'features': features,
      'stats': stats.toMap(),
    };
  }
}

// Enhanced class for category field display
class CategoryFieldDisplay {
  final String fieldName;
  final dynamic value;
  final String displayLabel;
  final String fieldType;
  final bool hasIcon;
  final String? iconUrl;
  final bool isRequired;
  final String? sourceCategory;
  final bool isInherited;

  CategoryFieldDisplay({
    required this.fieldName,
    required this.value,
    required this.displayLabel,
    required this.fieldType,
    this.hasIcon = false,
    this.iconUrl,
    this.isRequired = false,
    this.sourceCategory,
    this.isInherited = false,
  });

  // Get formatted display value
  String get formattedValue {
    switch (fieldType) {
      case 'boolean':
        return value == true ? 'Yes' : 'No';
      case 'date':
        if (value is DateTime) {
          return '${value.day}/${value.month}/${value.year}';
        } else if (value is String) {
          try {
            final date = DateTime.parse(value);
            return '${date.day}/${date.month}/${date.year}';
          } catch (e) {
            return value;
          }
        }
        return value?.toString() ?? 'Not specified';
      case 'number':
        if (value is num) {
          return value % 1 == 0 ? value.toInt().toString() : value.toString();
        }
        return value?.toString() ?? 'Not specified';
      case 'select':
      case 'dropdown':
        return value?.toString() ?? 'Not specified';
      case 'color_picker':
      case 'text':
      case 'textarea':
      default:
        return value?.toString() ?? 'Not specified';
    }
  }

  // Check if field has a meaningful value
  bool get hasValue {
    if (value == null) return false;
    if (value is String && value.trim().isEmpty) return false;
    if (value is List && value.isEmpty) return false;
    return true;
  }

  // Get inheritance info for display
  String? get inheritanceInfo {
    if (isInherited && sourceCategory != null) {
      return 'From: $sourceCategory';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldName': fieldName,
      'value': value,
      'displayLabel': displayLabel,
      'fieldType': fieldType,
      'hasIcon': hasIcon,
      'iconUrl': iconUrl,
      'isRequired': isRequired,
      'sourceCategory': sourceCategory,
      'isInherited': isInherited,
    };
  }
}

// Product Stats class
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
      year: map['year']?.toString(),
      mileage: map['mileage']?.toString() ?? map['kilometers']?.toString(),
      fuelType: map['fuelType']?.toString() ?? map['fuel_type']?.toString(),
      transmission: map['transmission']?.toString(),
      engineCapacity: map['engineCapacity']?.toString() ?? map['engine_capacity']?.toString(),
      bodyType: map['bodyType']?.toString() ?? map['body_type']?.toString(),
      assembly: map['assembly']?.toString(),
      registeredIn: map['registeredIn']?.toString() ?? map['registered_in']?.toString(),
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

  // Check if stats has any meaningful data
  bool get hasData {
    return [year, mileage, fuelType, transmission, engineCapacity, bodyType, assembly, registeredIn]
        .any((field) => field != null && field.isNotEmpty);
  }
}

// Keep existing SellerModel and UserFavoriteModel classes unchanged
class SellerModel {
  final String id;
  final String name;
  final String type;
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