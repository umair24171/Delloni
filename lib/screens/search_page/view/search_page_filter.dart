import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/search_page/controller/search_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class SearchFilterPage extends StatefulWidget {
  final Function(SearchFilters)? onFiltersApplied;
  
  const SearchFilterPage({Key? key, this.onFiltersApplied}) : super(key: key);

  @override
  State<SearchFilterPage> createState() => _SearchFilterPageState();
}

class _SearchFilterPageState extends State<SearchFilterPage> {
  final TextEditingController _minRadiusController = TextEditingController();
  final TextEditingController _maxRadiusController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  
  String selectedAdType = 'All';
  String selectedCategory = 'Any';
  String selectedLocation = 'Current Location';
  double? userLatitude;
  double? userLongitude;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _getCurrentLocation();
  }

  void _initializeFilters() {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    final filters = searchProvider.filters;
    
    selectedCategory = filters.selectedCategory ?? 'Any';
    selectedAdType = filters.adType ?? 'All';
    selectedLocation = filters.location ?? 'Current Location';
    userLatitude = filters.latitude;
    userLongitude = filters.longitude;
    
    _minRadiusController.text = filters.minRadius?.toString() ?? '0';
    _maxRadiusController.text = filters.maxRadius?.toString() ?? '50';
    _minPriceController.text = filters.minPrice?.toString() ?? '0';
    _maxPriceController.text = filters.maxPrice?.toString() ?? '100000';
  }

  Future<void> _getCurrentLocation() async {
    if (userLatitude != null && userLongitude != null) return;
    
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        userLatitude = position.latitude;
        userLongitude = position.longitude;
        selectedLocation = 'Current Location';
        _isLoadingLocation = false;
      });
    } catch (e) {
      _showLocationError('Failed to get location: $e');
    }
  }

  void _showLocationError(String message) {
    setState(() {
      _isLoadingLocation = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _minRadiusController.dispose();
    _maxRadiusController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    try {
      final filters = SearchFilters(
        selectedCategory: selectedCategory == 'Any' ? null : selectedCategory,
        minPrice: _parseDouble(_minPriceController.text),
        maxPrice: _parseDouble(_maxPriceController.text),
        minRadius: _parseDouble(_minRadiusController.text),
        maxRadius: _parseDouble(_maxRadiusController.text),
        adType: selectedAdType == 'All' ? null : selectedAdType,
        latitude: userLatitude,
        longitude: userLongitude,
        radiusKm: _parseDouble(_maxRadiusController.text),
        location: selectedLocation,
      );

      // Validate price range
      if (filters.minPrice != null && filters.maxPrice != null && 
          filters.minPrice! > filters.maxPrice!) {
        _showError('Minimum price cannot be greater than maximum price');
        return;
      }

      // Validate radius range
      if (filters.minRadius != null && filters.maxRadius != null && 
          filters.minRadius! > filters.maxRadius!) {
        _showError('Minimum radius cannot be greater than maximum radius');
        return;
      }

      if (widget.onFiltersApplied != null) {
        widget.onFiltersApplied!(filters);
      } else {
        final searchProvider = Provider.of<SearchProvider>(context, listen: false);
        searchProvider.updateFilters(filters);
      }

      Navigator.pop(context);
    } catch (e) {
      _showError('Invalid filter values. Please check your inputs.');
    }
  }

  double? _parseDouble(String value) {
    if (value.trim().isEmpty || value.trim() == '0') return null;
    try {
      return double.parse(value.replaceAll(',', ''));
    } catch (e) {
      return null;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      selectedCategory = 'Any';
      selectedAdType = 'All';
      selectedLocation = 'Current Location';
      _minRadiusController.text = '0';
      _maxRadiusController.text = '50';
      _minPriceController.text = '0';
      _maxPriceController.text = '100000';
    });

    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.clearFilters();
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
            Icons.close,
            color: Colors.black,
            size: 24,
          ),
        ),
        title: Text(
          'Search Filter',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              'Clear all',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Section
                  _buildFilterItem(
                    title: 'Category',
                    subtitle: selectedCategory,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoriesPageForFilter(
                            onCategorySelected: (category) {
                              setState(() {
                                selectedCategory = category;
                              });
                              Navigator.pop(context);
                            },
                            selectedCategory: selectedCategory,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Location Section
                  _buildFilterItem(
                    title: 'Location',
                    subtitle: _isLoadingLocation ? 'Getting location...' : selectedLocation,
                    trailing: _isLoadingLocation 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: _isLoadingLocation ? null : () {
                      _showLocationBottomSheet();
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Radius Section
                  _buildSectionTitle('Search Radius (km)'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Min',
                          controller: _minRadiusController,
                          hint: '0',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Max',
                          controller: _maxRadiusController,
                          hint: '50',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Price Section
                  _buildSectionTitle('Price Range (\$)'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Min',
                          controller: _minPriceController,
                          hint: '0',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Max',
                          controller: _maxPriceController,
                          hint: '100,000',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Ad Type Section
                  _buildSectionTitle('Ad Type'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildAdTypeButton('All'),
                      const SizedBox(width: 12),
                      _buildAdTypeButton('Individual'),
                      const SizedBox(width: 12),
                      _buildAdTypeButton('Company'),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Apply Filters Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, ).copyWith(bottom: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsController.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Apply Filters',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }
  
  Widget _buildFilterItem({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? const Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAdTypeButton(String type) {
    final bool isSelected = selectedAdType == type;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedAdType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? ColorsController.primaryColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              type,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Location',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.my_location, color: Color(0xFF0D5E2A)),
              title: Text('Current Location', style: GoogleFonts.poppins()),
              subtitle: userLatitude != null 
                  ? Text('${userLatitude!.toStringAsFixed(4)}, ${userLongitude!.toStringAsFixed(4)}')
                  : null,
              onTap: () {
                setState(() {
                  selectedLocation = 'Current Location';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_city),
              title: Text('Choose City', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                // You can implement city selection here
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Categories Page for Filter Selection
class CategoriesPageForFilter extends StatefulWidget {
  final Function(String) onCategorySelected;
  final String selectedCategory;
  
  const CategoriesPageForFilter({
    Key? key, 
    required this.onCategorySelected,
    required this.selectedCategory,
  }) : super(key: key);

  @override
  State<CategoriesPageForFilter> createState() => _CategoriesPageForFilterState();
}

class _CategoriesPageForFilterState extends State<CategoriesPageForFilter> {
  final TextEditingController _searchController = TextEditingController();
  List<CategoryItem> filteredCategories = [];
  bool isLoading = true;
  
  // Your original categories with my backend integration
  final List<CategoryItem> categories = [
    // Add "Any" option at the top
    CategoryItem(
      icon: Icons.apps,
      iconColor: const Color(0xFF0D5E2A),
      backgroundColor: Colors.grey[100]!,
      title: 'Any',
      isPopular: true,
      searchKeywords: ['any', 'all'],
    ),
    
    // Popular Categories (your original design)
    CategoryItem(
      icon: Icons.phone_android,
      iconColor: Colors.blue,
      backgroundColor: Colors.grey[800]!,
      title: 'Mobiles',
      isPopular: true,
      searchKeywords: ['mobile', 'phone', 'smartphone', 'iphone', 'samsung'],
    ),
    CategoryItem(
      icon: Icons.computer,
      iconColor: Colors.grey[300]!,
      backgroundColor: Colors.grey[800]!,
      title: 'Computers',
      isPopular: true,
      searchKeywords: ['computer', 'laptop', 'pc', 'desktop', 'macbook'],
    ),
    CategoryItem(
      icon: Icons.headphones,
      iconColor: Colors.purple,
      backgroundColor: Colors.grey[100]!,
      title: 'Computer Accessories',
      isPopular: true,
      searchKeywords: ['accessories', 'keyboard', 'mouse', 'headphones', 'cable'],
    ),
    CategoryItem(
      icon: Icons.home,
      iconColor: Colors.red,
      backgroundColor: Colors.grey[100]!,
      title: 'Property for Sale',
      isPopular: true,
      searchKeywords: ['property', 'house', 'apartment', 'land', 'villa'],
    ),
    CategoryItem(
      icon: Icons.directions_car,
      iconColor: Colors.grey[400]!,
      backgroundColor: Colors.grey[800]!,
      title: 'Vehicles',
      isPopular: true,
      searchKeywords: ['car', 'vehicle', 'bike', 'motorcycle', 'truck'],
    ),
    
    // Other Categories (your original design)
    CategoryItem(
      icon: Icons.pedal_bike,
      iconColor: Colors.blue,
      backgroundColor: Colors.grey[600]!,
      title: 'Bikes',
      isPopular: false,
      searchKeywords: ['bike', 'bicycle', 'motorcycle', 'scooter'],
    ),
    CategoryItem(
      icon: Icons.kitchen,
      iconColor: Colors.grey[300]!,
      backgroundColor: Colors.grey[700]!,
      title: 'Home Appliances',
      isPopular: false,
      searchKeywords: ['appliance', 'fridge', 'washing', 'microwave', 'ac'],
    ),
    CategoryItem(
      icon: Icons.build,
      iconColor: Colors.orange,
      backgroundColor: Colors.red,
      title: 'Services',
      isPopular: false,
      searchKeywords: ['service', 'repair', 'cleaning', 'maintenance'],
    ),
    CategoryItem(
      icon: Icons.pets,
      iconColor: Colors.brown,
      backgroundColor: Colors.orange[100]!,
      title: 'Animals',
      isPopular: false,
      searchKeywords: ['animal', 'pet', 'cat', 'dog', 'bird'],
    ),
    CategoryItem(
      icon: Icons.work,
      iconColor: Colors.grey[600]!,
      backgroundColor: Colors.grey[200]!,
      title: 'Jobs',
      isPopular: false,
      searchKeywords: ['job', 'work', 'employment', 'career'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeCategories() async {
    setState(() {
      isLoading = true;
    });

    // Load product counts for each category (except "Any")
    for (var category in categories) {
      if (category.title != 'Any') {
        category.productCount = await _getProductCountForCategory(category.title);
      }
    }

    setState(() {
      filteredCategories = List.from(categories);
      isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCategories = List.from(categories);
      } else {
        filteredCategories = categories.where((category) {
          final titleMatch = category.title.toLowerCase().contains(query.toLowerCase());
          final keywordMatch = category.searchKeywords.any(
            (keyword) => keyword.toLowerCase().contains(query.toLowerCase())
          );
          return titleMatch || keywordMatch;
        }).toList();
      }
    });
  }

  Future<int> _getProductCountForCategory(String categoryName) async {
    try {
      String firestoreCategory = _mapCategoryName(categoryName);
      
      final snapshot = await FirebaseFirestore.instance
          .collection('items')
          .where('status', isEqualTo: 'active')
          .where('category', isEqualTo: firestoreCategory)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting product count for $categoryName: $e');
      return 0;
    }
  }

  String _mapCategoryName(String displayName) {
    switch (displayName) {
      case 'Mobiles':
        return 'Mobiles';
      case 'Computers':
        return 'Computers';
      case 'Computer Accessories':
        return 'Computer Accessories';
      case 'Property for Sale':
        return 'Property for Sale';
      case 'Vehicles':
        return 'Vehicles';
      case 'Bikes':
        return 'Bikes';
      case 'Home Appliances':
        return 'Home Appliances';
      case 'Services':
        return 'Services';
      case 'Animals':
        return 'Animals';
      case 'Jobs':
        return 'Jobs';
      default:
        return displayName;
    }
  }

  void _navigateToCategory(CategoryItem category) {
    if (category.title == 'Mobiles') {
      // Navigate to MobilesCategoryPage for subcategory selection
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MobilesCategoryPageForFilter(
            onCategorySelected: (selectedCategory) {
              // Update the parent callback and close both pages
              widget.onCategorySelected(selectedCategory);
              Navigator.pop(context); // Close mobile categories page
            },
          ),
        ),
      );
    } else {
      // For other categories, select directly
      widget.onCategorySelected(category.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
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
          'Select Category',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field (keeping your original design)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by Categories',
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
                            _onSearchChanged('');
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
            
            const SizedBox(height: 24),
            
            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0D5E2A),
                  ),
                ),
              )
            else if (filteredCategories.isEmpty)
              _buildNoResults()
            else
              Expanded(
                child: ListView(
                  children: [
                    // Popular Section (keeping your original design)
                    if (filteredCategories.any((cat) => cat.isPopular)) ...[
                      Text(
                        'Popular',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...filteredCategories
                          .where((cat) => cat.isPopular)
                          .map((category) => _buildCategoryItem(category)),
                      const SizedBox(height: 24),
                    ],
                    
                    // Others Section (keeping your original design)
                    if (filteredCategories.any((cat) => !cat.isPopular)) ...[
                      Text(
                        'Others',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...filteredCategories
                          .where((cat) => !cat.isPopular)
                          .map((category) => _buildCategoryItem(category)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryItem(CategoryItem category) {
    final isSelected = category.title == widget.selectedCategory || 
                      (widget.selectedCategory.startsWith('Mobiles') && category.title == 'Mobiles');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: InkWell(
        onTap: () => _navigateToCategory(category),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              // Category Icon (keeping your original design)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  color: category.iconColor,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Category Title (keeping your original design)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                        color: isSelected ? const Color(0xFF0D5E2A) : Colors.black,
                      ),
                    ),
                    // Show selected subcategory if applicable
                    if (isSelected && widget.selectedCategory.startsWith('Mobiles - '))
                      Text(
                        widget.selectedCategory.replaceFirst('Mobiles - ', ''),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF0D5E2A).withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Product Count Badge (new backend feature)
              if (category.productCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D5E2A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${category.productCount}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF0D5E2A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              
              // Selection indicator and Arrow Icon
              if (isSelected)
                const Icon(Icons.check, color: Color(0xFF0D5E2A), size: 20)
              else
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Expanded(
      child: Center(
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
              'No categories found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mobile Categories Page for Filter Selection
class MobilesCategoryPageForFilter extends StatefulWidget {
  final Function(String) onCategorySelected;
  
  const MobilesCategoryPageForFilter({
    Key? key, 
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<MobilesCategoryPageForFilter> createState() => _MobilesCategoryPageForFilterState();
}

class _MobilesCategoryPageForFilterState extends State<MobilesCategoryPageForFilter> {
  final TextEditingController _searchController = TextEditingController();
  List<String> filteredMobileModels = [];
  
  final List<String> iPhoneModels = const [
    'All Mobile Phones',
    'iPhones',
    'Samsung',
    'Nokia',
    'Xiaomi',
    'Huawei',
    'OnePlus',
    'Oppo',
    'Vivo',
    'Realme',
    'Google Pixel',
    'Sony',
    'LG',
    'Motorola',
    'Honor',
  ];

  @override
  void initState() {
    super.initState();
    filteredMobileModels = List.from(iPhoneModels);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMobileModels = List.from(iPhoneModels);
      } else {
        filteredMobileModels = iPhoneModels
            .where((model) => model.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectMobileCategory(String model) {
    if (model == 'All Mobile Phones') {
      widget.onCategorySelected('Mobiles');
    } else {
      widget.onCategorySelected('Mobiles - $model');
    }
    // Close the mobile categories page after selection
    Navigator.pop(context);
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
          'Mobile Phones',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field (keeping your original design)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by Categories',
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
                            _onSearchChanged('');
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
            
            const SizedBox(height: 24),
            
            // iPhone Models List (keeping your original design)
            Expanded(
              child: filteredMobileModels.isEmpty 
                  ? _buildNoResults()
                  : ListView.builder(
                      itemCount: filteredMobileModels.length,
                      itemBuilder: (context, index) {
                        final model = filteredMobileModels[index];
                        final isFirst = index == 0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _selectMobileCategory(model),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      model,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: isFirst ? const Color(0xFF0D5E2A) : Colors.black,
                                        fontWeight: isFirst ? FontWeight.w500 : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
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
            'No categories found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// Category Item Model
class CategoryItem {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final bool isPopular;
  final List<String> searchKeywords;
  int productCount;

  CategoryItem({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.isPopular,
    required this.searchKeywords,
    this.productCount = 0,
  });
}