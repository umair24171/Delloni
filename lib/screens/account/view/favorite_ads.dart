// screens/favorite_ads.dart - Complete Implementation with Backend
import 'package:arabicmarketplace/screens/account/controller/favorite_provider.dart';
import 'package:arabicmarketplace/screens/custom_bottom_bar.dart';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
class FavoriteAds extends StatefulWidget {
  const FavoriteAds({super.key});

  @override
  State<FavoriteAds> createState() => _FavoriteAdsState();
}

class _FavoriteAdsState extends State<FavoriteAds> {
  late FavoritesProvider _favoritesProvider;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _favoritesProvider = FavoritesProvider();
  }

  @override
  void dispose() {
    _favoritesProvider.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _favoritesProvider,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Favourite Ads',
            style: GoogleFonts.jost(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: false,
          actions: [
            Consumer<FavoritesProvider>(
              builder: (context, provider, child) {
                return Row(
                  children: [
                    if (provider.favoriteAds.isNotEmpty) ...[
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.black),
                        onPressed: () => _showSearchDialog(provider),
                      ),
                      IconButton(
                        icon: Icon(Icons.clear_all, color: Colors.red),
                        onPressed: () => _showClearAllDialog(provider),
                      ),
                    ],
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.black),
                      onPressed: provider.isLoading ? null : () => provider.refreshFavorites(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer<FavoritesProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1744)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading your favorites...',
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      provider.error!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refreshFavorites(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF1744),
                      ),
                      child: Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            if (provider.favoriteAds.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                // // Stats Section
                // _buildFavoriteStats(provider),
                
                // Favorites List
                Expanded(
                  child: _buildFavoritesList(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hearts illustration
          Container(
            width: 240,
            height: 180,
            child: Stack(
              children: [
                // Dark red heart (top left)
                Positioned(
                  left: 30,
                  top: 20,
                  child: Icon(
                    Icons.favorite,
                    size: 70,
                    color: Color(0xFF7A1E2B), // Dark red/maroon
                  ),
                ),
                // Light peach heart (top right)
                Positioned(
                  right: 30,
                  top: 20,
                  child: Icon(
                    Icons.favorite,
                    size: 70,
                    color: Color(0xFFFFB299), // Light peach
                  ),
                ),
                // Bright red heart (center bottom, overlapping)
                Positioned(
                  left: 70,
                  top: 55,
                  child: Icon(
                    Icons.favorite,
                    size: 100,
                    color: Color(0xFFFF1744), // Bright red
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Main text
          Text(
            'you haven\'t liked anything yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            'collect all things you like in\none place',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          // Browse Products Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => CustomBottomNavigationBar(), // Replace with your product listing screen
              ));
            
            },
            icon: Icon(Icons.shopping_bag, color: Colors.white),
            label: Text(
              'Browse Products',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF1744),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildFavoriteStats(FavoritesProvider provider) {
  //   final stats = provider.getFavoriteStats();
    
  //   return Container(
  //     margin: EdgeInsets.all(16),
  //     padding: EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [
  //           Color(0xFFFF1744).withOpacity(0.1),
  //           Color(0xFFFFB299).withOpacity(0.1),
  //         ],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Color(0xFFFF1744).withOpacity(0.2)),
  //     ),
  //     child: Column(
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.favorite, color: Color(0xFFFF1744), size: 20),
  //             SizedBox(width: 8),
  //             Text(
  //               'Your Favorites Collection',
  //               style: GoogleFonts.jost(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w600,
  //                 color: Colors.black,
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 12),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
  //           children: [
  //             _buildStatItem('Total Items', stats['total'], Color(0xFFFF1744)),
  //             _buildStatItem('Categories', (stats['categories'] as Map).length, Color(0xFF7A1E2B)),
  //             _buildStatItem(
  //               'Total Value', 
  //               _formatTotalValue(stats['totalValue']), 
  //               Color(0xFFFFB299),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatItem(String label, dynamic count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatTotalValue(double value) {
    if (value >= 10000000) {
      return 'PKR ${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return 'PKR ${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return 'PKR ${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return 'PKR ${value.toStringAsFixed(0)}';
    }
  }

  Widget _buildFavoritesList(FavoritesProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.refreshFavorites(),
      color: Color(0xFFFF1744),
      child: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: provider.favoriteAds.length,
        itemBuilder: (context, index) {
          final ad = provider.favoriteAds[index];
          return _buildFavoriteCard(ad, provider);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(ProductModel ad, FavoritesProvider provider) {
    return Container(
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
              builder: (context) => ProductDetailScreen(productId: ad.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: ad.imageUrls.isNotEmpty
                          ? Image.network(
                              ad.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
                                );
                              },
                            )
                          : Center(
                              child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
                            ),
                    ),
                  ),
                  
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                          Icons.favorite,
                          color: Color(0xFFFF1744),
                          size: 20,
                        ),
                        onPressed: () => _removeFavorite(ad, provider),
                      ),
                    ),
                  ),
                  
                  // Negotiable Tag
                  if (ad.allowPriceNegotiation)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.yellow[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Negotiable',
                          style: GoogleFonts.jost(
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
            
            // Product Details
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    ad.getFormattedPrice(),
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[600]),
                      SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          ad.locationAddress ?? 'Location not set',
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                      SizedBox(width: 2),
                      Text(
                        ad.getTimeSincePosted(),
                        style: GoogleFonts.jost(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
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

  void _removeFavorite(ProductModel ad, FavoritesProvider provider) async {
    final success = await provider.removeFavorite(ad.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Removed from favorites',
            style: GoogleFonts.jost(fontSize: 14),
          ),
          backgroundColor: Color(0xFFFF1744),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to remove from favorites',
            style: GoogleFonts.jost(fontSize: 14),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showClearAllDialog(FavoritesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              'Clear All Favorites',
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove all items from your favorites? This action cannot be undone.',
          style: GoogleFonts.jost(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.clearAllFavorites();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'All favorites cleared' : 'Failed to clear favorites',
                    style: GoogleFonts.jost(fontSize: 14),
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(FavoritesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.search, color: Color(0xFFFF1744), size: 24),
            SizedBox(width: 8),
            Text(
              'Search Favorites',
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: _searchController,
          style: GoogleFonts.jost(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search your favorite products...',
            hintStyle: GoogleFonts.jost(fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: Icon(Icons.search, color: Color(0xFFFF1744)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final results = provider.searchFavorites(_searchController.text);
              _showSearchResults(results);
            },
            child: Text(
              'Search',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFF1744),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(List<ProductModel> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Search Results (${results.length})',
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No favorites found',
                        style: GoogleFonts.jost(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final ad = results[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: ad.imageUrls.isNotEmpty
                              ? Image.network(
                                  ad.imageUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.image, size: 20, color: Colors.grey[400]);
                                  },
                                )
                              : Icon(Icons.image, size: 20, color: Colors.grey[400]),
                        ),
                      ),
                      title: Text(
                        ad.title,
                        style: GoogleFonts.jost(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        ad.getFormattedPrice(),
                        style: GoogleFonts.jost(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(Icons.favorite, color: Color(0xFFFF1744), size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(productId: ad.id),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}