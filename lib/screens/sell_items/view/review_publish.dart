import 'dart:io';
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
import 'package:arabicmarketplace/screens/search_page/city_district_selection_page.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/view/success_page.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
class ReviewPublishPage extends StatefulWidget {
  const ReviewPublishPage({Key? key}) : super(key: key);

  @override
  State<ReviewPublishPage> createState() => _ReviewPublishPageState();
}

class _ReviewPublishPageState extends State<ReviewPublishPage> {
  PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showLocationDialog(BuildContext context, ItemProvider itemProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            easy.tr('choose_location'),
            style: GoogleFonts.jost(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLocationOption(
                context,
                itemProvider,
                Icons.location_city,
                Colors.blue,
                easy.tr('select_city_district'),
                easy.tr('choose_from_available_cities'),
                () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CityDistrictSelectionPage(),
                    ),
                  );
                  
                  if (result != null) {
                    itemProvider.updateLocation(
                      latitude: result['latitude'] ?? 0.0,
                      longitude: result['longitude'] ?? 0.0,
                      locationAddress: result['fullAddress'],
                    );
                    
                    _showSnackBar(context, easy.tr('location_updated_to', args: [result['fullAddress']]), Colors.green);
                  }
                },
              ),
              SizedBox(height: 8),
              _buildLocationOption(
                context,
                itemProvider,
                Icons.my_location,
                Colors.orange,
                easy.tr('use_current_location'),
                easy.tr('get_current_gps_location'),
                () async {
                  Navigator.pop(context);
                  final success = await itemProvider.fetchUserLocation(context);
                  if (!success && itemProvider.error != null) {
                    _showSnackBar(context, itemProvider.error!, Colors.red);
                  } else if (success) {
                    _showSnackBar(context, easy.tr('location_updated_successfully'), Colors.green);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationOption(
    BuildContext context,
    ItemProvider itemProvider,
    IconData icon,
    Color color,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ItemProvider, UserProvider>(
      builder: (context, itemProvider, userProvider, child) {
        final user = userProvider.currentUser;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            surfaceTintColor: Colors.white,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              AppLocalizations.reviewPublish.tr(),
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Text(
                    AppLocalizations.reviewPublishListing.tr(),
                    style: GoogleFonts.jost(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.heresPreview.tr(),
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Enhanced Image Slider Section
                  _buildImageSlider(itemProvider),
                  const SizedBox(height: 24),

                  // Error display
                  if (itemProvider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              itemProvider.error!,
                              style: GoogleFonts.jost(
                                fontSize: 14,
                                color: Colors.red[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Product Details Section
                  _buildProductDetails(itemProvider),
                  const SizedBox(height: 24),

                  // Seller Information Section
                  _buildSellerInfo(user),
                  const SizedBox(height: 24),

                  // Location Section
                  _buildLocationSection(itemProvider),
                  const SizedBox(height: 32),

                  // Enhanced Publish Button
                  _buildPublishButton(itemProvider),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Enhanced Image Slider with indicators and swipe functionality
  Widget _buildImageSlider(ItemProvider itemProvider) {
    if (itemProvider.images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              easy.tr('no_images_added'),
              style: GoogleFonts.jost(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              easy.tr('add_photos_to_preview'),
              style: GoogleFonts.jost(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Image PageView
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: itemProvider.images.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(File(itemProvider.images[index].path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),

          // Image Counter
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${itemProvider.images.length}',
                style: GoogleFonts.jost(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Navigation Arrows (if more than 1 image)
          if (itemProvider.images.length > 1) ...[
            // Previous Button
            if (_currentImageIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

            // Next Button
            if (_currentImageIndex < itemProvider.images.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
          ],

          // Page Indicators
          if (itemProvider.images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  itemProvider.images.length,
                  (index) => Container(
                    width: index == _currentImageIndex ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == _currentImageIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
// UPDATED: Enhanced Product Details Section with Category-Specific Fields
Widget _buildProductDetails(ItemProvider itemProvider) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Brand
      if (itemProvider.brand?.isNotEmpty == true)
        Text(
          itemProvider.brand!,
          style: GoogleFonts.jost(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      if (itemProvider.brand?.isNotEmpty == true) SizedBox(height: 4),

      // Title
      Text(
        itemProvider.itemTitle?.isNotEmpty == true
            ? itemProvider.itemTitle!
            : easy.tr('untitled'),
        style: GoogleFonts.jost(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 12),

      // Price and Negotiation
      Row(
        children: [
          Text(
            itemProvider.price != null && itemProvider.price! > 0
                ? 'S.P. ${itemProvider.price!.toStringAsFixed(0)}'
                : easy.tr('free'),
            style: GoogleFonts.jost(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ColorsController.primaryColor,
            ),
          ),
          if (itemProvider.allowPriceNegotiation) ...[
            SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Text(
                AppLocalizations.negotiable.tr(),
                style: GoogleFonts.jost(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 16),

      // Description
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.description.tr(),
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              itemProvider.description?.isNotEmpty == true
                  ? itemProvider.description!
                  : easy.tr('no_description_provided'),
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),

      // NEW: Category-Specific Details Section
      if (itemProvider.categorySpecificFields.isNotEmpty) ...[
        SizedBox(height: 16),
        _buildCategorySpecificDetails(itemProvider),
      ],

      // Basic Details (only show if not already shown in category-specific fields)
      if (itemProvider.condition?.isNotEmpty == true ||
          itemProvider.color?.isNotEmpty == true ||
          itemProvider.dimensions?.isNotEmpty == true) ...[
        SizedBox(height: 16),
        _buildBasicDetails(itemProvider),
      ],
    ],
  );
}

// NEW: Build Category-Specific Details Section
Widget _buildCategorySpecificDetails(ItemProvider itemProvider) {
  final categoryFields = itemProvider.categorySpecificFields;
  final categoryTemplate = itemProvider.categoryFieldTemplate;
  final categoryName = itemProvider.categoryTemplateName ?? itemProvider.categoryName;
  
  if (categoryFields.isEmpty) return SizedBox.shrink();

  // Group fields by category for better organization
  final organizedFields = <String, List<MapEntry<String, dynamic>>>{};
  
  for (final entry in categoryFields.entries) {
    if (entry.value != null && entry.value.toString().isNotEmpty) {
      // Find field template info
      final fieldTemplate = categoryTemplate.firstWhere(
        (template) => template['name'] == entry.key,
        orElse: () => <String, dynamic>{},
      );
      
      final category = fieldTemplate['category'] ?? 'general';
      organizedFields.putIfAbsent(category, () => []).add(entry);
    }
  }

  if (organizedFields.isEmpty) return SizedBox.shrink();

  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with category name
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(categoryName),
                size: 20,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '$categoryName ${easy.tr("specifications")}',
                style: GoogleFonts.jost(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Display fields organized by category
        ...organizedFields.entries.map((categoryEntry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category section header (only if multiple categories)
              if (organizedFields.keys.length > 1) ...[
                Text(
                  _getCategoryDisplayName(categoryEntry.key),
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: 8),
              ],
              
              // Fields in this category
              ...categoryEntry.value.map((fieldEntry) {
                // Find field template for proper label and formatting
                final fieldTemplate = categoryTemplate.firstWhere(
                  (template) => template['name'] == fieldEntry.key,
                  orElse: () => <String, dynamic>{},
                );
                
                final label = fieldTemplate['label'] ?? _formatFieldName(fieldEntry.key);
                final suffix = fieldTemplate['suffix'] ?? '';
                final fieldType = fieldTemplate['type'] ?? 'text';
                
                return _buildDetailRow(
                  label, 
                  _formatFieldValue(fieldEntry.value, fieldType, suffix),
                );
              }).toList(),
              
              if (organizedFields.keys.length > 1) SizedBox(height: 12),
            ],
          );
        }).toList(),
      ],
    ),
  );
}

// NEW: Build Basic Details (condition, color, dimensions)
Widget _buildBasicDetails(ItemProvider itemProvider) {
  final hasBasicDetails = (itemProvider.condition?.isNotEmpty == true) ||
                         (itemProvider.color?.isNotEmpty == true && 
                          !itemProvider.categorySpecificFields.containsKey('color')) ||
                         (itemProvider.dimensions?.isNotEmpty == true);
  
  if (!hasBasicDetails) return SizedBox.shrink();

  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.green[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.green[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.green[700],
              ),
            ),
            SizedBox(width: 12),
            Text(
              easy.tr('additional_details'),
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        if (itemProvider.condition?.isNotEmpty == true)
          _buildDetailRow(AppLocalizations.condition.tr(), itemProvider.condition!),
        
        if (itemProvider.color?.isNotEmpty == true && 
            !itemProvider.categorySpecificFields.containsKey('color'))
          _buildDetailRow(AppLocalizations.color.tr(), itemProvider.color!),
        
        if (itemProvider.dimensions?.isNotEmpty == true)
          _buildDetailRow(AppLocalizations.dimensions.tr(), itemProvider.dimensions!),
      ],
    ),
  );
}

// Helper method to get category icon
IconData _getCategoryIcon(String? categoryName) {
  if (categoryName == null) return Icons.category;
  
  final name = categoryName.toLowerCase();
  if (name.contains('mobile') || name.contains('phone')) return Icons.smartphone;
  if (name.contains('computer') || name.contains('laptop')) return Icons.computer;
  if (name.contains('vehicle') || name.contains('car')) return Icons.directions_car;
  if (name.contains('house') || name.contains('property')) return Icons.home;
  if (name.contains('fashion') || name.contains('clothing')) return Icons.checkroom;
  if (name.contains('sport')) return Icons.sports;
  if (name.contains('electronics')) return Icons.devices;
  
  return Icons.category;
}

// Helper method to get category display name
String _getCategoryDisplayName(String categoryKey) {
  switch (categoryKey) {
    case 'basic_info': return 'Basic Information';
    case 'technical': return 'Technical Specifications';
    case 'appearance': return 'Appearance';
    case 'features': return 'Features';
    case 'comfort': return 'Comfort & Convenience';
    case 'connectivity': return 'Connectivity';
    case 'display': return 'Display';
    case 'software': return 'Software';
    case 'classification': return 'Classification';
    case 'design': return 'Design';
    case 'condition': return 'Condition';
    case 'size': return 'Size & Dimensions';
    case 'layout': return 'Layout';
    case 'amenities': return 'Amenities';
    case 'service': return 'Service & Support';
    case 'quality': return 'Quality';
    case 'sizing': return 'Sizing';
    default: return categoryKey.replaceAll('_', ' ').toUpperCase();
  }
}

// Helper method to format field names
String _formatFieldName(String fieldName) {
  return fieldName.split('_').map((word) => 
    word[0].toUpperCase() + word.substring(1)
  ).join(' ');
}

// Helper method to format field values based on type
String _formatFieldValue(dynamic value, String fieldType, String suffix) {
  if (value == null) return '';
  
  switch (fieldType) {
    case 'boolean':
      return (value as bool) ? 'Yes' : 'No';
    case 'number':
      if (suffix.isNotEmpty) {
        return '${value} $suffix';
      }
      return value.toString();
    case 'year_picker':
      return value.toString();
    default:
      return value.toString();
  }
}

// Enhanced detail row with better styling
Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: GoogleFonts.jost(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.jost(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ],
    ),
  );
}

  // Widget _buildDetailRow(String label, String value) {
  //   return Padding(
  //     padding: EdgeInsets.only(bottom: 8),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         SizedBox(
  //           width: 80,
  //           child: Text(
  //             '$label:',
  //             style: GoogleFonts.jost(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w500,
  //               color: Colors.grey[600],
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           child: Text(
  //             value,
  //             style: GoogleFonts.jost(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w500,
  //               color: Colors.black,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Seller Information Section
  Widget _buildSellerInfo(dynamic user) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: user?.profileImage != null
                ? ClipOval(
                    child: Image.network(
                      user!.profileImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.type == 'company'
                      ? (user?.companyName ?? easy.tr('anonymous_company'))
                      : AppLocalizations.individualSeller.tr(),
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  user?.type == 'company' ? AppLocalizations.company.tr() : AppLocalizations.individual.tr(),
                  style: GoogleFonts.jost(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ColorsController.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text(
                //   AppLocalizations.contactSeller.tr(),
                //   style: GoogleFonts.jost(
                //     fontSize: 12,
                //     fontWeight: FontWeight.w500,
                //     color: ColorsController.primaryColor,
                //   ),
                // ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: ColorsController.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Location Section
  Widget _buildLocationSection(ItemProvider itemProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.location.tr(),
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showLocationDialog(context, itemProvider),
              icon: Icon(
                Icons.edit_location,
                size: 16,
                color: ColorsController.primaryColor,
              ),
              label: Text(
                easy.tr('change'),
                style: GoogleFonts.jost(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ColorsController.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: itemProvider.locationAddress != null
                ? Colors.green[50]
                : Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: itemProvider.locationAddress != null
                  ? Colors.green[300]!
                  : Colors.red[300]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: itemProvider.locationAddress != null
                      ? Colors.green[100]
                      : Colors.red[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  itemProvider.locationAddress != null
                      ? Icons.location_on
                      : Icons.location_off,
                  color: itemProvider.locationAddress != null
                      ? Colors.green[700]
                      : Colors.red[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemProvider.locationAddress != null ? easy.tr('location_set') : easy.tr('location_required'),
                      style: GoogleFonts.jost(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: itemProvider.locationAddress != null
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                    Text(
                      itemProvider.locationAddress?.isNotEmpty == true
                          ? itemProvider.locationAddress!
                          : easy.tr('click_change_to_set_location'),
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        color: itemProvider.locationAddress != null
                            ? Colors.green[600]
                            : Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Enhanced Publish Button
  Widget _buildPublishButton(ItemProvider itemProvider) {
    final canPublish = itemProvider.canPublish && !itemProvider.isPublishing;
    
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canPublish ? () async {
          try {
            final success = await itemProvider.publishItem(context);
            if (success) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SuccessPage()),
              );
            }
          } catch (e) {
            _showSnackBar(context, 'Error: $e', Colors.red);
          }
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canPublish 
              ? ColorsController.primaryColor
              : Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canPublish ? 4 : 0,
          shadowColor: ColorsController.primaryColor.withOpacity(0.3),
        ),
        child: itemProvider.isPublishing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Publishing...',
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.publish,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    AppLocalizations.publish.tr(),
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
