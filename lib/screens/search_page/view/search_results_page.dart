import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:arabicmarketplace/screens/notifications/view/notification_saved_search_page.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_page_filter.dart';
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
  
  const SearchResultsPage({
    Key? key, 
    required this.filters,
    this.initialQuery,
  }) : super(key: key);

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late SearchProvider _searchProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSearch();
  }

  void _initializeSearch() async {
    // Use existing SearchProvider or create new one
    _searchProvider = Provider.of<SearchProvider>(context, listen: false);
    
    // Apply filters and execute search
    _searchProvider.updateFilters(widget.filters);
    
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      await _searchProvider.performImmediateSearch(widget.initialQuery);
    } else {
      // Trigger search with current filters
      await _searchProvider.performImmediateSearch('');
    }
    
    setState(() {
      _isInitialized = true;
    });
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
          'Search Results',
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
              }
            },
            icon: const Icon(Icons.tune, color: Colors.black),
          ),
          
          // Save search button
          IconButton(
            onPressed: _showSaveSearchDialog,
            icon: const Icon(Icons.bookmark_add, color: Colors.black),
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Summary Section
                    _buildSearchSummary(searchProvider),
                    
                    // Active Filters Section
                    if (searchProvider.hasFilters) _buildActiveFilters(searchProvider),
                    
                    // Results Section
                    Expanded(child: _buildResultsSection(searchProvider)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSearchSummary(SearchProvider searchProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  searchProvider.getSearchSummary(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${searchProvider.searchResults.length} results found',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
              if (searchProvider.searchResults.isNotEmpty)
                TextButton.icon(
                  onPressed: _showSaveSearchDialog,
                  icon: const Icon(Icons.bookmark_add, size: 16),
                  label: const Text('Save'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(SearchProvider searchProvider) {
    final filters = searchProvider.filters;
    final activeFilters = <Widget>[];

    if (filters.selectedCategory != null) {
      activeFilters.add(_buildFilterChip(
        'Category: ${filters.selectedCategory}',
        () => searchProvider.clearFilters(),
      ));
    }

    if (filters.cityName != null) {
      String locationText = filters.districtName != null 
          ? '${filters.districtName}, ${filters.cityName}'
          : filters.cityName!;
      activeFilters.add(_buildFilterChip(
        'Location: $locationText',
        () => searchProvider.clearFilters(),
      ));
    }

    if (filters.minPrice != null || filters.maxPrice != null) {
      String priceText = '';
      if (filters.minPrice != null && filters.maxPrice != null) {
        priceText = 'Price: \$${filters.minPrice!.toStringAsFixed(0)} - \$${filters.maxPrice!.toStringAsFixed(0)}';
      } else if (filters.minPrice != null) {
        priceText = 'Min Price: \$${filters.minPrice!.toStringAsFixed(0)}';
      } else if (filters.maxPrice != null) {
        priceText = 'Max Price: \$${filters.maxPrice!.toStringAsFixed(0)}';
      }
      if (priceText.isNotEmpty) {
        activeFilters.add(_buildFilterChip(priceText, () => searchProvider.clearFilters()));
      }
    }

    if (filters.adType != null && filters.adType != 'All') {
      activeFilters.add(_buildFilterChip(
        'Type: ${filters.adType}',
        () => searchProvider.clearFilters(),
      ));
    }

    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                TextButton(
                  onPressed: () => searchProvider.clearFilters(),
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: activeFilters),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        backgroundColor: Colors.blue[100],
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        side: BorderSide(color: Colors.blue[300]!),
      ),
    );
  }

  Widget _buildResultsSection(SearchProvider searchProvider) {
    if (searchProvider.isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0D5E2A)),
            SizedBox(height: 16),
            Text('Searching...'),
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
              'Search Error',
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
              child: const Text('Retry'),
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
              'No Results Found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria or filters',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Save this search to get notified when new items are added',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showSaveSearchDialog,
              icon: const Icon(Icons.bookmark_add, size: 18),
              label: const Text('Save Search'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D5E2A),
                side: const BorderSide(color: Color(0xFF0D5E2A)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchProvider.searchResults.length,
      itemBuilder: (context, index) {
        final product = searchProvider.searchResults[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: product.imageUrls.isNotEmpty
                          ? Image.network(
                              product.imageUrls.first,
                              fit: BoxFit.cover,
                              height: 170,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.image, 
                                    size: 50, 
                                    color: Colors.grey[400]
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image, 
                                size: 50, 
                                color: Colors.grey[400]
                              ),
                            ),
                    ),
                    
                    // Favorite Icon
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    
                    // Negotiable Tag
                    if (product.allowPriceNegotiation)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.yellow[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppLocalizations.negotiable.tr(),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      product.title ?? 'No Title',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    
                    // Price
                    Text(
                      '\$${product.price?.toStringAsFixed(2) ?? '0.00'}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Condition and Time Row
                    Row(
                      children: [
                        Text(
                          product.condition ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 12, 
                            color: Colors.grey[600]
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _getTimeSincePosted(product.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 12, 
                            color: Colors.grey[600]
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Location and Category Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.locationAddress ?? 'Location not set',
                            style: GoogleFonts.poppins(
                              fontSize: 12, 
                              color: Colors.grey[600]
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          product.category ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12, 
                            color: Colors.grey[600]
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