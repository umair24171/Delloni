import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/categories_selection_page/view/categories_selection_page.dart';
import 'package:arabicmarketplace/screens/notifications/controller/saved_search_provider.dart';
import 'package:arabicmarketplace/screens/search_page/city_district_selection_page.dart';
import 'package:arabicmarketplace/screens/search_page/controller/search_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/view/review_publish.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:arabicmarketplace/screens/sell_items/view/item_details_screen.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_results_page.dart';
import 'package:arabicmarketplace/screens/search_page/view/map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final TextEditingController _searchNameController = TextEditingController();
  
  // NEW: Dynamic filter controllers based on category
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();
  final TextEditingController _minAreaController = TextEditingController();
  final TextEditingController _maxAreaController = TextEditingController();
  final TextEditingController _minMileageController = TextEditingController();
  final TextEditingController _maxMileageController = TextEditingController();
  final TextEditingController _minYearController = TextEditingController();
  final TextEditingController _maxYearController = TextEditingController();
  
  String selectedAdType = 'All';
  String selectedCategory = 'Any';
  String selectedLocation = 'Current Location';
  String? selectedCityId;
  String? selectedCityName;
  String? selectedDistrictId;
  String? selectedDistrictName;
  double? userLatitude;
  double? userLongitude;
  bool _isLoadingLocation = false;
  bool _isSavingSearch = false;
  String? selectedCategoryName;
  String? selectedCategoryId;

  // NEW: Category-specific filter states
  String selectedJobType = 'Any'; // Full-time, Part-time, Contract, etc.
  String selectedExperienceLevel = 'Any'; // Entry, Mid, Senior
  String selectedPropertyType = 'Any'; // House, Apartment, Land, etc.
  String selectedVehicleType = 'Any'; // Car, Motorcycle, Truck, etc.
  String selectedCondition = 'Any'; // New, Used, Refurbished
  String selectedBrand = 'Any';

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

  // NEW: Get category type for dynamic filters
  String _getCategoryType(String? categoryName) {
    if (categoryName == null) return 'general';
    
    final categoryLower = categoryName.toLowerCase();
    
    if (categoryLower.contains('job') || categoryLower.contains('career') || categoryLower.contains('employment')) {
      return 'jobs';
    } else if (categoryLower.contains('house') || categoryLower.contains('property') || categoryLower.contains('real estate') || 
               categoryLower.contains('apartment') || categoryLower.contains('villa') || categoryLower.contains('land')) {
      return 'real_estate';
    } else if (categoryLower.contains('car') || categoryLower.contains('vehicle') || categoryLower.contains('motorcycle') || 
               categoryLower.contains('truck') || categoryLower.contains('auto')) {
      return 'vehicles';
    } else if (categoryLower.contains('mobile') || categoryLower.contains('phone') || categoryLower.contains('electronics') || 
               categoryLower.contains('computer') || categoryLower.contains('laptop')) {
      return 'electronics';
    }
    
    return 'general';
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
    _searchNameController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    _minMileageController.dispose();
    _maxMileageController.dispose();
    _minYearController.dispose();
    _maxYearController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    try {
      final filters = SearchFilters(
        selectedCategory: selectedCategoryName,
        minPrice: _parseDouble(_minPriceController.text),
        maxPrice: _parseDouble(_maxPriceController.text),
        minRadius: _parseDouble(_minRadiusController.text),
        maxRadius: _parseDouble(_maxRadiusController.text),
        adType: selectedAdType == 'All' ? null : selectedAdType,
        latitude: userLatitude,
        longitude: userLongitude,
        radiusKm: _parseDouble(_maxRadiusController.text),
        location: selectedLocation,
        cityId: selectedCityId,
        cityName: selectedCityName,
        districtId: selectedDistrictId,
        districtName: selectedDistrictName,
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

      Navigator.of(context).pop(filters); // Return filters to parent
    } catch (e) {
      _showError('Invalid filter values. Please check your inputs.');
    }
  }

  Future<void> _saveSearch() async {
    if (_searchNameController.text.trim().isEmpty) {
      _showError('Please enter a name for your saved search');
      return;
    }

    setState(() {
      _isSavingSearch = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Please login to save searches');
        setState(() {
          _isSavingSearch = false;
        });
        return;
      }

      final savedSearchProvider = Provider.of<SavedSearchProvider>(context, listen: false);
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);
      
      final filters = SearchFilters(
        selectedCategory: selectedCategoryName,
        minPrice: _parseDouble(_minPriceController.text),
        maxPrice: _parseDouble(_maxPriceController.text),
        minRadius: _parseDouble(_minRadiusController.text),
        maxRadius: _parseDouble(_maxRadiusController.text),
        adType: selectedAdType == 'All' ? null : selectedAdType,
        latitude: userLatitude,
        longitude: userLongitude,
        radiusKm: _parseDouble(_maxRadiusController.text),
        location: selectedLocation,
        cityId: selectedCityId,
        cityName: selectedCityName,
        districtId: selectedDistrictId,
        districtName: selectedDistrictName,
      );

      final success = await savedSearchProvider.saveCurrentSearch(
        name: _searchNameController.text.trim(),
        query: searchProvider.searchQuery,
        filters: filters,
      );

      setState(() {
        _isSavingSearch = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search saved successfully! You\'ll be notified when new items match your criteria.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _searchNameController.clear();
      } else {
        _showError('Failed to save search. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isSavingSearch = false;
      });
      _showError('Failed to save search: $e');
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
      selectedCityId = null;
      selectedCityName = null;
      selectedDistrictId = null;
      selectedDistrictName = null;
      selectedJobType = 'Any';
      selectedExperienceLevel = 'Any';
      selectedPropertyType = 'Any';
      selectedVehicleType = 'Any';
      selectedCondition = 'Any';
      selectedBrand = 'Any';
      _minRadiusController.text = '0';
      _maxRadiusController.text = '50';
      _minPriceController.text = '0';
      _maxPriceController.text = '100000';
      _minSalaryController.clear();
      _maxSalaryController.clear();
      _minAreaController.clear();
      _maxAreaController.clear();
      _minMileageController.clear();
      _maxMileageController.clear();
      _minYearController.clear();
      _maxYearController.clear();
    });

    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final categoryType = _getCategoryType(selectedCategoryName);
    
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
          'Advanced Search Filter',
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
              'Clear All',
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
                    subtitle: selectedCategoryName ?? 'Select Category',
                  onTap: () async {
  final categories = await _loadCategoriesFromFirestore();
  final mainCategories = categories.where((cat) => cat['level'] == 0).toList();
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CategorySelectionPage(
        categories: categories,
        mainCategories: mainCategories,
        isForSearch: true, // NEW: This enables the "Select All" functionality
      ),
    ),
  );
  if (result != null && result['categoryName'] != null) {
    setState(() {
      selectedCategoryName = result['categoryName'];
      selectedCategoryId = result['finalCategoryId'];
      // NEW: Handle "Select All" cases
      if (result['isSelectAll'] == true) {
        selectedCategoryName = 'All in ${result['categoryName']}';
      }
      // Reset category-specific filters when category changes
      _resetCategorySpecificFilters();
    });
  }
}
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Enhanced Location Section with more options
                  _buildEnhancedLocationSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Dynamic filters based on category type
                  ..._buildDynamicFilters(categoryType),
                  
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
                  
                  // Price Section (conditional based on category)
                  if (categoryType != 'jobs') ...[
                    _buildSectionTitle(categoryType == 'real_estate' ? 'Price Range (\$)' : 'Price Range (\$)'),
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
                            hint: categoryType == 'real_estate' ? '1,000,000' : '100,000',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Salary Section (only for jobs)
                  if (categoryType == 'jobs') ...[
                    _buildSectionTitle('Salary Range (\$/month)'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            label: 'Min',
                            controller: _minSalaryController,
                            hint: '0',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildNumberField(
                            label: 'Max',
                            controller: _maxSalaryController,
                            hint: '10,000',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  
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
                  
                  // Save Search Section
                  _buildSaveSearchSection(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Apply Filters Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16,).copyWith(bottom: 40),
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
                      Icons.search,
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

  // NEW: Build dynamic filters based on category
  List<Widget> _buildDynamicFilters(String categoryType) {
    List<Widget> widgets = [];

    switch (categoryType) {
      case 'jobs':
        widgets.addAll([
          _buildSectionTitle('Job Type'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Any', 'Full-time', 'Part-time', 'Contract', 'Freelance', 'Internship']
                .map((type) => _buildChipButton(type, selectedJobType, (value) {
                  setState(() {
                    selectedJobType = value;
                  });
                })).toList(),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Experience Level'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Any', 'Entry Level', 'Mid Level', 'Senior Level', 'Executive']
                .map((level) => _buildChipButton(level, selectedExperienceLevel, (value) {
                  setState(() {
                    selectedExperienceLevel = value;
                  });
                })).toList(),
          ),
        ]);
        break;

      case 'real_estate':
        widgets.addAll([
          _buildSectionTitle('Property Type'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Any', 'House', 'Apartment', 'Villa', 'Land', 'Commercial', 'Office']
                .map((type) => _buildChipButton(type, selectedPropertyType, (value) {
                  setState(() {
                    selectedPropertyType = value;
                  });
                })).toList(),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Area (sq ft)'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'Min Area',
                  controller: _minAreaController,
                  hint: '500',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  label: 'Max Area',
                  controller: _maxAreaController,
                  hint: '5000',
                ),
              ),
            ],
          ),
        ]);
        break;

      case 'vehicles':
        widgets.addAll([
          _buildSectionTitle('Vehicle Type'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Any', 'Car', 'Motorcycle', 'Truck', 'Bus', 'Bicycle']
                .map((type) => _buildChipButton(type, selectedVehicleType, (value) {
                  setState(() {
                    selectedVehicleType = value;
                  });
                })).toList(),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Year Range'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'From Year',
                  controller: _minYearController,
                  hint: '2000',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  label: 'To Year',
                  controller: _maxYearController,
                  hint: '2024',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Mileage (km)'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'Min Mileage',
                  controller: _minMileageController,
                  hint: '0',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  label: 'Max Mileage',
                  controller: _maxMileageController,
                  hint: '200000',
                ),
              ),
            ],
          ),
        ]);
        break;

      case 'electronics':
        widgets.addAll([
          _buildSectionTitle('Condition'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Any', 'New', 'Used', 'Refurbished']
                .map((condition) => _buildChipButton(condition, selectedCondition, (value) {
                  setState(() {
                    selectedCondition = value;
                  });
                })).toList(),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Brand'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Any', 'Apple', 'Samsung', 'Huawei', 'Xiaomi', 'OnePlus', 'Google']
                .map((brand) => _buildChipButton(brand, selectedBrand, (value) {
                  setState(() {
                    selectedBrand = value;
                  });
                })).toList(),
          ),
        ]);
        break;

      default:
        widgets.addAll([
          _buildSectionTitle('Condition'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Any', 'New', 'Used', 'Like New']
                .map((condition) => _buildChipButton(condition, selectedCondition, (value) {
                  setState(() {
                    selectedCondition = value;
                  });
                })).toList(),
          ),
        ]);
        break;
    }

    return widgets;
  }

  // NEW: Reset category-specific filters
  void _resetCategorySpecificFilters() {
    selectedJobType = 'Any';
    selectedExperienceLevel = 'Any';
    selectedPropertyType = 'Any';
    selectedVehicleType = 'Any';
    selectedCondition = 'Any';
    selectedBrand = 'Any';
    _minSalaryController.clear();
    _maxSalaryController.clear();
    _minAreaController.clear();
    _maxAreaController.clear();
    _minMileageController.clear();
    _maxMileageController.clear();
    _minYearController.clear();
    _maxYearController.clear();
  }

  // NEW: Build chip button for filters
  Widget _buildChipButton(String label, String selectedValue, Function(String) onSelected) {
    final isSelected = selectedValue == label;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => onSelected(label),
      selectedColor: ColorsController.primaryColor,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey[200],
      padding: EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // ENHANCED: Location section with more options
  Widget _buildEnhancedLocationSection() {
    String locationDisplay = 'Current Location';
    if (selectedCityName != null) {
      if (selectedDistrictName != null) {
        locationDisplay = '$selectedDistrictName, $selectedCityName';
      } else {
        locationDisplay = selectedCityName!;
      }
    } else if (selectedLocation != null && selectedLocation != 'Current Location') {
      locationDisplay = selectedLocation!;
    } else if (userLatitude != null && userLongitude != null) {
      locationDisplay = 'Current Location (${userLatitude!.toStringAsFixed(2)}, ${userLongitude!.toStringAsFixed(2)})';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterItem(
          title: 'Location',
          subtitle: _isLoadingLocation ? 'Getting location...' : locationDisplay,
          trailing: _isLoadingLocation 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _isLoadingLocation ? null : () async {
            await showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Choose Location Method',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.my_location, color: Colors.green[700]),
                      ),
                      title: const Text('Use Current Location'),
                      subtitle: const Text('Get your precise location automatically'),
                      onTap: () async {
                        await _getCurrentLocation();
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.map, color: Colors.blue[700]),
                      ),
                      title: const Text('Choose on Map'),
                      subtitle: const Text('Pick any location on the map'),
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapLocationPicker(
                              initialLocation: userLatitude != null && userLongitude != null
                                  ? LatLng(userLatitude!, userLongitude!)
                                  : null,
                              initialRadiusKm: _parseDouble(_maxRadiusController.text) ?? 10,
                            ),
                          ),
                        );
                        if (result != null && result['latLng'] != null) {
                          setState(() {
                            userLatitude = result['latLng'].latitude;
                            userLongitude = result['latLng'].longitude;
                            selectedCityId = null;
                            selectedCityName = null;
                            selectedDistrictId = null;
                            selectedDistrictName = null;
                            selectedLocation = result['address'] ?? 'Map Location';
                            _maxRadiusController.text = result['radiusKm'].toString();
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.location_city, color: Colors.orange[700]),
                      ),
                      title: const Text('Choose City/District'),
                      subtitle: const Text('Select from available cities and districts'),
                      onTap: () {
                        Navigator.pop(context);
                        _showCityDistrictSelection();
                      },
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSaveSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark_add, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Save This Search',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Get notified when new items match your search criteria',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchNameController,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter a name for this search...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue[400]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingSearch ? null : _saveSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSavingSearch
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save Search',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
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

  void _showCityDistrictSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CityDistrictSelectionPage(),
      ),
    );

    if (result != null) {
      setState(() {
        selectedCityId = result['cityId'];
        selectedCityName = result['cityName'];
        selectedDistrictId = result['districtId'];
        selectedDistrictName = result['districtName'];
        selectedLocation = result['fullAddress'];
        if (result['latitude'] != null && result['latitude'] != 0.0) {
          userLatitude = result['latitude'];
          userLongitude = result['longitude'];
        }
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadCategoriesFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}