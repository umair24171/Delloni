import 'dart:developer';

import 'package:arabicmarketplace/controller/review_provider.dart';
import 'package:arabicmarketplace/controller/review_service.dart';
import 'package:arabicmarketplace/main.dart';
import 'package:arabicmarketplace/screens/account/view/account_profile_page.dart';
import 'package:arabicmarketplace/screens/product_detail/controller/product_detail_provider.dart';
import 'package:arabicmarketplace/screens/product_detail/model/product_detail_model.dart';
import 'package:arabicmarketplace/screens/reviews_page/model/review_model.dart';
import 'package:arabicmarketplace/screens/reviews_page/view/reviews_page.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:arabicmarketplace/widgets/image_optimise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailScreen extends StatefulWidget {
  final String? productId;
  final ProductDetailModel? product; // For when passed from home

  const ProductDetailScreen({
    Key? key,
    this.productId,
    this.product,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductDetailProvider _provider;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _provider = ProductDetailProvider();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.productId != null) {
        _provider.initializeProduct(widget.productId!);
      } else if (widget.product != null) {
        _provider.initializeProduct(widget.product!.id);
      }
    });
  }

  Future<void> _handleCallButtonPress(ProductDetailProvider provider) async {
  // Show loading indicator
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 12),
          Text('Opening dialer...'),
        ],
      ),
      backgroundColor: Color(0xFF2D5016),
      duration: Duration(seconds: 1),
    ),
  );



  // Call the provider method and get status
  Map<String, dynamic> result = await provider.callSellerWithStatus();
  
  // Hide the loading snackbar
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  
  // Show result feedback
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            result['success'] 
              ? (result['hasNumber'] ? Icons.phone : Icons.info_outline)
              : Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(child: Text(result['message'])),
        ],
      ),
      backgroundColor: result['success'] 
        ? (result['hasNumber'] ? Colors.green : Colors.orange)
        : Colors.red,
      duration: Duration(seconds: 3),
      action: !result['hasNumber'] && result['success'] ? SnackBarAction(
        label: 'Chat Instead',
        textColor: Colors.white,
        onPressed: () => provider.chatWithSeller(context),
      ) : null,
    ),
  );
}

Future<void> _shareProduct(ProductDetailProvider provider) async {
  final product = provider.product;
  if (product == null) return;

  try {
    // Create share content
    String shareText = '''
🏷️ ${product.title}

💰 ${product.getFormattedPrice()}${product.allowPriceNegotiation ? ' (Negotiable)' : ''}

📍 ${product.locationAddress ?? 'Location not specified'}

🏷️ Condition: ${product.condition}

${product.description.isNotEmpty ? '📝 ${product.description}\n' : ''}
⏰ Posted: ${product.getTimeSincePosted()}

Check out this amazing product on our marketplace!

#Marketplace #${product.category} #ForSale
''';

    // Share with result handling
    final result = await Share.share(
      shareText,
      subject: '${product.title} - ${product.getFormattedPrice()}',
    );

    // Show feedback based on result
    if (result.status == ShareResultStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Product shared successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    // Show error if sharing fails
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Failed to share product'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
    print('Error sharing product: $e');
  }
}


  @override
  void dispose() {
    _provider.dispose();
    _pageController.dispose();
    super.dispose();
  }
  // ENHANCED: Category-specific Stats Section (Top row with icons)
  Widget _buildCategoryStatsSection(ProductDetailModel product) {
    // Get category-specific fields from the product
    final categoryFields = _getCategorySpecificFields(product);
    if (categoryFields.isEmpty) return SizedBox.shrink();

    // Get the most important fields for stats display
    List<Widget> statItems = [];
    
    // Priority fields for stats display
    final priorityFields = {
      'year': {'icon': Icons.calendar_today, 'suffix': ''},
      'kilometers': {'icon': Icons.speed, 'suffix': ' km'},
      'mileage': {'icon': Icons.speed, 'suffix': ' km'},
      'fuel_type': {'icon': Icons.local_gas_station, 'suffix': ''},
      'transmission': {'icon': Icons.settings, 'suffix': ''},
      'storage': {'icon': Icons.storage, 'suffix': ''},
      'ram': {'icon': Icons.memory, 'suffix': ''},
      'area': {'icon': Icons.square_foot, 'suffix': ' sq ft'},
      'bedrooms': {'icon': Icons.bed, 'suffix': ' bed'},
    };

    // Build stat items from category fields
    for (final fieldName in priorityFields.keys) {
      if (categoryFields.containsKey(fieldName) && categoryFields[fieldName] != null) {
        final value = categoryFields[fieldName];
        final config = priorityFields[fieldName]!;
        
        if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
          statItems.add(_buildStatItem(
            config['icon'] as IconData,
            '${value.toString()}${config['suffix']}',
          ));
        }
      }
    }

    // Fallback to legacy stats if no category fields
    if (statItems.isEmpty) {
      final stats = product.stats;
      if (stats.year != null) {
        statItems.add(_buildStatItem(Icons.calendar_today, stats.year!));
      }
      if (stats.mileage != null) {
        statItems.add(_buildStatItem(Icons.speed, stats.mileage!));
      }
      if (stats.fuelType != null) {
        statItems.add(_buildStatItem(Icons.local_gas_station, stats.fuelType!));
      }
      if (stats.transmission != null) {
        statItems.add(_buildStatItem(Icons.settings, stats.transmission!));
      }
    }

    if (statItems.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE9ECEF), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: statItems.take(4).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        body: Consumer<ProductDetailProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(provider.error!, style: TextStyle(color: Colors.red)),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refreshData(),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (provider.product == null) {
              return Center(child: Text('Product not found'));
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Images with Overlay AppBar
                  _buildImageSectionWithOverlay(provider.product!, provider),
                  
                  // Content Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price
                        _buildTitlePriceSection(provider.product!),
                        
                        SizedBox(height: 25),
                        
                        // Action Buttons
                        _buildActionButtons(provider),
                        
                        SizedBox(height: 30),
                        
                        // ENHANCED: Category-specific Stats Row
                        _buildCategoryStatsSection(provider.product!),
                        
                        SizedBox(height: 30),
                        
                        // ENHANCED: Category-specific Details Section
                        _buildCategoryDetailsSection(provider.product!),
                        
                        SizedBox(height: 30),
                        
                        // Description
                        _buildDescriptionSection(provider.product!),
                        
                        SizedBox(height: 30),
                        
                        // ENHANCED: Category-specific Features
                        _buildCategoryFeaturesSection(provider.product!),
                        
                        SizedBox(height: 30),
                        
                        // Seller Detail with Rating
                        _buildSellerSection(provider.seller, provider),
                        
                        SizedBox(height: 30),
                        
                        // Seller Reviews Section
                        _buildSellerReviewsSection(provider.seller),
                        
                        SizedBox(height: 30),
                        
                        // Related Products
                        _buildRelatedProductsSection(provider.relatedProducts),
                        
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: Consumer<ProductDetailProvider>(
          builder: (context, provider, child) {
            if (provider.product == null || provider.seller == null) {
              return SizedBox.shrink();
            }
            
            return _canUserReview(provider.seller!.id) 
                ? FloatingActionButton.extended(
                    onPressed: () => _showQuickReviewDialog(provider.product!, provider.seller!),
                    backgroundColor: Color(0xFF2D5016),
                    icon: Icon(Icons.star_outline, color: Colors.white),
                    label: Text(
                      'Review Seller',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : SizedBox.shrink();
          },
        ),
      ),
    );
  }
  Widget _buildCategoryDetailsSection(ProductDetailModel product) {
  print('Building category details section for: ${product.title}');
  
  final categoryFields = _getCategorySpecificFields(product);
  print('Category fields for UI: $categoryFields');
  
  List<Widget> details = [];

  // Add category-specific fields first
  if (categoryFields.isNotEmpty) {
    print('Found ${categoryFields.length} category fields');
    
    // Organize fields by category for better display
    final organizedFields = _organizeFieldsByCategory(categoryFields, product);
    print('Organized fields: $organizedFields');
    
    for (final categoryEntry in organizedFields.entries) {
      print('Processing category: ${categoryEntry.key} with ${categoryEntry.value.length} fields');
      
      // Add category header if multiple categories
      if (organizedFields.keys.length > 1) {
        details.add(
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              _getCategoryDisplayName(categoryEntry.key),
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D5016),
              ),
            ),
          ),
        );
      }
      
      // Add fields in this category
      for (final field in categoryEntry.value) {
        final label = field['label'] as String? ?? '';
        final value = field['value'] as String? ?? '';
        print('Adding field: $label = $value');
        if (label.isNotEmpty && value.isNotEmpty) {
          details.add(_buildDetailRow(label, value));
        }
      }
    }
  } else {
    print('No category fields found');
  }

  // Add standard fields that aren't in category fields
  final standardFields = _getStandardFields(product, categoryFields);
  print('Standard fields: ${standardFields.length}');
  for (final field in standardFields) {
    final label = field['label'] as String? ?? '';
    final value = field['value'] as String? ?? '';
    if (label.isNotEmpty && value.isNotEmpty) {
      details.add(_buildDetailRow(label, value));
      print('Added standard field: $label = $value');
    }
  }

  // Always add Ad ID and Views
  details.add(_buildDetailRow('Ad ID', product.id.substring(0, 8).toUpperCase()));
  details.add(_buildDetailRow('Views', product.viewCount.toString()));

  if (details.isEmpty) {
    print('No details to show');
    return SizedBox.shrink();
  }

  print('Rendering ${details.length} detail items');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Specifications',
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      SizedBox(height: 15),
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE9ECEF), width: 1),
        ),
        child: Column(children: details),
      ),
    ],
  );
}

  Widget _buildCategoryFeaturesSection(ProductDetailModel product) {
    final categoryFields = _getCategorySpecificFields(product);
    List<String> features = [];

    // Extract boolean features from category fields
    final booleanFeatures = _extractBooleanFeatures(categoryFields);
    features.addAll(booleanFeatures);

    // Add legacy features
    features.addAll(product.features);

    if (features.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 15),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE9ECEF), width: 1),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              return _buildFeatureItem(
                _getFeatureIcon(features[index]),
                features[index],
              );
            },
          ),
        ),
      ],
    );
  }
  String _getCategoryDisplayName(String categoryKey) {
    final categoryNames = {
      'basic_info': 'Basic Information',
      'technical': 'Technical Specifications',
      'appearance': 'Appearance',
      'design': 'Design',
      'features': 'Features',
      'classification': 'Classification',
      'size': 'Size & Dimensions',
      'layout': 'Layout',
      'connectivity': 'Connectivity',
      'software': 'Software',
      'quality': 'Quality',
      'condition': 'Condition',
      'amenities': 'Amenities',
      'service': 'Service',
      'sizing': 'Sizing',
    };
    
    return categoryNames[categoryKey] ?? categoryKey.replaceAll('_', ' ').toUpperCase();
  }
  // Helper method to get category-specific fields from product
 Map<String, dynamic> _getCategorySpecificFields(ProductDetailModel product) {
  print('=== DEBUG: Getting Category Specific Fields ===');
  print('Product ID: ${product.id}');
  print('Product title: ${product.title}');
  print('Product category: ${product.category}');
  
  // Debug: Print all specifications
  print('All product specifications:');
  product.specifications.forEach((key, value) {
    print('  $key: $value (${value.runtimeType})');
  });
  
  final categoryFields = <String, dynamic>{};
  
  // Method 1: Try to get from product's categorySpecificFields
  if (product.specifications.containsKey('categorySpecificFields')) {
    final fields = product.specifications['categorySpecificFields'];
    print('Found categorySpecificFields: $fields (${fields.runtimeType})');
    
    if (fields is Map<String, dynamic>) {
      print('categorySpecificFields is Map<String, dynamic>');
      final extractedFields = Map<String, dynamic>.from(fields);
      print('Extracted fields: $extractedFields');
      categoryFields.addAll(extractedFields);
    } else if (fields is Map) {
      print('categorySpecificFields is generic Map, converting...');
      fields.forEach((key, value) {
        if (key is String) {
          categoryFields[key] = value;
          print('  Added: $key = $value');
        }
      });
    }
  } else {
    print('No categorySpecificFields found in specifications');
  }
  
  // Method 2: Try to get from flattenedFields
  if (product.specifications.containsKey('flattenedFields')) {
    final flattenedFields = product.specifications['flattenedFields'];
    print('Found flattenedFields: $flattenedFields');
    
    if (flattenedFields is Map) {
      flattenedFields.forEach((key, value) {
        if (key is String && key.startsWith('cf_')) {
          // Remove 'cf_' prefix
          final fieldName = key.substring(3);
          categoryFields[fieldName] = value;
          print('  Added from flattened: $fieldName = $value');
        }
      });
    }
  }
  
  // Method 3: Direct field extraction (fallback)
  final knownCategoryFields = {
    'year', 'kilometers', 'mileage', 'fuel_type', 'transmission', 'engine_capacity',
    'body_type', 'car_type', 'doors', 'seating_capacity', 'power_steering',
    'air_conditioning', 'bike_type', 'engine_type', 'storage', 'ram',
    'screen_size', 'battery_capacity', 'network_type', 'dual_sim',
    'processor', 'storage_type', 'storage_capacity', 'graphics_card',
    'operating_system', 'property_type', 'area', 'bedrooms', 'bathrooms',
    'furnished', 'parking', 'purpose', 'size', 'material', 'gender',
    'room_type', 'assembly_required', 'sport_type', 'suitable_for'
  };

  print('Checking known category fields...');
  for (final fieldName in knownCategoryFields) {
    if (product.specifications.containsKey(fieldName)) {
      if (!categoryFields.containsKey(fieldName)) {
        categoryFields[fieldName] = product.specifications[fieldName];
        print('  Added known field: $fieldName = ${product.specifications[fieldName]}');
      }
    }
  }
  
  print('Final category fields: $categoryFields');
  print('=== END DEBUG ===');
  
  return categoryFields;
}
  // Helper method to organize fields by category
  Map<String, List<Map<String, String>>> _organizeFieldsByCategory(
    Map<String, dynamic> fields, 
    ProductDetailModel product
  ) {
    final organized = <String, List<Map<String, String>>>{};
    
    // Field category mapping
    final fieldCategories = {
      'basic_info': ['year', 'kilometers', 'mileage'],
      'technical': ['fuel_type', 'transmission', 'engine_capacity', 'processor', 'ram', 'storage_type', 'storage_capacity'],
      'appearance': ['color', 'body_type', 'car_type'],
      'design': ['doors', 'seating_capacity', 'screen_size'],
      'features': ['power_steering', 'air_conditioning', 'dual_sim'],
      'classification': ['property_type', 'bike_type', 'gender', 'sport_type'],
      'size': ['area', 'size'],
      'layout': ['bedrooms', 'bathrooms'],
      'connectivity': ['network_type'],
      'software': ['operating_system'],
      'quality': ['material'],
      'condition': ['furnished'],
      'amenities': ['parking'],
      'service': ['assembly_required'],
      'sizing': ['suitable_for'],
    };

    // Categorize fields
    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final fieldValue = entry.value;
      
      if (fieldValue == null || fieldValue.toString().isEmpty || fieldValue.toString() == 'null') {
        continue;
      }

      String category = 'general';
      for (final catEntry in fieldCategories.entries) {
        if (catEntry.value.contains(fieldName)) {
          category = catEntry.key;
          break;
        }
      }

      organized.putIfAbsent(category, () => []).add({
        'label': _getFieldDisplayName(fieldName),
        'value': _formatFieldValue(fieldValue, fieldName),
      });
    }

    return organized;
  }
  String _getFieldDisplayName(String fieldName) {
    final displayNames = {
      'year': 'Year',
      'kilometers': 'Mileage',
      'mileage': 'Mileage',
      'fuel_type': 'Fuel Type',
      'transmission': 'Transmission',
      'engine_capacity': 'Engine Capacity',
      'body_type': 'Body Type',
      'car_type': 'Car Type',
      'doors': 'Doors',
      'seating_capacity': 'Seating',
      'power_steering': 'Power Steering',
      'air_conditioning': 'Air Conditioning',
      'bike_type': 'Bike Type',
      'engine_type': 'Engine Type',
      'storage': 'Storage',
      'ram': 'RAM',
      'screen_size': 'Screen Size',
      'battery_capacity': 'Battery',
      'network_type': 'Network',
      'dual_sim': 'Dual SIM',
      'processor': 'Processor',
      'storage_type': 'Storage Type',
      'storage_capacity': 'Storage Capacity',
      'graphics_card': 'Graphics Card',
      'operating_system': 'Operating System',
      'property_type': 'Property Type',
      'area': 'Area',
      'bedrooms': 'Bedrooms',
      'bathrooms': 'Bathrooms',
      'furnished': 'Furnished',
      'parking': 'Parking',
      'purpose': 'Purpose',
      'size': 'Size',
      'material': 'Material',
      'gender': 'Gender',
      'room_type': 'Room Type',
      'assembly_required': 'Assembly Required',
      'sport_type': 'Sport Type',
      'suitable_for': 'Suitable For',
    };
    
    return displayNames[fieldName] ?? fieldName.replaceAll('_', ' ').split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Helper method to format field values
  String _formatFieldValue(dynamic value, String fieldName) {
    if (value == null) return 'N/A';
    
    // Add units/suffixes based on field type
    final fieldUnits = {
      'kilometers': ' km',
      'mileage': ' km',
      'engine_capacity': ' CC',
      'area': ' sq ft',
      'battery_capacity': ' mAh',
      'screen_size': '"',
    };
    
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    
    final unit = fieldUnits[fieldName] ?? '';
    return '${value.toString()}$unit';
  }
  // Helper method to get standard fields not in category fields
  List<Map<String, String>> _getStandardFields(
    ProductDetailModel product, 
    Map<String, dynamic> categoryFields
  ) {
    final standardFields = <Map<String, String>>[];
    
    // Only add standard fields if they're not already in category fields
    if (!categoryFields.containsKey('color') && product.color != null && product.color!.isNotEmpty) {
      standardFields.add({'label': 'Color', 'value': product.color!});
    }
    
    if (product.brand != null && product.brand!.isNotEmpty) {
      standardFields.add({'label': 'Brand', 'value': product.brand!});
    }
    
    if (product.dimensions != null && product.dimensions!.isNotEmpty) {
      standardFields.add({'label': 'Dimensions', 'value': product.dimensions!});
    }

    // Add legacy specifications that aren't category fields
    final specs = product.specifications;
    final stats = product.stats;
    
    if (stats.registeredIn != null && !categoryFields.containsKey('registered_in')) {
      standardFields.add({'label': 'Registered in', 'value': stats.registeredIn!});
    }
    
    if (stats.assembly != null && !categoryFields.containsKey('assembly')) {
      standardFields.add({'label': 'Assembly', 'value': stats.assembly!});
    }

    return standardFields;
  }

  // Helper method to extract boolean features
  List<String> _extractBooleanFeatures(Map<String, dynamic> fields) {
    final features = <String>[];
    
    for (final entry in fields.entries) {
      if (entry.value is bool && entry.value == true) {
        features.add(_getFieldDisplayName(entry.key));
      }
    }
    
    return features;
  }

Widget _buildImageSectionWithOverlay(ProductDetailModel product, ProductDetailProvider provider) {
  return Stack(
    children: [
      // Main Image Container
      Container(
        height: 400, // Increased height to accommodate status bar
        width: double.infinity,
        child: product.imageUrls.isNotEmpty
            ? PageView.builder(
                controller: _pageController,
                itemCount: product.imageUrls.length,
                onPageChanged: (index) => provider.updateImageIndex(index),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE8E8E8), Color(0xFFF5F5F5)],
                      ),
                    ),
                    child: UniversalImage(
                        imageUrl:  product.imageUrls[index],
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    // Image.network(
                    //   product.imageUrls[index],
                    //   fit: BoxFit.cover,
                    //   errorBuilder: (context, error, stackTrace) {
                    //     return Container(
                    //       color: Colors.grey[300],
                    //       child: Center(
                    //         child: Icon(Icons.image, size: 80, color: Colors.grey[600]),
                    //       ),
                    //     );
                    //   },
                    // ),
                  );
                },
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8E8E8), Color(0xFFF5F5F5)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey[600]),
                ),
              ),
      ),
      
      // Gradient overlay for better icon visibility
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 120,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      
      // Custom AppBar overlay
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Container(
            height: 56,
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // Back Button
                Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                Spacer(),
                
                // Action Buttons
                Consumer<ProductDetailProvider>(
                  builder: (context, provider, child) {
                    return Row(
                      children: [
                        // Favorite Button
                        Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              provider.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: provider.isFavorite ? Colors.red : Colors.black,
                            ),
                            onPressed: () => provider.toggleFavorite(),
                          ),
                        ),
                        
                        // Share Button
                        Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.share_outlined, color: Colors.black),
                            onPressed: () => _shareProduct(provider),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      
      // Image counter (bottom right)
      if (product.imageUrls.length > 1)
        Positioned(
          bottom: 15,
          right: 20,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${provider.currentImageIndex + 1}/${product.imageUrls.length}',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      
      // Negotiable tag (bottom left)
      if (product.allowPriceNegotiation)
        Positioned(
          bottom: 15,
          left: 20,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.yellow[700],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              'Negotiable',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
    ],
  );
}
  Widget _buildTitlePriceSection(ProductDetailModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 5),
        Text(
          product.getFormattedPrice(),
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5),
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                product.locationAddress ?? 'Location not specified',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Text(
              product.getTimeSincePosted(),
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        if (product.condition.isNotEmpty) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getConditionColor(product.condition),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product.condition,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

 Widget _buildActionButtons(ProductDetailProvider provider) {
  return Row(
    children: [
      Expanded(
        child: Container(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => provider.chatWithSeller(context),
            icon: Icon(Icons.chat_outlined, color: Colors.white),
            label: Text(
             '${AppLocalizations.chat.tr()}',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2D5016),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ),
      SizedBox(width: 15),
      Expanded(
        child: Container(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _handleCallButtonPress(provider),
            icon: Icon(
              provider.sellerHasPhoneNumber 
                ? Icons.phone_outlined 
                : Icons.phone_disabled_outlined,
              color: Colors.white,
            ),
            label: Text(
              provider.sellerHasPhoneNumber ? '${AppLocalizations.call.tr()}' : 'No Number',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.sellerHasPhoneNumber 
                ? Color(0xFF2D5016) 
                : Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
  Widget _buildStatsSection(ProductDetailModel product) {
    final stats = product.stats;
    List<Widget> statItems = [];

    if (stats.year != null) {
      statItems.add(_buildStatItem(Icons.calendar_today_outlined, stats.year!));
    }
    if (stats.mileage != null) {
      statItems.add(_buildStatItem(Icons.speed_outlined, stats.mileage!));
    }
    if (stats.fuelType != null) {
      statItems.add(_buildStatItem(Icons.local_gas_station_outlined, stats.fuelType!));
    }
    if (stats.transmission != null) {
      statItems.add(_buildStatItem(Icons.settings_outlined, stats.transmission!));
    }

    if (statItems.isEmpty) return SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: statItems.take(4).toList(),
    );
  }

  Widget _buildDetailsSection(ProductDetailModel product) {
    List<Widget> details = [];
    final specs = product.specifications;
    final stats = product.stats;

    // Add common details
    if (stats.registeredIn != null) {
      details.add(_buildDetailRow('Registered in', stats.registeredIn!));
    }
    if (product.color != null) {
      details.add(_buildDetailRow('Color', product.color!));
    }
    if (stats.assembly != null) {
      details.add(_buildDetailRow('Assembly', stats.assembly!));
    }
    if (stats.engineCapacity != null) {
      details.add(_buildDetailRow('Engine Capacity', stats.engineCapacity!));
    }
    if (stats.bodyType != null) {
      details.add(_buildDetailRow('Body Type', stats.bodyType!));
    }
    if (product.brand != null) {
      details.add(_buildDetailRow('Brand', product.brand!));
    }

    // Add custom specifications
    specs.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        details.add(_buildDetailRow(_formatSpecKey(key), value.toString()));
      }
    });

    details.add(_buildDetailRow('Ad ID', product.id.substring(0, 8)));
    details.add(_buildDetailRow('Views', product.viewCount.toString()));

    if (details.isEmpty) return SizedBox.shrink();

    return Column(children: details);
  }

  Widget _buildDescriptionSection(ProductDetailModel product) {
    if (product.description.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
        AppLocalizations.description.tr(),
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 15),
        Text(
          product.description,
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(ProductDetailModel product) {
    if (product.features.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 4,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: product.features.length,
          itemBuilder: (context, index) {
            return _buildFeatureItem(
              _getFeatureIcon(product.features[index]),
              product.features[index],
            );
          },
        ),
      ],
    );
  }

 Widget _buildSellerSection(SellerModel? seller, ProductDetailProvider provider) {
  if (seller == null) return SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppLocalizations.sellerDetail.tr(),
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      SizedBox(height: 15),
      Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _navigateToSellerProfile(seller.id),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: seller.profileImageUrl != null
                        ? NetworkImage(seller.profileImageUrl!)
                        : null,
                    child: seller.profileImageUrl == null
                        ? Icon(Icons.person, size: 30)
                        : null,
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.getDisplayName(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '${ AppLocalizations.memberSince.tr()}: ${seller.getMemberSinceFormatted()}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 5),
                        UserRatingWidget(
                          userId: seller.id,
                          showCount: true,
                          iconSize: 16,
                          fontSize: 14,
                        ),
                        // Show phone status
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              provider.sellerHasPhoneNumber 
                                ? Icons.phone 
                                : Icons.phone_disabled,
                              size: 12,
                              color: provider.sellerHasPhoneNumber 
                                ? Colors.green 
                                : Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              provider.sellerHasPhoneNumber
                                ? '${AppLocalizations.phoneAvailable.tr()}'
                                : 'No phone number',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: provider.sellerHasPhoneNumber 
                                  ? Colors.green[700] 
                                  : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (provider.sellerHasPhoneNumber && provider.sellerFormattedPhone != null) ...[
                              SizedBox(width: 8),
                              Text(
                                provider.sellerFormattedPhone!,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: () => provider.chatWithSeller(context),
                              child: Icon(
                                Icons.message_outlined,
                                size: 20,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: provider.sellerHasPhoneNumber 
                                  ? Colors.green.withOpacity(0.3) 
                                  : Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _handleCallButtonPress(provider),
                              child: Icon(
                                provider.sellerHasPhoneNumber 
                                  ? Icons.phone_outlined 
                                  : Icons.phone_disabled_outlined,
                                size: 20,
                                color: provider.sellerHasPhoneNumber 
                                  ? Colors.grey[700] 
                                  : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      InkWell(
                        onTap: () => _navigateToSellerProfile(seller.id),
                        child: Text(
                          'View Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Color(0xFF2D5016),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Quick action buttons
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showQuickReviewDialog(provider.product!, seller),
                    icon: Icon(Icons.star_outline, size: 18),
                    label: Text(
                     '${AppLocalizations.leaveReview.tr()}',
                      style: GoogleFonts.outfit(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF2D5016),
                      side: BorderSide(color: Color(0xFF2D5016)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToSellerReviews(seller.id),
                    icon: Icon(Icons.reviews_outlined, size: 18),
                    label: Text(
                 '${AppLocalizations.allReviews.tr()}',
                      style: GoogleFonts.outfit(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

  // New method to build seller reviews section
  Widget _buildSellerReviewsSection(SellerModel? seller) {
    if (seller == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
             '${AppLocalizations.recentReviews.tr()}',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToSellerReviews(seller.id),
              child: Text(
                'View All',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Color(0xFF2D5016),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        // Use the RecentReviewsWidget
        RecentReviewsWidget(
          userId: seller.id,
          maxReviews: 2,
        ),
      ],
    );
  }

  Widget _buildRelatedProductsSection(List<ProductDetailModel> relatedProducts) {
    if (relatedProducts.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Products',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 15),
        Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: relatedProducts.length,
            itemBuilder: (context, index) {
              final product = relatedProducts[index];
              return Container(
                width: 150,
                margin: EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(productId: product.id),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          child: product.imageUrls.isNotEmpty
                              ? Image.network(
                                  product.imageUrls.first,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.image, color: Colors.grey[400]),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image, color: Colors.grey[400]),
                                ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              product.getFormattedPrice(),
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper methods
  Widget _buildStatItem(IconData icon, String text) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2D5016).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon, 
              size: 24, 
              color: Color(0xFF2D5016),
            ),
          ),
          SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
   Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFeatureItem(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE9ECEF), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Color(0xFF2D5016).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon, 
              size: 18, 
              color: Color(0xFF2D5016),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Review-related methods
  bool _canUserReview(String sellerId) {
    // Logic to check if current user can review this seller
    // This would typically check if user has purchased from this seller
    // and hasn't already reviewed them
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid == sellerId) {
      return false; // Can't review yourself
    }
    return true; // Simplified - in real app, check purchase history
  }

  void _showQuickReviewDialog(ProductDetailModel product, SellerModel seller) {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Rate ${seller.getDisplayName()}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your experience with this seller?',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => rating = index + 1.0),
                    child: Icon(
                      Icons.star,
                      size: 36,
                      color: index < rating ? Colors.amber : Colors.grey[300],
                    ),
                  );
                }),
              ),
              SizedBox(height: 8),
              Text(
                _getRatingText(rating),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getRatingColor(rating),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFF2D5016)),
                  ),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _submitQuickReviewWithDebug(product, seller, rating, commentController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2D5016),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Submit Review',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _debugReviewSubmission(ProductDetailModel product, SellerModel seller) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    log('DEBUG: No current user');
    return;
  }

  log('=== DEBUG REVIEW SUBMISSION ===');
  log('Current User ID: ${user.uid}');
  log('Product ID: ${product.id}');
  log('Seller ID: ${seller.id}');
  log('Product Title: ${product.title}');
  log('Seller Name: ${seller.getDisplayName()}');

  // Check document existence
  final reviewService = ReviewService();
  Map<String, bool> docCheck = await reviewService.debugCheckDocuments(
    reviewerId: user.uid,
    revieweeId: seller.id,
    itemId: product.id,
  );

  log('Document Existence Check:');
  log('- Reviewer (${user.uid}): ${docCheck['reviewer']}');
  log('- Reviewee (${seller.id}): ${docCheck['reviewee']}');
  log('- Item (${product.id}): ${docCheck['item']}');

  // Check specific field values
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      log('Reviewer Data:');
      log('- Type: ${userData['type']}');
      log('- Email: ${userData['email']}');
      log('- Company Name: ${userData['companyName']}');
    }

    DocumentSnapshot sellerDoc = await FirebaseFirestore.instance.collection('users').doc(seller.id).get();
    if (sellerDoc.exists) {
      Map<String, dynamic> sellerData = sellerDoc.data() as Map<String, dynamic>;
      log('Seller Data:');
      log('- Type: ${sellerData['type']}');
      log('- Email: ${sellerData['email']}');
      log('- Company Name: ${sellerData['companyName']}');
    }

    DocumentSnapshot itemDoc = await FirebaseFirestore.instance.collection('items').doc(product.id).get();
    if (itemDoc.exists) {
      Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
      log('Item Data:');
      log('- Title: ${itemData['title']}');
      log('- ItemTitle: ${itemData['itemTitle']}');
      log('- SellerId: ${itemData['sellerId']}');
      log('- Status: ${itemData['status']}');
    }
  } catch (e) {
    log('Error during debug check: $e');
  }

  log('=== END DEBUG ===');
}

// Modified review submission method with debug
Future<void> _submitQuickReviewWithDebug(
  ProductDetailModel product, 
  SellerModel seller, 
  double rating, 
  String comment
) async {
  try {
    // First run debug
    await _debugReviewSubmission(product, seller);

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Submitting review...'),
          ],
        ),
        backgroundColor: Color(0xFF2D5016),
        duration: Duration(seconds: 2),
      ),
    );

    final reviewProvider = context.read<ReviewProvider>();
    
    bool success = await reviewProvider.createReview(
      revieweeId: seller.id,
      itemId: product.id,
      rating: rating,
      comment: comment.trim(),
      transactionType: 'purchase',
    );

    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Review submitted successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      log('Review submission failed. Error: ${reviewProvider.error}');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reviewProvider.error ?? 'Failed to submit review'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    log('Exception during review submission: $e');
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
}


  void _navigateToSellerProfile(String sellerId) {
    // Navigate to seller's profile page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountProfilePage(userId: sellerId,),
      ),
    );
  }

  void _navigateToSellerReviews(String sellerId) {
    // Navigate to seller's reviews page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsPage(
          userId: sellerId,
          showCreateReviewButton: false,
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent';
  }

  Color _getRatingColor(double rating) {
    if (rating <= 2) return Colors.red;
    if (rating <= 3) return Colors.orange;
    if (rating <= 4) return Colors.blue;
    return Colors.green;
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'used':
        return Colors.orange;
      case 'refurbished':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

 IconData _getFeatureIcon(String feature) {
    String lowerFeature = feature.toLowerCase();
    if (lowerFeature.contains('power steering')) return Icons.casino;
    if (lowerFeature.contains('air conditioning') || lowerFeature.contains('ac')) return Icons.ac_unit;
    if (lowerFeature.contains('lock')) return Icons.lock_outline;
    if (lowerFeature.contains('seat')) return Icons.airline_seat_recline_normal;
    if (lowerFeature.contains('automatic') || lowerFeature.contains('gear')) return Icons.settings;
    if (lowerFeature.contains('speed')) return Icons.speed;
    if (lowerFeature.contains('bluetooth')) return Icons.bluetooth;
    if (lowerFeature.contains('camera')) return Icons.camera_alt;
    if (lowerFeature.contains('gps') || lowerFeature.contains('navigation')) return Icons.navigation;
    if (lowerFeature.contains('dual sim')) return Icons.sim_card;
    if (lowerFeature.contains('parking')) return Icons.local_parking;
    if (lowerFeature.contains('furnished')) return Icons.chair;
    return Icons.check_circle_outline;
  }
  String _formatSpecKey(String key) {
    return key.split('_').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
    ).join(' ');
  }
}


// User Rating Widget (from the review system)
class UserRatingWidget extends StatelessWidget {
  final String userId;
  final bool showCount;
  final double iconSize;
  final double fontSize;

  const UserRatingWidget({
    Key? key,
    required this.userId,
    this.showCount = true,
    this.iconSize = 16,
    this.fontSize = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReviewService().getUserRatingSummary(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: iconSize, color: Colors.grey[300]),
              SizedBox(width: 4),
              Text(
                '--',
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  color: Colors.grey[500],
                ),
              ),
            ],
          );
        }

        final data = snapshot.data!;
        final rating = data['averageRating']?.toDouble() ?? 0.0;
        final count = data['reviewCount'] ?? 0;

        if (count == 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border, size: iconSize, color: Colors.grey[400]),
              SizedBox(width: 4),
              Text(
                'No reviews',
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  color: Colors.grey[500],
                ),
              ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: iconSize, color: Colors.amber),
            SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: GoogleFonts.outfit(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showCount) ...[
              SizedBox(width: 4),
              Text(
                '($count)',
                style: GoogleFonts.outfit(
                  fontSize: fontSize - 2,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// Recent Reviews Widget
class RecentReviewsWidget extends StatelessWidget {
  final String userId;
  final int maxReviews;

  const RecentReviewsWidget({
    Key? key,
    required this.userId,
    this.maxReviews = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ReviewService().getUserReviews(userId, limit: maxReviews),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Text(
                'No reviews yet',
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        final reviews = snapshot.data!.docs
            .map((doc) => ReviewModel.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList();

        return Column(
          children: reviews.map((review) => _buildCompactReviewCard(review)).toList(),
        );
      },
    );
  }

  Widget _buildCompactReviewCard(ReviewModel review) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
             Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => AccountProfilePage(userId: review.reviewerId,),
      ),
    );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFF2D5016),
                  child: Text(
                    review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : 'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.reviewerName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStarRating(review.rating, size: 12),
              ],
            ),
          ),
          if (review.comment.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              review.comment,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 4),
          Text(
            review.formattedDate,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 12}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}
