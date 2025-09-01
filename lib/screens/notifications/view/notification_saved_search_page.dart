// screens/saved_searches_page.dart
import 'package:arabicmarketplace/controller/notifications_helper.dart';
import 'package:arabicmarketplace/screens/notifications/controller/saved_search_provider.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_page.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_results_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:arabicmarketplace/screens/product_detail/model/product_detail_model.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:arabicmarketplace/screens/search_page/controller/search_provider.dart';
class SavedSearchesPage extends StatefulWidget {
  const SavedSearchesPage({Key? key}) : super(key: key);

  @override
  State<SavedSearchesPage> createState() => _SavedSearchesPageState();
}

class _SavedSearchesPageState extends State<SavedSearchesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        // backgroundColor: Colors.white,
       surfaceTintColor:Theme.of(context).appBarTheme.backgroundColor ,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,  size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saved Searches'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            // color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<SavedSearchProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xff014700),
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading saved searches'.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadSavedSearches(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff014700),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:  Text('Retry'.tr()),
                  ),
                ],
              ),
            );
          }

          if (provider.savedSearches.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Header with count
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bookmark,
                      color: const Color(0xff014700),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${provider.savedSearches.length} ${"Saved Search".tr()} ${provider.savedSearches.length == 1 ? '' : 'es'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Swipe to delete'.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // List of saved searches
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.savedSearches.length,
                  itemBuilder: (context, index) {
                    final savedSearch = provider.savedSearches[index];
                    return _buildSavedSearchCard(savedSearch, provider, index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No saved searches yet'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Save your search filters to get notified when new matching items are posted'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.search, size: 20),
                label: Text(
                  'Start Searching'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff014700),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedSearchCard(SavedSearchModel savedSearch, SavedSearchProvider provider, int index) {
    return Dismissible(
      key: Key(savedSearch.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(savedSearch);
      },
      onDismissed: (direction) {
        provider.deleteSavedSearch(savedSearch.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\"${savedSearch.name}\" ${"deleted".tr()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _executeSavedSearch(savedSearch),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              // color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with name and switch
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          savedSearch.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            // color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (savedSearch.matchCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff014700).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${savedSearch.matchCount}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff014700),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: savedSearch.isActive,
                          onChanged: (value) {
                            provider.updateSavedSearch(
                              savedSearch.id, 
                              isActive: value,
                            );
                          },
                          activeColor: const Color(0xff014700),
                          inactiveThumbColor: Colors.grey[400],
                          inactiveTrackColor: Colors.grey[200],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Search criteria
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      savedSearch.getDisplayText(),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Footer with date and status
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${"Created".tr()} ${_formatDate(savedSearch.createdAt)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: savedSearch.isActive 
                              ? const Color(0xff014700).withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              savedSearch.isActive 
                                  ? Icons.notifications_active
                                  : Icons.notifications_off,
                              size: 12,
                              color: savedSearch.isActive 
                                  ? const Color(0xff014700)
                                  : Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              savedSearch.isActive ? 'Active'.tr() : 'Paused'.tr(),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: savedSearch.isActive 
                                    ? const Color(0xff014700)
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showEditDialog(savedSearch, provider),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(SavedSearchModel savedSearch) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness != Brightness.dark
            ? Colors.white
            : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Delete Saved Search'.tr(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '${"Are you sure you want to delete".tr()} \"${savedSearch.name}\"${"?".tr()} ${"This action cannot be undone.".tr()}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel'.tr(),
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete'.tr(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _executeSavedSearch(SavedSearchModel savedSearch) {
    // Convert SavedSearchModel to SearchFilters
    final filters = SearchFilters(
      selectedCategory: savedSearch.categoryId,
      minPrice: savedSearch.minPrice,
      maxPrice: savedSearch.maxPrice,
      adType: savedSearch.adType,
      latitude: savedSearch.latitude,
      longitude: savedSearch.longitude,
      radiusKm: savedSearch.radiusKm,
      location: savedSearch.cityName,
      cityId: savedSearch.cityId,
      cityName: savedSearch.cityName,
      districtId: savedSearch.districtId,
      districtName: savedSearch.districtName,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          filters: filters,
          initialQuery: savedSearch.query,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now'.tr();
    }
  }

  void _showEditDialog(SavedSearchModel savedSearch, SavedSearchProvider provider) {
    final controller = TextEditingController(text: savedSearch.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness != Brightness.dark
            ? Colors.white
            : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Edit Search Name'.tr(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a new name for your saved search:'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search name'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLength: 50,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel'.tr(),
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.updateSavedSearch(
                  savedSearch.id, 
                  name: controller.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Search name updated'.tr(),style: TextStyle(color: Theme.of(context).colorScheme.onBackground),),
                    backgroundColor: const Color(0xff014700),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff014700),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save'.tr(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// screens/saved_search_results_page.dart
class SavedSearchResultsPage extends StatefulWidget {
  final SavedSearchModel savedSearch;

  const SavedSearchResultsPage({
    Key? key,
    required this.savedSearch,
  }) : super(key: key);

  @override
  State<SavedSearchResultsPage> createState() => _SavedSearchResultsPageState();
}

class _SavedSearchResultsPageState extends State<SavedSearchResultsPage> {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final provider = Provider.of<SavedSearchProvider>(context, listen: false);
      final results = await provider.executeSavedSearch(widget.savedSearch);
      
      setState(() {
        _products = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.savedSearch.name,
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              '${_products.length} ${"results".tr()}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadResults,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search criteria display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Criteria:'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.savedSearch.getDisplayText(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading results'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadResults,
              child:  Text('Retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: product.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.image, color: Colors.grey[400]),
                          ),
                        )
                      : Icon(Icons.image, color: Colors.grey[400]),
                ),
                const SizedBox(width: 12),
                
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.getFormattedPrice(),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff014700),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (product.locationAddress != null)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.locationAddress!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        product.getTimeSincePosted(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// widgets/save_search_dialog.dart
class SaveSearchDialog extends StatefulWidget {
  final String currentQuery;
  final SearchFilters currentFilters;

  const SaveSearchDialog({
    Key? key,
    required this.currentQuery,
    required this.currentFilters,
  }) : super(key: key);

  @override
  State<SaveSearchDialog> createState() => _SaveSearchDialogState();
}

class _SaveSearchDialogState extends State<SaveSearchDialog> {
  final _nameController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Generate a default name based on the search
    _nameController.text = '';
  }

  String _generateDefaultName() {
    List<String> parts = [];
    
    if (widget.currentQuery.isNotEmpty) {
      parts.add(widget.currentQuery);
    }
    
    if (widget.currentFilters.selectedCategory != null) {
      parts.add(widget.currentFilters.selectedCategory!);
    }
    
    if (widget.currentFilters.cityName != null) {
      parts.add(widget.currentFilters.cityName!);
    }
    
    if (parts.isEmpty) {
      return 'My Search'.tr();
    }
    
    return parts.join(' in ');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).brightness != Brightness.dark
          ? Colors.white
          : Colors.black,
      title:  Text('Save Search'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text('Give your search a name:'.tr()),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter search name'.tr(),
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            maxLength: 50,
          ),
          // const SizedBox(height: 16),
          // Container(
          //   padding: const EdgeInsets.all(12),
          //   decoration: BoxDecoration(
          //     color: Colors.grey[50],
          //     borderRadius: BorderRadius.circular(8),
          //     border: Border.all(color: Colors.grey[300]!),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         'Search criteria:'.tr(),
          //         style: GoogleFonts.poppins(
          //           fontSize: 12,
          //           fontWeight: FontWeight.w500,
          //           color: Colors.grey[600],
          //         ),
          //       ),
          //       const SizedBox(height: 4),
          //       Text(
          //         _getSearchCriteriaText(),
          //         style: GoogleFonts.poppins(
          //           fontSize: 14,
          //           color: Colors.grey[700],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                size: 16,
                color: Colors.green[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You\'ll get notified when new items match this search'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child:  Text('Cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveSearch,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              :  Text('Save'.tr()),
        ),
      ],
    );
  }

  String _getSearchCriteriaText() {
    List<String> parts = [];
    
    if (widget.currentQuery.isNotEmpty) {
      parts.add('"${widget.currentQuery}"');
    }
    
    if (widget.currentFilters.selectedCategory != null) {
      parts.add('in ${widget.currentFilters.selectedCategory}');
    }
    
    if (widget.currentFilters.minPrice != null || widget.currentFilters.maxPrice != null) {
      if (widget.currentFilters.minPrice != null && widget.currentFilters.maxPrice != null) {
        parts.add('Rs ${widget.currentFilters.minPrice!.toStringAsFixed(0)} - Rs ${widget.currentFilters.maxPrice!.toStringAsFixed(0)}');
      } else if (widget.currentFilters.minPrice != null) {
        parts.add('above Rs ${widget.currentFilters.minPrice!.toStringAsFixed(0)}');
      } else if (widget.currentFilters.maxPrice != null) {
        parts.add('below Rs ${widget.currentFilters.maxPrice!.toStringAsFixed(0)}');
      }
    }
    
    if (widget.currentFilters.cityName != null) {
      parts.add('in ${widget.currentFilters.cityName}');
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : 'All items';
  }

  Future<void> _saveSearch() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a name'.tr();
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final provider = Provider.of<SavedSearchProvider>(context, listen: false);
      final success = await provider.saveCurrentSearch(
        name: _nameController.text.trim(),
        query: widget.currentQuery,
        filters: widget.currentFilters,
      );

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search saved successfully!'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error = 'Failed to save search';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
    }
  }
}