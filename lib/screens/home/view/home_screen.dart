
import 'dart:io';

import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/account/controller/favorite_provider.dart';
import 'package:arabicmarketplace/screens/account/view/notifications_page.dart';
import 'package:arabicmarketplace/screens/home/controller/home_provider.dart';
import 'package:arabicmarketplace/screens/home/view/all_categories_page.dart';
import 'package:arabicmarketplace/screens/home/view/location_selection_page.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_page.dart';
import 'package:arabicmarketplace/widgets/image_optimise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
// How to integrate the backend with your existing MarketplaceHomePage

// 2. Updated MarketplaceHomePage with backend integration
class MarketplaceHomePage extends StatefulWidget {
  @override
  _MarketplaceHomePageState createState() => _MarketplaceHomePageState();
}

class _MarketplaceHomePageState extends State<MarketplaceHomePage> {
  @override
  void initState() {
    super.initState();
    // Initialize data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<HomeProvider>(
          builder: (context, homeProvider, child) {
            if (homeProvider.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (homeProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${homeProvider.error}'),
                    ElevatedButton(
                      onPressed: () => homeProvider.refreshData(),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => homeProvider.refreshData(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Section - FIXED
                    _buildHeader(context, homeProvider),
                    
                    // Browse Categories Section - FIXED with spacing
                    _buildCategoriesSection(homeProvider.categories),
                    
                    SizedBox(height: 8),
                    
                    // Featured Section - FIXED navigation
                    _buildFeaturedSection(homeProvider.featuredProducts),
                    
                    SizedBox(height: 8),
                    
                    // Personalized Section - FIXED navigation
                    _buildPersonalizedSection(homeProvider.personalizedProducts),
                    
                    SizedBox(height: 8),
                    
                    // Ad Banner Section
                    _buildAdBannersSection(homeProvider.adBanners),
                    
                    // Product Sections - FIXED navigation
                    _buildProductSection('Most Viewed', homeProvider.mostViewedProducts),
                    _buildProductSection('Mobile Phones', homeProvider.mobilePhones),
                    _buildProductSection('Computers', homeProvider.computers),
                    _buildProductSection('Computer Accessories', homeProvider.computerAccessories),
                    
                    SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // FIXED HEADER: Notification icon aligned with location, longer search bar
  Widget _buildHeader(BuildContext context, HomeProvider homeProvider) {
    return Container(
      padding: EdgeInsets.all(6),
      color: Colors.white,
      child: Column(
        children: [
          // Top Row with Logo and Search
          Row(
            children: [
              // Menu Icon with logo
              Container(
                height: 70,
                width: 62,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset('assets/icons/home_logo.png', 
                  height: 70, width: 62, fit: BoxFit.cover),
              ),
              
              // FIXED: Expanded Search Bar (no free space)
              Expanded(
                child: TextField(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage()));
                  },
                  style: GoogleFonts.jost(fontSize: 16, fontWeight: FontWeight.w400),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[500],
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.search),
                    constraints: BoxConstraints(maxHeight: 45),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 9),
            ],
          ),
          
          SizedBox(height: 8),
          
          // FIXED: Location and Notification in same row
          Row(
            children: [
              // FIXED: Location Field - aligned properly
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LocationsPage()));
                  },
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(Icons.location_on_outlined, color: Color(0xFF9CA3AF), size: 20),
                        ),
                        Expanded(
                          child: Text(
                            homeProvider.userLocationAddress ?? 'Saddar, Karachi',
                            style: GoogleFonts.jost(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(Icons.keyboard_arrow_right, color: Color(0xFF9CA3AF), size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 9),
              
              // FIXED: Notification Bell - aligned with location
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage()));
                },
                child: Container(
                  height: 45,
                  width: 45,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!)
                  ),
                  child: SvgPicture.asset('assets/icons/Notification.svg',
                    height: 40, width: 40, fit: BoxFit.cover),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // FIXED Categories Section with proper spacing and navigation
  Widget _buildCategoriesSection(List<Map<String, dynamic>> categories) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Browse Categories', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              InkWell(
                onTap: () {
                  // FIXED: Navigate to all categories page
                  _navigateToAllCategories();
                },
                child: Text(
                  'See all',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ColorsController.primaryColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // FIXED: Row with proper spacing between categories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: categories.take(5).map((category) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4), // FIXED: Added spacing
                  child: _buildCategoryItem(
                    category['name'] ?? 'Category',
                    category['iconUrl'] ?? 'category',
                    _getColorFromHex(category['color'] ?? '#666666'),
                    onTap: () {
                      // FIXED: Navigate to category with proper hierarchy
                      _navigateToCategoryHierarchy(category);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // FIXED Featured Section with working navigation
  Widget _buildFeaturedSection(List<Map<String, dynamic>> featuredProducts) {
    if (featuredProducts.isEmpty) return SizedBox.shrink();
    
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Featured', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              InkWell(
                onTap: () {
                  // FIXED: Working navigation
                  _navigateToProductList('Featured', featuredProducts);
                },
                child: Text(
                  'See all',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ColorsController.primaryColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              if (featuredProducts.isNotEmpty)
                Expanded(child: _buildProductCard(featuredProducts[0])),
              if (featuredProducts.length > 1) ...[
                SizedBox(width: 12),
                Expanded(child: _buildProductCard(featuredProducts[1])),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // FIXED Personalized Section with working navigation
  Widget _buildPersonalizedSection(List<Map<String, dynamic>> personalizedProducts) {
    if (personalizedProducts.isEmpty) return SizedBox.shrink();
    
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Personalized', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              InkWell(
                onTap: () {
                  // FIXED: Working navigation
                  _navigateToProductList('Personalized', personalizedProducts);
                },
                child: Text(
                  'See all',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ColorsController.primaryColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              if (personalizedProducts.isNotEmpty)
                Expanded(child: _buildProductCard(personalizedProducts[0])),
              if (personalizedProducts.length > 1) ...[
                SizedBox(width: 12),
                Expanded(child: _buildProductCard(personalizedProducts[1])),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // FIXED Product Section with working navigation
  Widget _buildProductSection(String title, List<Map<String, dynamic>> products) {
    if (products.isEmpty) return SizedBox.shrink();
    
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              InkWell(
                onTap: () {
                  // FIXED: Working navigation
                  _navigateToProductList(title, products);
                },
                child: Text(
                  'See all',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ColorsController.primaryColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              if (products.isNotEmpty)
                Expanded(child: _buildProductCard(products[0])),
              if (products.length > 1) ...[
                SizedBox(width: 12),
                Expanded(child: _buildProductCard(products[1])),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // FIXED: Ad Banners Section (keeping your existing code)
  Widget _buildAdBannersSection(List<Map<String, dynamic>> banners) {
    if (banners.isEmpty) return SizedBox.shrink();

    return Container(
      height: 180,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: PageView.builder(
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final banner = banners[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _handleBannerTap(banner),
                child: Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: UniversalImage(
                        imageUrl: banner['imageUrl'] ?? '',
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
                    ),
                    
                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: [0.3, 1.0],
                          ),
                        ),
                      ),
                    ),
                    
                    // Title and Description Overlay
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (banner['title'] != null && banner['title'].toString().isNotEmpty)
                            Text(
                              banner['title'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          
                          if (banner['title'] != null && 
                              banner['title'].toString().isNotEmpty &&
                              banner['description'] != null && 
                              banner['description'].toString().isNotEmpty)
                            SizedBox(height: 4),
                          
                          if (banner['description'] != null && banner['description'].toString().isNotEmpty)
                            Text(
                              banner['description'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // FIXED Category Item with better text handling
  Widget _buildCategoryItem(String title, String icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: UniversalImage(
              imageUrl: icon,
              fit: BoxFit.cover,
              height: 50,
              width: 50,
              errorWidget: Container(
                color: Colors.grey[200],
                child: Icon(Icons.category, size: 30, color: Colors.grey[400]),
              ),
            ),
          ),
          SizedBox(height: 8),
          // FIXED: Better text handling for long names
          Container(
            height: 32, // Fixed height to prevent layout issues
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10, 
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // FIXED Product Card (keeping your existing implementation)
 Widget _buildProductCard(Map<String, dynamic> product) {
  return InkWell(
    onTap: () {
      // Increment view count
      context.read<HomeProvider>().incrementProductView(product['id'] ?? '');
      // Navigate to product detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(productId: product['id'] ?? '')
        )
      );
    },
    child: Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Stack(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: _buildProductImage(product),
                ),
                
                // FIXED: Working Favorite Icon with Consumer
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, child) {
                      final productId = product['id'] ?? '';
                      final isFavorite = favoritesProvider.isFavorite(productId);
                      
                      return GestureDetector(
                        onTap: () async {
                          // Add haptic feedback
                          HapticFeedback.lightImpact();
                          
                          // Toggle favorite
                          await favoritesProvider.toggleFavorite(productId);
                          
                          // Show feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFavorite ? Icons.heart_broken : Icons.favorite,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    isFavorite 
                                      ? 'Removed from favorites' 
                                      : 'Added to favorites',
                                  ),
                                ],
                              ),
                              backgroundColor: isFavorite ? Colors.orange : Colors.red,
                              duration: Duration(milliseconds: 1500),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Negotiable Tag
                if (product['allowPriceNegotiation'] == true)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.yellow[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Negotiable',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content Section
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  product['itemTitle'] ?? 'Product Title',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                
                // Price
                Text(
                  _getFormattedPrice(product['price']),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                
                // Condition and Time Row
                Row(
                  children: [
                    Text(
                      product['condition'] ?? 'Used',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Spacer(),
                    Text(
                      _getTimeSincePosted(product['createdAt']),
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                
                // Location and Views Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product['locationAddress'] ?? 'Location not set',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${product['viewCount'] ?? product['views'] ?? 0} views',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // FIXED Navigation Methods
  void _navigateToAllCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllCategoriesPage(), // You need to create this page
      ),
    );
  }

  void _navigateToCategoryHierarchy(Map<String, dynamic> category) {
    final categoryId = category['id'] ?? '';
    final categoryName = category['name'] ?? '';
    final level = category['level'] ?? 0;

    if (level == 0) {
      // Main category - navigate to subcategories
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubCategoriesPage(
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        ),
      );
    } else if (level == 1) {
      // Subcategory - navigate to sub-subcategories
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubSubCategoriesPage(
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        ),
      );
    } else {
      // Final level - navigate to products
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryProductsPage(
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        ),
      );
    }
  }

  void _navigateToProductList(String title, List<Map<String, dynamic>> products) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListPage(
          title: title,
          products: products,
        ),
      ),
    );
  }

  void _handleBannerTap(Map<String, dynamic> banner) {
    final targetType = banner['targetType'];
    final targetId = banner['targetId'];
    final linkUrl = banner['linkUrl'];
    
    switch (targetType) {
      case 'category':
        if (targetId != null) {
          _navigateToCategoryHierarchy({'id': targetId, 'name': banner['title'] ?? 'Category', 'level': 0});
        }
        break;
      case 'product':
        if (targetId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: targetId),
            ),
          );
        }
        break;
      case 'external':
        if (linkUrl != null) {
          // Use url_launcher package to open external URL
          // launch(linkUrl);
        }
        break;
    }
  }

  // // Helper Methods (keeping your existing implementations)
  // IconData _getIconFromString(String iconName) {
  //   switch (iconName.toLowerCase()) {
  //     case 'phone_android':
  //     case 'mobile':
  //     case 'smartphone':
  //       return Icons.phone_android;
  //     case 'home':
  //     case 'house':
  //     case 'property':
  //       return Icons.home;
  //     case 'computer':
  //     case 'desktop':
  //       return Icons.computer;
  //     case 'kitchen':
  //     case 'appliances':
  //       return Icons.kitchen;
  //     case 'laptop':
  //       return Icons.laptop;
  //     case 'car':
  //     case 'vehicle':
  //       return Icons.directions_car;
  //     case 'camera':
  //       return Icons.camera_alt;
  //     case 'headphones':
  //       return Icons.headphones;
  //     case 'tv':
  //       return Icons.tv;
  //     case 'sports':
  //       return Icons.sports_soccer;
  //     default: 
  //       return Icons.category;
  //   }
  // }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    final imageUrls = product['imageUrls'] as List<dynamic>?;
    
    if (imageUrls != null && imageUrls.isNotEmpty) {
      return UniversalImage(
        imageUrl: imageUrls.first.toString(),
        fit: BoxFit.cover,
        height: 170,
        width: double.infinity,
        errorWidget: Container(
          color: Colors.grey[200],
          child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
      );
    }
  }

  String _getFormattedPrice(dynamic price) {
    if (price == null) return 'Price not set';
    
    try {
      final priceValue = price is num ? price.toDouble() : double.parse(price.toString());
      return 'PKR ${priceValue.toStringAsFixed(0)}';
    } catch (e) {
      return 'Price not set';
    }
  }

  String _getTimeSincePosted(dynamic createdAt) {
    if (createdAt == null) return 'Recently';
    
    try {
      DateTime postDate;
      if (createdAt is Timestamp) {
        postDate = createdAt.toDate();
      } else if (createdAt is DateTime) {
        postDate = createdAt;
      } else {
        return 'Recently';
      }
      
      final now = DateTime.now();
      final difference = now.difference(postDate);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}