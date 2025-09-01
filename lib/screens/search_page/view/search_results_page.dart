import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:arabicmarketplace/screens/notifications/view/notification_saved_search_page.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_page_filter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabicmarketplace/screens/search_page/controller/search_provider.dart';
import 'package:arabicmarketplace/screens/notifications/controller/saved_search_provider.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
class SearchResultsPage extends StatefulWidget {
  final SearchFilters filters;
  final String? initialQuery;
  final String? categoryName; // ADD: To display category name properly
  
  const SearchResultsPage({
    Key? key, 
    required this.filters,
    this.initialQuery,
    this.categoryName,
  }) : super(key: key);

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late SearchProvider _searchProvider;
  bool _isInitialized = false;
  String? _displayCategoryName;
  ScrollController _scrollController = ScrollController();
  double _bannerOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _displayCategoryName = widget.categoryName;
    
    // Listen to scroll for banner animation
    _scrollController.addListener(() {
      setState(() {
        // Move banner left/right based on scroll position
        _bannerOffset = (_scrollController.offset * 0.1) % 60 - 30;
      });
    });
    
    // Call initialization but don't await it to avoid setState during build
    _initializeSearch();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeSearch() {
    // Use post-frame callback to ensure we're not in the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        
        print('SearchResultsPage initializing with filters: ${widget.filters.selectedCategory}');
        
        // Use existing SearchProvider
        _searchProvider = Provider.of<SearchProvider>(context, listen: false);
        
        // IMPORTANT: Apply filters BEFORE executing search
        print('Applying filters to SearchProvider...');
        _searchProvider.updateFilters(widget.filters);
        
        // If we have a category but no category name, try to get it
        if (widget.filters.selectedCategory != null && _displayCategoryName == null) {
          _displayCategoryName = await _getCategoryName(widget.filters.selectedCategory!);
          print('Loaded category name: $_displayCategoryName');
        }
        
        // IMPORTANT: Execute search with the applied filters
        print('Executing search with query: "${widget.initialQuery ?? ""}"');
        
        if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
          await _searchProvider.performImmediateSearch(widget.initialQuery!);
        } else {
          // For filter-only searches, use empty query to trigger filtered search
          await _searchProvider.performImmediateSearch('');
        }
        
        print('Search completed. Results: ${_searchProvider.searchResults.length}');
        
        // Safe to call setState now
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        print('Error initializing SearchResultsPage: $e');
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    });
  }

  // NEW: Get category name from ID
  Future<String?> _getCategoryName(String categoryId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .get();
      
      if (doc.exists) {
        return doc.data()?['name'];
      }
    } catch (e) {
      print('Error getting category name: $e');
    }
    return null;
  }

  void _showSaveSearchDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SaveSearchDialog(
        currentQuery: widget.initialQuery ?? '',
        currentFilters: widget.filters,
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search saved! You\'ll get notified of new matches.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20,
          ),
        ),
        title: Text(
          'Search Results'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          // Edit filters button
          IconButton(
            onPressed: () async {
              final newFilters = await showModalBottomSheet<SearchFilters>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => FractionallySizedBox(
                  heightFactor: 0.95,
                  child: SearchFilterPage(),
                ),
              );
              
              if (newFilters != null) {
                _searchProvider.updateFilters(newFilters);
                // Re-trigger search with new filters
                await _searchProvider.performImmediateSearch(widget.initialQuery ?? '');
                
                // Update category name if changed
                if (newFilters.selectedCategory != widget.filters.selectedCategory) {
                  _displayCategoryName = await _getCategoryName(newFilters.selectedCategory ?? '');
                  setState(() {});
                }
              }
            },
            icon: const Icon(Icons.tune, color: Colors.black),
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0D5E2A),
              ),
            )
          : Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                return Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact Search Summary Section
                        _buildCompactSearchSummary(searchProvider),
                        
                        // Compact Active Filters Section
                        if (searchProvider.hasFilters) _buildCompactActiveFilters(searchProvider),
                        
                        // Results Section
                        Expanded(child: _buildResultsSection(searchProvider)),
                      ],
                    ),
                    
                    // Floating Save Search Banner (moves with scroll)
                // Replace the existing floating banner section with this updated version

// Floating Save Search Banner (moves with scroll)
Positioned(
  left: 16,
  //  + _bannerOffset,
  right: 16 ,
  // - _bannerOffset,
  bottom: 20,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.green[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green[200]!),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        // Changed from notifications_none to favorite_border (heart icon)
        Icon(Icons.favorite_border, color: Colors.green[700], size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Save Search', // Changed from 'Suche speichern'
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.green[700],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[700],
            borderRadius: BorderRadius.circular(6),
          ),
          child: InkWell(
            onTap: _showSaveSearchDialog,
            child: Text(
              'Save Now', // Changed from 'Jetzt buchen' to be more appropriate
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCompactSearchSummary(SearchProvider searchProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Mehr als ${searchProvider.searchResults.length} ${"results found".tr()}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActiveFilters(SearchProvider searchProvider) {
    final filters = searchProvider.filters;
    final activeFilters = <Widget>[];

    // UPDATED: Show category name instead of ID
    if (filters.selectedCategory != null && _displayCategoryName != null) {
      activeFilters.add(_buildCompactFilterChip(
        _displayCategoryName!,
        () {
          // Create new filters without category
          final newFilters = filters.copyWith(selectedCategory: null);
          searchProvider.updateFilters(newFilters);
          _displayCategoryName = null;
          setState(() {});
        },
      ));
    }

    if (filters.cityName != null) {
      String locationText = filters.districtName != null 
          ? '${filters.districtName}, ${filters.cityName}'
          : filters.cityName!;
      activeFilters.add(_buildCompactFilterChip(
        locationText,
        () {
          // Create new filters without location
          final newFilters = filters.copyWith(
            cityId: null,
            cityName: null,
            districtId: null,
            districtName: null,
            latitude: null,
            longitude: null,
            location: null,
          );
          searchProvider.updateFilters(newFilters);
        },
      ));
    }

    if (filters.minPrice != null || filters.maxPrice != null) {
      String priceText = '';
      if (filters.minPrice != null && filters.maxPrice != null) {
        priceText = '\$${filters.minPrice!.toStringAsFixed(0)} - \$${filters.maxPrice!.toStringAsFixed(0)}';
      } else if (filters.minPrice != null) {
        priceText = 'Min \$${filters.minPrice!.toStringAsFixed(0)}';
      } else if (filters.maxPrice != null) {
        priceText = 'Max \$${filters.maxPrice!.toStringAsFixed(0)}';
      }
      if (priceText.isNotEmpty) {
        activeFilters.add(_buildCompactFilterChip(
          priceText, 
          () {
            // Create new filters without price range
            final newFilters = filters.copyWith(
              minPrice: null,
              maxPrice: null,
            );
            searchProvider.updateFilters(newFilters);
          },
        ));
      }
    }

    if (filters.adType != null && filters.adType != 'All') {
      activeFilters.add(_buildCompactFilterChip(
        filters.adType!,
        () {
          // Create new filters without ad type
          final newFilters = filters.copyWith(adType: 'All');
          searchProvider.updateFilters(newFilters);
        },
      ));
    }

    // Add Filter button as first item
    activeFilters.insert(0, _buildFilterButton());

    if (activeFilters.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: activeFilters),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 16, color: Colors.green[700]),
            const SizedBox(width: 4),
            Text(
              'Filter',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '3',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(SearchProvider searchProvider) {
    if (searchProvider.isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0D5E2A)),
            SizedBox(height: 16),
            Text('Searching...'.tr()),
          ],
        ),
      );
    }

    if (searchProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search Error'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchProvider.error!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initializeSearch(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5E2A),
              ),
              child: Text('Retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (!searchProvider.hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Results Found'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria or filters'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Results with proper padding for floating banner
    return RefreshIndicator(
      onRefresh: () async {
         _initializeSearch();
      },
      child: searchProvider.searchResults.length > 4 
          ? GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Bottom padding for floating banner
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: searchProvider.searchResults.length,
              itemBuilder: (context, index) {
                final product = searchProvider.searchResults[index];
                return _buildProductGridCard(product);
              },
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Bottom padding for floating banner
              itemCount: searchProvider.searchResults.length,
              itemBuilder: (context, index) {
                final product = searchProvider.searchResults[index];
                return _buildProductCard(product);
              },
            ),
    );
  }

  // NEW: Grid card layout matching reference image style
  Widget _buildProductGridCard(ProductModel product) {
    return Container(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id)
            )
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Container with badges
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Stack(
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        child: product.imageUrls.isNotEmpty
                            ? Image.network(
                                product.imageUrls.first,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image, 
                                      size: 30, 
                                      color: Colors.grey[400]
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image, 
                                  size: 30, 
                                  color: Colors.grey[400]
                                ),
                              ),
                      ),
                      
                      // TOP badge (like in reference)
                      if (product.isFeatured == true)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'TOP',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      
                      // Favorite Icon
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                      
                      // Image count badge (bottom right)
                      if (product.imageUrls.length > 1)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${product.imageUrls.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Content Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        product.title ?? 'No Title',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      
                      // Price with negotiation info
                      Row(
                        children: [
                          Text(
                            '\$${product.price?.toStringAsFixed(0) ?? '0'}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          if (product.allowPriceNegotiation)
                            Text(
                              ' VB',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      
                      // Distance and Location
                      Text(
                        '${product.locationAddress?.split(',').first ?? 'Unknown'} (${(product.locationAddress?.split(',').last ?? 0)} km)',
                        style: GoogleFonts.poppins(
                          fontSize: 10, 
                          color: Colors.grey[600]
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Time posted
                      Text(
                        _getTimeSincePosted(product.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 9, 
                          color: Colors.grey[500]
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id)
            )
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Container
              Container(
                width: 120,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                ),
                child: Stack(
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      child: product.imageUrls.isNotEmpty
                          ? Image.network(
                              product.imageUrls.first,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 90,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.image, 
                                    size: 30, 
                                    color: Colors.grey[400]
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image, 
                                size: 30, 
                                color: Colors.grey[400]
                              ),
                            ),
                    ),
                    
                    // TOP badge
                    if (product.isFeatured == true)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'TOP',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    
                    // Favorite Icon
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                    
                    // Image count
                    if (product.imageUrls.length > 1)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${product.imageUrls.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Content Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        product.title ?? 'No Title',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Price and distance row
                      Row(
                        children: [
                          Text(
                            '\$${product.price?.toStringAsFixed(0) ?? '0'}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          if (product.allowPriceNegotiation)
                            Text(
                              ' VB',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const Spacer(),
                          Text(
                              '${(product.locationAddress?.split(',').last ?? 0)} km',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Location and Time Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.locationAddress?.split(',').first ?? 'Unknown location',
                              style: GoogleFonts.poppins(
                                fontSize: 11, 
                                color: Colors.grey[600]
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _getTimeSincePosted(product.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 11, 
                              color: Colors.grey[600]
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeSincePosted(DateTime? createdAt) {
    if (createdAt == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}