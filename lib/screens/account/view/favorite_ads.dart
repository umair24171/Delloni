// screens/favorite_ads.dart - Complete Implementation with Backend
import 'package:arabicmarketplace/screens/account/controller/favorite_provider.dart';
import 'package:arabicmarketplace/screens/custom_bottom_bar.dart';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onBackground),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
           '${AppLocalizations.favouriteAds.tr()}',
            style: GoogleFonts.jost(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
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
                        icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onBackground),
                        onPressed: () => _showSearchDialog(provider),
                      ),
                      IconButton(
                        icon: Icon(Icons.clear_all, color: Theme.of(context).colorScheme.error),
                        onPressed: () => _showClearAllDialog(provider),
                      ),
                    ],
                    IconButton(
                      icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onBackground),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.error),
                    ),
                    SizedBox(height: 16),
                    Text(
                      AppLocalizations.loadingYourAds.tr(),
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                    SizedBox(height: 16),
                    Text(
                      provider.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refreshFavorites(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: Text(AppLocalizations.retry.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onError)),
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
                    color: Theme.of(context).colorScheme.error, // Dark red/maroon
                  ),
                ),
                // Light peach heart (top right)
                Positioned(
                  right: 30,
                  top: 20,
                  child: Icon(
                    Icons.favorite,
                    size: 70,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // Light peach
                  ),
                ),
                // Bright red heart (center bottom, overlapping)
                Positioned(
                  left: 70,
                  top: 55,
                  child: Icon(
                    Icons.favorite,
                    size: 100,
                    color: Theme.of(context).colorScheme.error, // Bright red
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Main text
          Text(
            AppLocalizations.noFavoritesYet.tr(),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            AppLocalizations.collectAllThingsYouLike.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
            icon: Icon(Icons.shopping_bag, color: Theme.of(context).colorScheme.onPrimary),
            label: Text(
              AppLocalizations.browseCategories.tr(), // Or add a new key for 'Browse Products'
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
      color: Theme.of(context).colorScheme.error,
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
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
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: ad.imageUrls.isNotEmpty
                          ? Image.network(
                              ad.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(Icons.image, size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                );
                              },
                            )
                          : Center(
                              child: Icon(Icons.image, size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            ),
                    ),
                  ),
                  
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: Theme.of(context).colorScheme.error,
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
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppLocalizations.negotiable.tr(),
                          style: GoogleFonts.jost(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onPrimary,
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
                      color: Theme.of(context).colorScheme.onBackground,
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                      SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          ad.locationAddress ?? AppLocalizations.locationNotSet.tr(),
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                      Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      SizedBox(width: 2),
                      Text(
                        ad.getTimeSincePosted(),
                        style: GoogleFonts.jost(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
            AppLocalizations.removedFromFavorites.tr(),
            style: GoogleFonts.jost(fontSize: 14),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.removeFavoriteFailed.tr(),
            style: GoogleFonts.jost(fontSize: 14),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
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
            Icon(Icons.warning, color: Theme.of(context).colorScheme.error, size: 24),
            SizedBox(width: 8),
            Text(
              AppLocalizations.clearAllFavorites.tr(),
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.areYouSureYouWantToRemoveAllItemsFromYourFavorites.tr(),
          style: GoogleFonts.jost(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.cancel.tr(),
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    success ? AppLocalizations.allFavoritesCleared.tr() : AppLocalizations.clearFavoritesFailed.tr(),
                    style: GoogleFonts.jost(fontSize: 14),
                  ),
                  backgroundColor: success ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Text(
              AppLocalizations.clearAll.tr(),
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.error,
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
            Icon(Icons.search, color: Theme.of(context).colorScheme.error, size: 24),
            SizedBox(width: 8),
            Text(
              AppLocalizations.searchFavorites.tr(),
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: _searchController,
          style: GoogleFonts.jost(fontSize: 14),
          decoration: InputDecoration(
            hintText: AppLocalizations.searchYourFavoriteProducts.tr(),
            hintStyle: GoogleFonts.jost(fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.error),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.cancel.tr(),
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
              AppLocalizations.search.tr(),
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.error,
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
          '${AppLocalizations.searchResults.tr()} (${results.length})',
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
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
                      Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      SizedBox(height: 16),
                      Text(
                        AppLocalizations.noFavoritesFound.tr(),
                        style: GoogleFonts.jost(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: ad.imageUrls.isNotEmpty
                              ? Image.network(
                                  ad.imageUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.image, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5));
                                  },
                                )
                              : Icon(Icons.image, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
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
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(Icons.favorite, color: Theme.of(context).colorScheme.error, size: 16),
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
              AppLocalizations.close.tr(),
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}