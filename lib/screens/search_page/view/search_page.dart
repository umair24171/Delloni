
import 'package:arabicmarketplace/screens/categories_selection_page/view/categories_selection_page.dart';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:arabicmarketplace/screens/notifications/controller/saved_search_provider.dart';
import 'package:arabicmarketplace/screens/notifications/view/notification_saved_search_page.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:arabicmarketplace/screens/search_page/controller/search_provider.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_page_filter.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_results_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Add other necessary imports for your models and pages
// Make sure to import SearchResultsPage
// import 'search_results_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
// Add other necessary imports for your models and pages
// Make sure to import SearchResultsPage
// import 'search_results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key, this.isMain = false}) : super(key: key);
  final bool isMain;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showResults = false;
  
  // Add these for dynamic categories
  List<Map<String, dynamic>> _popularCategories = [];
  List<Map<String, dynamic>> _allCategories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    // Auto focus to show keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    // Load categories dynamically
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // NEW: Load categories dynamically from Firestore
  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoadingCategories = true;
      });

      // Load all categories for navigation
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      _allCategories = categoriesSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Get popular categories (parent categories with high priority)
      _popularCategories = _allCategories
          .where((cat) => cat['level'] == 0) // Parent categories only
          .toList();

      // Sort by priority and take top categories
      _popularCategories.sort((a, b) {
        final priorityA = a['priority'] ?? 0;
        final priorityB = b['priority'] ?? 0;
        return priorityB.compareTo(priorityA);
      });

      // Take top 8 popular categories
      _popularCategories = _popularCategories.take(8).toList();

      setState(() {
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);
      searchProvider.performImmediateSearch(query);
      setState(() {
        _showResults = true;
      });
    }
  }

  void _onSearchChanged(String query) {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.updateSearchQuery(query);
    
    setState(() {
      _showResults = query.trim().isNotEmpty;
    });
  }

  void _showSaveSearchDialog() {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    
    // Check if there's something to save
    if (searchProvider.searchQuery.isEmpty && !searchProvider.hasFilters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a search query or apply filters first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => SaveSearchDialog(
        currentQuery: searchProvider.searchQuery,
        currentFilters: searchProvider.filters,
      ),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search saved! You\'ll get notified of new matches.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // NEW: Navigate to category selection page
  Future<void> _navigateToCategorySelection(String? initialCategoryId, String categoryName) async {
    try {
      // Get main categories (level 0)
      final mainCategories = _allCategories
          .where((cat) => cat['level'] == 0)
          .toList();

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategorySelectionPage(
            categories: _allCategories,
            mainCategories: mainCategories,
            selectedMainCategoryId: initialCategoryId,
            isForSearch: true, // Enable search mode for "Select All" options
          ),
        ),
      );

      if (result != null) {
        // Handle the category selection result
        final finalCategoryId = result['finalCategoryId'];
        final finalCategoryName = result['categoryName'];
        final isSelectAll = result['isSelectAll'] ?? false;

        // Create filters with selected category
        final searchProvider = Provider.of<SearchProvider>(context, listen: false);
        SearchFilters newFilters = searchProvider.filters.copyWith(
          selectedCategory: finalCategoryId,
        );

        // Navigate to SearchResultsPage with the selected category
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchResultsPage(
              filters: newFilters,
              initialQuery: finalCategoryName,
              categoryName: finalCategoryName,
            ),
          ),
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSelectAll 
                ? 'Searching in all subcategories of $finalCategoryName'
                : 'Searching in $finalCategoryName',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error navigating to category selection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading categories: $e'),
          backgroundColor: Colors.red,
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
        leading: widget.isMain ? null : IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20,
          ),
        ),
        
        title: Text(
          '${AppLocalizations.search.tr()}',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: widget.isMain,
        actions: [
          // Add saved searches button
          Consumer<SavedSearchProvider>(
            builder: (context, provider, child) {
              final count = provider.savedSearches.length;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.bookmark_border, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedSearchesPage(),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Field with Filter Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
                          onChanged: _onSearchChanged,
                          onSubmitted: _performSearch,
                          decoration: InputDecoration(
                            hintText: '${AppLocalizations.findCarsMobiles.tr()}',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                                    onPressed: () {
                                      _searchController.clear();
                                      searchProvider.clearSearch();
                                      setState(() {
                                        _showResults = false;
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        final filters = await showModalBottomSheet<SearchFilters>(
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
                        if (filters != null) {
                          print('Filters received: ${filters.selectedCategory}, ${filters.minPrice}, ${filters.maxPrice}'); // Debug log
                          
                          // Get the category name for display
                          String? categoryName;
                          if (filters.selectedCategory != null) {
                            try {
                              final doc = await FirebaseFirestore.instance
                                  .collection('categories')
                                  .doc(filters.selectedCategory!)
                                  .get();
                              if (doc.exists) {
                                categoryName = doc.data()?['name'];
                              }
                            } catch (e) {
                              print('Error getting category name: $e');
                            }
                          }
                          
                          // Navigate to SearchResultsPage with filters
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchResultsPage(
                                filters: filters,
                                initialQuery: _searchController.text.trim(),
                                categoryName: categoryName,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: searchProvider.hasFilters 
                              ? const Color(0xFF0D5E2A) 
                              : const Color(0xFF0D5E2A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(
                                Icons.tune,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            if (searchProvider.hasFilters)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Show search results or default content
                Expanded(
                  child: _showResults ? _buildSearchResults(searchProvider) : _buildDefaultContent(searchProvider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(SearchProvider searchProvider) {
    if (searchProvider.isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0D5E2A),
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
              onPressed: () => _performSearch(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5E2A),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!searchProvider.hasResults) {
      return _buildNoResults();
    }

    return ListView(
      children: [
        // Categories section
        if (searchProvider.categoryResults.isNotEmpty) ...[
          Text(
            '${AppLocalizations.categories.tr()}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...searchProvider.categoryResults.map((category) => _buildCategoryResultItem(category)),
          const SizedBox(height: 24),
        ],
        
        // Products section
        if (searchProvider.searchResults.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Products (${searchProvider.searchResults.length})',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  // Save search button
                  if (searchProvider.searchQuery.isNotEmpty || searchProvider.hasFilters)
                    TextButton.icon(
                      onPressed: _showSaveSearchDialog,
                      icon: const Icon(Icons.bookmark_add, size: 16),
                      label: const Text('Save'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0D5E2A),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  // Clear filters button
                  if (searchProvider.hasFilters)
                    TextButton(
                      onPressed: () => searchProvider.clearFilters(),
                      child: Text(
                        'Clear filters',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...searchProvider.searchResults.map((product) => _buildProductResultItem(product)),
        ],
      ],
    );
  }

  Widget _buildNoResults() {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords or check your filters',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              
              // Save search option for no results
              if (searchProvider.searchQuery.isNotEmpty || searchProvider.hasFilters) ...[
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultContent(SearchProvider searchProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent search section
          if (searchProvider.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppLocalizations.recentSearch.tr()}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () => searchProvider.clearRecentSearches(),
                  child: Text(
                    '${AppLocalizations.clearAll.tr()}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...searchProvider.recentSearches.map((search) => _buildSearchItem(search, searchProvider)),
            const SizedBox(height: 24),
          ],
          
          // Popular Categories section - NOW DYNAMIC
          Text(
            '${AppLocalizations.popularCategories.tr()}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // UPDATED: Dynamic category items
          if (_isLoadingCategories)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  color: Color(0xFF0D5E2A),
                ),
              ),
            )
          else if (_popularCategories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No categories available',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ..._popularCategories.map((category) => _buildCategoryItem(
              category['name'] ?? 'Unknown Category',
              category['id'],
            )),
        ],
      ),
    );
  }

  Widget _buildSearchItem(String text, SearchProvider searchProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          _searchController.text = text;
          _performSearch(text);
        },
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            IconButton(
              onPressed: () => searchProvider.removeFromRecentSearches(text),
              icon: const Icon(
                Icons.close,
                size: 18,
                color: Colors.grey,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
  
  // UPDATED: Category item with navigation to subcategory selection
  Widget _buildCategoryItem(String text, String? categoryId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          // Navigate to category selection page for subcategory selection
          await _navigateToCategorySelection(categoryId, text);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5E2A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.category,
                  color: const Color(0xFF0D5E2A),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Category result item with navigation to subcategory selection
  Widget _buildCategoryResultItem(CategoryModel category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          // Navigate to category selection page for subcategory selection
          await _navigateToCategorySelection(category.id, category.name);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5E2A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.category,
                  color: const Color(0xFF0D5E2A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Tap to browse category',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductResultItem(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to product details
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
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
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
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.yellow[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${AppLocalizations.negotiable.tr()}',
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
                      product.title ?? 'No Title',
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
                      '\$${product.price?.toStringAsFixed(2) ?? '0.00'}',
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
                          product.condition ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 12, 
                            color: Colors.grey[600]
                          ),
                        ),
                        Spacer(),
                        Text(
                          _getTimeSincePosted(product.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 12, 
                            color: Colors.grey[600]
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    
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