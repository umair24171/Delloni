import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/categories_selection_page/view/categories_selection_page.dart';
import 'package:arabicmarketplace/screens/notifications/controller/saved_search_provider.dart';
import 'package:arabicmarketplace/screens/search_page/city_district_selection_page.dart';
import 'package:arabicmarketplace/screens/search_page/controller/search_provider.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_results_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:arabicmarketplace/screens/search_page/view/map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
class SearchFilterPage extends StatefulWidget {
  final Function(SearchFilters)? onFiltersApplied;
  final bool isMain;
  
  const SearchFilterPage({Key? key, this.onFiltersApplied, this.isMain = false}) : super(key: key);

  @override
  State<SearchFilterPage> createState() => _SearchFilterPageState();
}

class _SearchFilterPageState extends State<SearchFilterPage> {
  final TextEditingController _minRadiusController = TextEditingController();
  final TextEditingController _maxRadiusController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _searchNameController = TextEditingController();
  
  // Basic filter states
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

  // ENHANCED: Category configuration and dynamic fields
  Map<String, dynamic>? selectedCategoryConfig;
  List<Map<String, dynamic>> categoryConfiguredFields = [];
  Map<String, dynamic> dynamicFieldValues = {}; // Store values for dynamic fields
  Map<String, TextEditingController> dynamicTextControllers = {}; // Controllers for text fields

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _getCurrentLocation();
    debugEverything();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _minRadiusController.dispose();
    _maxRadiusController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _searchNameController.dispose();
    
    // Dispose dynamic controllers
    dynamicTextControllers.forEach((key, controller) {
      controller.dispose();
    });
    
    super.dispose();
  }

  // ENHANCED: Initialize filters with category configuration loading
  void _initializeFilters() {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    final filters = searchProvider.filters;
    
    selectedCategoryId = filters.selectedCategory;
    selectedCategory = filters.selectedCategory ?? 'Any';
    selectedAdType = filters.adType ?? 'All';
    selectedLocation = filters.location ?? 'Current Location';
    selectedCityId = filters.cityId;
    selectedCityName = filters.cityName;
    selectedDistrictId = filters.districtId;
    selectedDistrictName = filters.districtName;
    userLatitude = filters.latitude;
    userLongitude = filters.longitude;
    
    _minRadiusController.text = filters.minRadius?.toString() ?? '0';
    _maxRadiusController.text = filters.maxRadius?.toString() ?? '50';
    _minPriceController.text = filters.minPrice?.toString() ?? '0';
    _maxPriceController.text = filters.maxPrice?.toString() ?? '1000000';

    // Load existing category-specific filters
    if (filters.categorySpecificFilters != null) {
      dynamicFieldValues = Map<String, dynamic>.from(filters.categorySpecificFilters!);
    }

    // Load category configuration if we have category ID
    if (selectedCategoryId != null) {
      _loadCategoryConfiguration(selectedCategoryId!);
    }
  }

  // ENHANCED: Load category configuration including configuredFields
  Future<void> _loadCategoryConfiguration(String categoryId) async {
    try {
      print('Loading category configuration for: $categoryId');
      
      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        
        setState(() {
          selectedCategoryName = data['name'];
          selectedCategoryConfig = data;
          
          // Extract configured fields
          if (data['configuredFields'] != null) {
            categoryConfiguredFields = List<Map<String, dynamic>>.from(data['configuredFields']);
            print('Found ${categoryConfiguredFields.length} configured fields');
            
            // Initialize controllers for text fields
            for (final field in categoryConfiguredFields) {
              final fieldName = field['name'] ?? field['fieldName'];
              final fieldType = field['type'];
              
              if (fieldName != null && (fieldType == 'text' || fieldType == 'number')) {
                if (!dynamicTextControllers.containsKey(fieldName)) {
                  dynamicTextControllers[fieldName] = TextEditingController();
                }
                
                // Set existing value if any
                if (dynamicFieldValues.containsKey(fieldName)) {
                  dynamicTextControllers[fieldName]!.text = dynamicFieldValues[fieldName].toString();
                }
              }
            }
          } else {
            categoryConfiguredFields = [];
            print('No configured fields found for this category');
          }
        });
        
        print('Category configuration loaded: ${data['name']}');
        print('Configured fields: ${categoryConfiguredFields.map((f) => f['name']).toList()}');
      }
    } catch (e) {
      print('Error loading category configuration: $e');
    }
  }

  // ENHANCED: Clear category-specific data when category changes
  void _clearCategorySpecificData() {
    setState(() {
      selectedCategoryConfig = null;
      categoryConfiguredFields = [];
      dynamicFieldValues.clear();
      
      // Dispose and clear dynamic controllers
      dynamicTextControllers.forEach((key, controller) {
        controller.dispose();
      });
      dynamicTextControllers.clear();
    });
  }

  // ENHANCED: Location handling with proper debugging
  Future<void> _getCurrentLocation() async {
    if (userLatitude != null && userLongitude != null) return;
    
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled'.tr());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permission denied'.tr());
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
        selectedCityId = null; // Clear city selection when using current location
        selectedCityName = null;
        selectedDistrictId = null;
        selectedDistrictName = null;
        _isLoadingLocation = false;
      });
      
      print('✅ Current location obtained: $userLatitude, $userLongitude');
    } catch (e) {
      _showLocationError('Failed to get location: $e');
    }
  }

  // ENHANCED: Apply filters with dynamic category fields and proper location handling
  void _applyFilters() {
    try {
      print('🔧 Applying filters...');
      
      // Build category-specific filters map including dynamic fields
      Map<String, dynamic> categorySpecificFilters = {};
      
      // Add dynamic field values
      dynamicFieldValues.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty && value != 'Any') {
          categorySpecificFilters[key] = value;
          print('Added dynamic filter: $key = $value');
        }
      });
      
      // Add text field values
      dynamicTextControllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          // Try to parse as number if it looks like a number
          final text = controller.text.trim();
          if (RegExp(r'^\d+\.?\d*$').hasMatch(text)) {
            categorySpecificFilters[key] = double.tryParse(text) ?? text;
          } else {
            categorySpecificFilters[key] = text;
          }
          print('Added text filter: $key = ${categorySpecificFilters[key]}');
        }
      });

      // ENHANCED: Proper location handling
      double? finalLatitude = userLatitude;
      double? finalLongitude = userLongitude;
      String? finalLocation = selectedLocation;
      
      // If city/district is selected, clear coordinates to use city filtering
      if (selectedCityId != null) {
        finalLatitude = null;
        finalLongitude = null;
        if (selectedDistrictName != null) {
          finalLocation = '$selectedDistrictName, $selectedCityName';
        } else {
          finalLocation = selectedCityName;
        }
        print('🏙️ Using city-based filtering: $finalLocation');
      } else if (userLatitude != null && userLongitude != null) {
        // Use coordinate-based filtering
        finalLocation = 'Current Location';
        print('📍 Using coordinate-based filtering: $finalLatitude, $finalLongitude');
      }

      final filters = SearchFilters(
        selectedCategory: selectedCategoryId, // Use category ID, not name
        minPrice: _parseDouble(_minPriceController.text),
        maxPrice: _parseDouble(_maxPriceController.text),
        minRadius: _parseDouble(_minRadiusController.text),
        maxRadius: _parseDouble(_maxRadiusController.text),
        adType: selectedAdType == 'All' ? null : selectedAdType,
        latitude: finalLatitude,
        longitude: finalLongitude,
        radiusKm: _parseDouble(_maxRadiusController.text),
        location: finalLocation,
        cityId: selectedCityId,
        cityName: selectedCityName,
        districtId: selectedDistrictId,
        districtName: selectedDistrictName,
        categorySpecificFilters: categorySpecificFilters.isNotEmpty ? categorySpecificFilters : null,
      );

      print('🎯 Final filters created:');
      print('- Category: ${filters.selectedCategory}');
      print('- Price: ${filters.minPrice} - ${filters.maxPrice}');
      print('- Location: ${filters.location}');
      print('- City ID: ${filters.cityId}');
      print('- District ID: ${filters.districtId}');
      print('- Coordinates: ${filters.latitude}, ${filters.longitude}');
      print('- Category specific: ${filters.categorySpecificFilters}');

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
      // widget.onFiltersApplied?.call(filters);
      Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultsPage(filters: filters)));

      // Navigator.of(context).pop(filters); // Return filters to parent
    } catch (e) {
      print('❌ Error applying filters: $e');
      _showError('Invalid filter values. Please check your inputs.');
    }
  }

  // ENHANCED: City/District selection with proper callback handling
  void _showCityDistrictSelection() async {
    print('🏙️ Opening city/district selection...');
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CityDistrictSelectionPage(),
      ),
    );

    print('🏙️ City/District selection result: $result');

    if (result != null && mounted) {
      setState(() {
        selectedCityId = result['cityId'];
        selectedCityName = result['cityName'];
        selectedDistrictId = result['districtId'];
        selectedDistrictName = result['districtName'];
        
        // Update location display
        if (selectedDistrictName != null) {
          selectedLocation = '$selectedDistrictName, $selectedCityName';
        } else if (selectedCityName != null) {
          selectedLocation = selectedCityName!;
        } else {
          selectedLocation = result['fullAddress'] ?? 'Custom Location';
        }
        
        // Clear coordinates when city/district is selected (prefer city-based filtering)
        userLatitude = null;
        userLongitude = null;
        
        print('✅ Location updated to: $selectedLocation');
        print('✅ City ID: $selectedCityId, District ID: $selectedDistrictId');
      });
    }
  }

  // ENHANCED: Build dynamic filter fields based on category configuration
  List<Widget> _buildDynamicCategoryFields() {
    if (categoryConfiguredFields.isEmpty) {
      return [];
    }

    print('Building ${categoryConfiguredFields.length} dynamic category fields');

    final widgets = <Widget>[];

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Text(
          'Category-Specific Filters'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
      ),
    );

    for (final field in categoryConfiguredFields) {
      final fieldName = field['name'] ?? field['fieldName'];
      final fieldLabel = field['label'] ?? fieldName;
      final fieldType = field['type'];
      final fieldOptions = field['options'];
      final isRequired = field['required'] ?? false;

      if (fieldName == null) continue;

      print('Building field: $fieldName ($fieldType)');

      switch (fieldType) {
        case 'dropdown':
        case 'select':
          if (fieldOptions != null && fieldOptions is List) {
            widgets.add(_buildDropdownField(fieldName, fieldLabel, fieldOptions, isRequired));
            widgets.add(const SizedBox(height: 16));
          }
          break;

        case 'text':
        case 'number':
          widgets.add(_buildTextFieldForCategory(fieldName, fieldLabel, fieldType, isRequired));
          widgets.add(const SizedBox(height: 16));
          break;

        case 'boolean':
          widgets.add(_buildBooleanField(fieldName, fieldLabel, isRequired));
          widgets.add(const SizedBox(height: 16));
          break;

        case 'range':
          widgets.add(_buildRangeField(fieldName, fieldLabel, field));
          widgets.add(const SizedBox(height: 16));
          break;

        default:
          print('Unknown field type: $fieldType for field: $fieldName');
          break;
      }
    }

    if (widgets.length > 1) { // More than just the title
      widgets.add(const SizedBox(height: 8));
    }

    return widgets;
  }

  // Build dropdown field for category-specific options
  Widget _buildDropdownField(String fieldName, String fieldLabel, List options, bool isRequired) {
    final currentValue = dynamicFieldValues[fieldName] ?? 'Any';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              fieldLabel.tr(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(currentValue) ? currentValue : 'Any',
              isExpanded: true,
              items: [
                DropdownMenuItem<String>(
                  value: 'Any',
                  child: Text('Any'.tr()),
                ),
                ...options.map((option) => DropdownMenuItem<String>(
                  value: option.toString(),
                  child: Text(option.toString()),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  dynamicFieldValues[fieldName] = value;
                });
                print('Dropdown changed: $fieldName = $value');
              },
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build text field for category-specific inputs
  Widget _buildTextFieldForCategory(String fieldName, String fieldLabel, String fieldType, bool isRequired) {
    if (!dynamicTextControllers.containsKey(fieldName)) {
      dynamicTextControllers[fieldName] = TextEditingController();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              fieldLabel.tr(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: dynamicTextControllers[fieldName]!,
            keyboardType: fieldType == 'number' ? TextInputType.number : TextInputType.text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Enter $fieldLabel'.tr(),
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

  // Build boolean field (switch/toggle)
  Widget _buildBooleanField(String fieldName, String fieldLabel, bool isRequired) {
    final currentValue = dynamicFieldValues[fieldName] ?? false;
    
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                fieldLabel.tr(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        Switch(
          value: currentValue == true,
          onChanged: (value) {
            setState(() {
              dynamicFieldValues[fieldName] = value;
            });
            print('Boolean changed: $fieldName = $value');
          },
          activeColor: ColorsController.primaryColor,
        ),
      ],
    );
  }

  // Build range field (min/max inputs)
  Widget _buildRangeField(String fieldName, String fieldLabel, Map<String, dynamic> field) {
    final minKey = '${fieldName}_min';
    final maxKey = '${fieldName}_max';
    
    if (!dynamicTextControllers.containsKey(minKey)) {
      dynamicTextControllers[minKey] = TextEditingController();
    }
    if (!dynamicTextControllers.containsKey(maxKey)) {
      dynamicTextControllers[maxKey] = TextEditingController();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$fieldLabel Range'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                label: 'Min'.tr(),
                controller: dynamicTextControllers[minKey]!,
                hint: '0',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberField(
                label: 'Max'.tr(),
                controller: dynamicTextControllers[maxKey]!,
                hint: '999999',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Enhanced debug method to check everything including location
  Future<void> debugEverything() async {
    print('🔍 ===== COMPREHENSIVE DEBUG START =====');
    
    try {
      // Check current location state
      print('\n📍 CURRENT LOCATION STATE:');
      print('- User Latitude: $userLatitude');
      print('- User Longitude: $userLongitude');
      print('- Selected Location: $selectedLocation');
      print('- Selected City ID: $selectedCityId');
      print('- Selected City Name: $selectedCityName');
      print('- Selected District ID: $selectedDistrictId');
      print('- Selected District Name: $selectedDistrictName');
      
      // Test location services
      print('\n🌍 LOCATION SERVICES CHECK:');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('- Location services enabled: $serviceEnabled');
      
      LocationPermission permission = await Geolocator.checkPermission();
      print('- Location permission: $permission');

      // Check cities database
      print('\n🏙️ CHECKING CITIES IN DATABASE:');
      final citiesSnapshot = await FirebaseFirestore.instance
          .collection('cities')
          .where('isActive', isEqualTo: true)
          .limit(5)
          .get();
      
      print('   Found ${citiesSnapshot.docs.length} active cities:');
      for (var doc in citiesSnapshot.docs) {
        final data = doc.data();
        print('   - ID: ${doc.id} | Name: ${data['name']} | Active: ${data['isActive']}');
      }
      
      // Check districts database
      print('\n🏘️ CHECKING DISTRICTS IN DATABASE:');
      final districtsSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .where('isActive', isEqualTo: true)
          .limit(5)
          .get();
      
      print('   Found ${districtsSnapshot.docs.length} active districts:');
      for (var doc in districtsSnapshot.docs) {
        final data = doc.data();
        print('   - ID: ${doc.id} | Name: ${data['name']} | CityID: ${data['cityId']}');
      }

      // Check products with location data
      print('\n📦 CHECKING PRODUCTS WITH LOCATION:');
      final productSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .where('status', isEqualTo: 'active')
          .limit(3)
          .get();
      
      for (var doc in productSnapshot.docs) {
        final data = doc.data();
        print('   - Product: ${data['itemTitle']}');
        print('     * CityId: "${data['cityId']}" | DistrictId: "${data['districtId']}"');
        print('     * Location: "${data['locationAddress']}"');
        print('     * Coordinates: ${data['latitude']}, ${data['longitude']}');
      }

      // Check category configuration
      if (selectedCategoryId != null) {
        print('\n🎯 CHECKING SELECTED CATEGORY:');
        final categoryDoc = await FirebaseFirestore.instance
            .collection('categories')
            .doc(selectedCategoryId!)
            .get();
        
        if (categoryDoc.exists) {
          final data = categoryDoc.data()!;
          print('   - Category: ${data['name']}');
          print('   - Has Custom Fields: ${data['hasCustomFields']}');
          print('   - Configured Fields: ${data['configuredFields']?.length ?? 0}');
          
          if (data['configuredFields'] != null) {
            for (var field in data['configuredFields']) {
              print('     * Field: ${field['name']} (${field['type']})');
            }
          }
        }
      }
      
    } catch (e) {
      print('❌ Debug error: $e');
    }
    
    print('\n🔍 ===== COMPREHENSIVE DEBUG END =====');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: widget.isMain ? null : IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close,
            size: 24,
          ),
        ),
        title: Text(
          'Advanced Search Filter'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              'Clear All'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Debug button (remove in production)
          IconButton(
            onPressed: debugEverything,
            icon: Icon(Icons.bug_report, color: Colors.orange),
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
                  // Category Section - ENHANCED
                  _buildFilterItem(
                    title: 'Category'.tr(),
                    subtitle: selectedCategoryName ?? 'Select Category'.tr(),
                    onTap: () async {
                      final categories = await _loadCategoriesFromFirestore();
                      final mainCategories = categories.where((cat) => cat['level'] == 0).toList();
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategorySelectionPage(
                            categories: categories,
                            mainCategories: mainCategories,
                            selectedMainCategoryId: selectedCategoryId,
                            isForSearch: true,
                          ),
                        ),
                      );
                      if (result != null && result['categoryName'] != null) {
                        // Clear previous category data
                        _clearCategorySpecificData();
                        
                        setState(() {
                          selectedCategoryName = result['categoryName'];
                          selectedCategoryId = result['finalCategoryId'];
                          if (result['isSelectAll'] == true) {
                            selectedCategoryName = 'All in ${result['categoryName']}';
                          }
                        });
                        
                        // Load new category configuration
                        if (selectedCategoryId != null) {
                          await _loadCategoryConfiguration(selectedCategoryId!);
                        }
                      }
                    }
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ENHANCED: Location section with better status display
                  _buildEnhancedLocationSection(),
                  
                  const SizedBox(height: 24),
                  
                  // ENHANCED: Dynamic category-specific fields
                  ..._buildDynamicCategoryFields(),
                  
                  // Price Section
                  _buildSectionTitle('Price Range (\$)'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Min'.tr(),
                          controller: _minPriceController,
                          hint: '0',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Max'.tr(),
                          controller: _maxPriceController,
                          hint: '1,000,000',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Radius Section
                  _buildSectionTitle('Search Radius (km)'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Min'.tr(),
                          controller: _minRadiusController,
                          hint: '0',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Max'.tr(),
                          controller: _maxRadiusController,
                          hint: '50',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
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
                      'Apply Filters'.tr(),
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

  // ENHANCED: Location section with better status indicators
 // ENHANCED: Location section with Map option
Widget _buildEnhancedLocationSection() {
  String locationDisplay = 'Current Location'.tr();
  Color statusColor = Colors.grey;
  IconData statusIcon = Icons.location_off;
  
  if (selectedCityName != null) {
    if (selectedDistrictName != null) {
      locationDisplay = '$selectedDistrictName, $selectedCityName';
    } else {
      locationDisplay = selectedCityName!;
    }
    statusColor = Colors.green;
    statusIcon = Icons.location_city;
  } else if (userLatitude != null && userLongitude != null) {
    locationDisplay = 'Current Location (${userLatitude!.toStringAsFixed(2)}, ${userLongitude!.toStringAsFixed(2)})';
    statusColor = Colors.blue;
    statusIcon = Icons.my_location;
  } else if (_isLoadingLocation) {
    locationDisplay = 'Getting location...'.tr();
    statusColor = Colors.orange;
    statusIcon = Icons.location_searching;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildFilterItem(
        title: 'Location'.tr(),
        subtitle: locationDisplay,
        trailing: _isLoadingLocation 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
        onTap: _isLoadingLocation ? null : () async {
          await showModalBottomSheet(
            backgroundColor: Theme.of(context).brightness != Brightness.dark
                ? Colors.white
                : Colors.black,
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
                      'Choose Location Method'.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Option 1: Current Location
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
                    title: Text('Use Current Location'.tr()),
                    subtitle: Text('Get your precise location automatically'.tr()),
                    onTap: () async {
                      Navigator.pop(context);
                      await _getCurrentLocation();
                    },
                  ),
                  
                  // Option 2: City/District Selection
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
                    title: Text('Choose City/District'.tr()),
                    subtitle: Text('Select from available cities and districts'.tr()),
                    onTap: () {
                      Navigator.pop(context);
                      _showCityDistrictSelection();
                    },
                  ),
                  
                  // Option 3: Map Selection (NEW)
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
                    title: Text('Choose on Map'.tr()),
                    subtitle: Text('Select location visually on map'.tr()),
                    onTap: () async {
                      Navigator.pop(context);
                      await _showMapLocationPicker();
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

// NEW: Show map location picker with database integration
Future<void> _showMapLocationPicker() async {
  print('🗺️ Opening map location picker...');
  
  try {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedMapLocationPicker(
          initialLocation: userLatitude != null && userLongitude != null 
              ? LatLng(userLatitude!, userLongitude!) 
              : null,
          initialRadiusKm: _parseDouble(_maxRadiusController.text) ?? 50.0,
        ),
      ),
    );

    print('🗺️ Map location picker result: $result');

    if (result != null && mounted) {
      setState(() {
        // Set coordinates from map selection
        userLatitude = result['latLng']?.latitude;
        userLongitude = result['latLng']?.longitude;
        
        // Set matched city/district if found
        selectedCityId = result['cityId'];
        selectedCityName = result['cityName'];
        selectedDistrictId = result['districtId'];
        selectedDistrictName = result['districtName'];
        
        // Update radius if changed
        if (result['radiusKm'] != null) {
          _maxRadiusController.text = result['radiusKm'].toString();
        }
        
        // Update location display
        if (result['address'] != null) {
          selectedLocation = result['address'];
        } else if (selectedCityName != null) {
          selectedLocation = selectedDistrictName != null 
              ? '$selectedDistrictName, $selectedCityName'
              : selectedCityName!;
        } else {
          selectedLocation = 'Map Location (${userLatitude!.toStringAsFixed(3)}, ${userLongitude!.toStringAsFixed(3)})';
        }
        
        print('✅ Map location updated:');
        print('✅ - Coordinates: $userLatitude, $userLongitude');
        print('✅ - City: $selectedCityName ($selectedCityId)');
        print('✅ - District: $selectedDistrictName ($selectedDistrictId)');
        print('✅ - Display: $selectedLocation');
      });
    }
  } catch (e) {
    print('❌ Error opening map location picker: $e');
    _showError('Failed to open map: $e');
  }
}
  // Helper methods remain the same...
  void _clearAllFilters() {
    setState(() {
      selectedCategory = 'Any';
      selectedCategoryId = null;
      selectedCategoryName = null;
      selectedAdType = 'All';
      selectedLocation = 'Current Location';
      selectedCityId = null;
      selectedCityName = null;
      selectedDistrictId = null;
      selectedDistrictName = null;
      userLatitude = null;
      userLongitude = null;
      _minRadiusController.text = '0';
      _maxRadiusController.text = '50';
      _minPriceController.text = '0';
      _maxPriceController.text = '1000000';
    });
    
    _clearCategorySpecificData();

    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.clearFilters();
  }

  // Other helper methods...
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

  // [Include all the other helper methods like _buildSectionTitle, _buildFilterItem, 
  // _buildNumberField, _buildAdTypeButton, _buildSaveSearchSection, etc. from your original code]

  Widget _buildSectionTitle(String title) {
    return Text(
      title.tr(),
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
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
              type.tr(),
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
                'Save This Search'.tr(),
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
            'Get notified when new items match your search criteria'.tr(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchNameController,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Enter a name for this search...'.tr(),
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
                      'Save Search'.tr(),
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

      // Build complete filters including dynamic fields
      Map<String, dynamic> categorySpecificFilters = {};
      
      // Add dynamic field values
      dynamicFieldValues.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty && value != 'Any') {
          categorySpecificFilters[key] = value;
        }
      });
      
      // Add text field values
      dynamicTextControllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          final text = controller.text.trim();
          if (RegExp(r'^\d+\.?\d*$').hasMatch(text)) {
            categorySpecificFilters[key] = double.tryParse(text) ?? text;
          } else {
            categorySpecificFilters[key] = text;
          }
        }
      });

      final savedSearchProvider = Provider.of<SavedSearchProvider>(context, listen: false);
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);
      
      final filters = SearchFilters(
        selectedCategory: selectedCategoryId,
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
        categorySpecificFilters: categorySpecificFilters.isNotEmpty ? categorySpecificFilters : null,
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