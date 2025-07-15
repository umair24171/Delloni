import 'dart:developer' as developer;

import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/categories_selection_page/view/categories_selection_page.dart';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/view/pricing_shipping.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class ItemDetailsPage extends StatefulWidget {
  const ItemDetailsPage({Key? key, this.isMain = false,this.productToEdit }) : super(key: key);
  final bool isMain;
  final ProductModel? productToEdit;

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Categories from Firestore
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _mainCategories = [];
  List<Map<String, dynamic>> _subCategories = [];
  List<Map<String, dynamic>> _subSubCategories = [];
  List<Map<String, dynamic>> _subSubSubCategories = [];
  
  bool _isLoadingCategories = true;
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedSubSubCategoryId;
  String? _selectedSubSubSubCategoryId;
  String? _selectedCategoryName;

  // Category-specific fields
  Map<String, dynamic> _categorySpecificFields = {};
  List<String> _currentCategoryFields = [];

  // ENHANCED: Comprehensive category field templates matching admin web side
  Map<String, List<Map<String, dynamic>>> get _categoryFieldTemplates {
    return {
      // VEHICLES - Main Category
      'Vehicle': [
        {
          'name': 'year',
          'label': AppLocalizations.year.tr(),
          'type': 'year_picker',
          'required': true,
          'category': 'basic_info',
          'validation': {'min': 1950, 'max': 2025},
        },
        {
          'name': 'kilometers',
          'label': AppLocalizations.mileageKm.tr(),
          'type': 'number',
          'required': true,
          'category': 'technical',
          'suffix': 'km',
          'validation': {'min': 0, 'max': 1000000},
        },
        {
          'name': 'fuel_type',
          'label': AppLocalizations.fuelType.tr(),
          'type': 'dropdown',
          'required': true,
          'category': 'technical',
          'options': [
            AppLocalizations.petrol.tr(),
            AppLocalizations.diesel.tr(),
            AppLocalizations.electric.tr(),
            AppLocalizations.hybrid.tr(),
            'CNG',
            'LPG'
          ],
        },
        {
          'name': 'transmission',
          'label': AppLocalizations.transmission.tr(),
          'type': 'dropdown',
          'required': true,
          'category': 'technical',
          'options': [
            AppLocalizations.manual.tr(),
            AppLocalizations.automatic.tr(),
            'Semi-Automatic'
          ],
        },
        {
          'name': 'engine_capacity',
          'label': AppLocalizations.engineCapacityCc.tr(),
          'type': 'number',
          'required': false,
          'category': 'technical',
          'suffix': 'CC',
          'validation': {'min': 50, 'max': 8000},
        },
        {
          'name': 'color',
          'label': AppLocalizations.color.tr(),
          'type': 'color_picker',
          'required': true,
          'category': 'appearance',
          'options': ['White', 'Black', 'Silver', 'Red', 'Blue', 'Grey', 'Green', 'Other'],
        },
        {
          'name': 'body_type',
          'label': AppLocalizations.bodyType.tr(),
          'type': 'dropdown',
          'required': false,
          'category': 'design',
          'options': [
            AppLocalizations.sedan.tr(),
            AppLocalizations.hatchback.tr(),
            AppLocalizations.suv.tr(),
            AppLocalizations.coupe.tr(),
            AppLocalizations.convertible.tr(),
            'Wagon',
            'Pickup'
          ],
        },
      ],

      // CARS - Subcategory (inherits from vehicles + specific fields)
      'Cars': [
        {
          'name': 'car_type',
          'label': 'Car Type',
          'type': 'dropdown',
          'required': true,
          'category': 'classification',
          'options': ['Sedan', 'Hatchback', 'SUV', 'Coupe', 'Station Wagon', 'Crossover'],
        },
        {
          'name': 'doors',
          'label': 'Number of Doors',
          'type': 'dropdown',
          'required': true,
          'category': 'design',
          'options': ['2', '3', '4', '5'],
        },
        {
          'name': 'seating_capacity',
          'label': 'Seating Capacity',
          'type': 'dropdown',
          'required': true,
          'category': 'comfort',
          'options': ['2', '4', '5', '7', '8+'],
        },
        {
          'name': 'power_steering',
          'label': 'Power Steering',
          'type': 'boolean',
          'required': false,
          'category': 'features',
        },
        {
          'name': 'air_conditioning',
          'label': 'Air Conditioning',
          'type': 'boolean',
          'required': false,
          'category': 'features',
        },
      ],

      // MOTORCYCLES - Subcategory
      'Motorcycles': [
        {
          'name': 'bike_type',
          'label': 'Motorcycle Type',
          'type': 'dropdown',
          'required': true,
          'category': 'classification',
          'options': ['Sport', 'Cruiser', 'Touring', 'Standard', 'Dirt Bike', 'Scooter'],
        },
        {
          'name': 'engine_type',
          'label': 'Engine Type',
          'type': 'dropdown',
          'required': false,
          'category': 'technical',
          'options': ['2-Stroke', '4-Stroke'],
        },
      ],

      // MOBILE PHONES - Enhanced
      'Mobiles': [
        {
          'name': 'storage',
          'label': AppLocalizations.storage.tr(),
          'type': 'dropdown',
          'required': true,
          'category': 'technical',
          'options': ['32GB', '64GB', '128GB', '256GB', '512GB', '1TB'],
        },
        {
          'name': 'ram',
          'label': AppLocalizations.ram.tr(),
          'type': 'dropdown',
          'required': true,
          'category': 'technical',
          'options': ['2GB', '3GB', '4GB', '6GB', '8GB', '12GB', '16GB'],
        },
        {
          'name': 'screen_size',
          'label': 'Screen Size',
          'type': 'text',
          'required': false,
          'category': 'display',
          'suffix': 'inches',
          'hint': 'e.g., 6.1',
        },
        {
          'name': 'battery_capacity',
          'label': 'Battery Capacity',
          'type': 'number',
          'required': false,
          'category': 'technical',
          'suffix': 'mAh',
          'validation': {'min': 1000, 'max': 10000},
        },
        {
          'name': 'color',
          'label': AppLocalizations.color.tr(),
          'type': 'color_picker',
          'required': true,
          'category': 'appearance',
          'options': ['Black', 'White', 'Gold', 'Silver', 'Blue', 'Red', 'Green', 'Purple', 'Other'],
        },
        {
          'name': 'network_type',
          'label': 'Network',
          'type': 'dropdown',
          'required': false,
          'category': 'connectivity',
          'options': ['3G', '4G', '5G'],
        },
        {
          'name': 'dual_sim',
          'label': 'Dual SIM',
          'type': 'boolean',
          'required': false,
          'category': 'connectivity',
        },
        {
          'name': 'warranty',
          'label': AppLocalizations.warranty.tr(),
          'type': 'dropdown',
          'required': false,
          'category': 'service',
          'options': [
            AppLocalizations.noWarranty.tr(),
            AppLocalizations.oneMonth.tr(),
            AppLocalizations.threeMonths.tr(),
            AppLocalizations.sixMonths.tr(),
            AppLocalizations.oneYear.tr()
          ],
        },
      ],

      // COMPUTERS - New
      'Computers': [
        {
          'name': 'processor',
          'label': 'Processor',
          'type': 'text',
          'required': true,
          'category': 'technical',
          'hint': 'e.g., Intel Core i5, AMD Ryzen 5',
        },
        {
          'name': 'ram',
          'label': 'RAM',
          'type': 'dropdown',
          'required': true,
          'category': 'technical',
          'options': ['4GB', '8GB', '16GB', '32GB', '64GB'],
        },
        {
          'name': 'storage_type',
          'label': 'Storage Type',
          'type': 'dropdown',
          'required': true,
          'category': 'technical',
          'options': ['HDD', 'SSD', 'Hybrid'],
        },
        {
          'name': 'storage_capacity',
          'label': 'Storage Capacity',
          'type': 'dropdown',
          'required': true,
          'category': 'technical',
          'options': ['256GB', '512GB', '1TB', '2TB', '4TB+'],
        },
        {
          'name': 'screen_size',
          'label': 'Screen Size',
          'type': 'text',
          'required': false,
          'category': 'display',
          'suffix': 'inches',
          'hint': 'e.g., 15.6',
        },
        {
          'name': 'graphics_card',
          'label': 'Graphics Card',
          'type': 'text',
          'required': false,
          'category': 'technical',
          'hint': 'e.g., NVIDIA GTX 1650',
        },
        {
          'name': 'operating_system',
          'label': 'Operating System',
          'type': 'dropdown',
          'required': false,
          'category': 'software',
          'options': ['Windows 11', 'Windows 10', 'macOS', 'Linux', 'DOS', 'Other'],
        },
      ],

      // ELECTRONICS - General
      'Mobiles & Electronics': [
        {
          'name': 'warranty',
          'label': AppLocalizations.warranty.tr(),
          'type': 'dropdown',
          'required': false,
          'category': 'service',
          'options': [
            AppLocalizations.noWarranty.tr(),
            '6 Months',
            AppLocalizations.oneYear.tr(),
            '2 Years',
            '3+ Years'
          ],
        },
        {
          'name': 'power_consumption',
          'label': 'Power Consumption',
          'type': 'text',
          'required': false,
          'category': 'technical',
          'suffix': 'Watts',
          'hint': 'e.g., 150W',
        },
      ],

      // REAL ESTATE - Enhanced
      'property': [
        {
          'name': 'property_type',
          'label': 'Property Type',
          'type': 'dropdown',
          'required': true,
          'category': 'classification',
          'options': ['House', 'Apartment', 'Villa', 'Plot', 'Commercial', 'Office'],
        },
        {
          'name': 'area',
          'label': AppLocalizations.areaSqFt.tr(),
          'type': 'number',
          'required': true,
          'category': 'size',
          'suffix': 'sq ft',
          'validation': {'min': 100, 'max': 100000},
        },
        {
          'name': 'bedrooms',
          'label': AppLocalizations.bedrooms.tr(),
          'type': 'dropdown',
          'required': true,
          'category': 'layout',
          'options': ['1', '2', '3', '4', '5', '6+'],
        },
        {
          'name': 'bathrooms',
          'label': AppLocalizations.bathrooms.tr(),
          'type': 'dropdown',
          'required': true,
          'category': 'layout',
          'options': ['1', '2', '3', '4', '5+'],
        },
        {
          'name': 'furnished',
          'label': AppLocalizations.furnished.tr(),
          'type': 'dropdown',
          'required': true,
          'category': 'condition',
          'options': [
            AppLocalizations.furnishedOption.tr(),
            AppLocalizations.semiFurnished.tr(),
            AppLocalizations.unfurnished.tr()
          ],
        },
        {
          'name': 'parking',
          'label': 'Parking',
          'type': 'boolean',
          'required': false,
          'category': 'amenities',
        },
        {
          'name': 'purpose',
          'label': 'Purpose',
          'type': 'dropdown',
          'required': true,
          'category': 'classification',
          'options': ['For Sale', 'For Rent'],
        },
      ],

      // FASHION - New
      'Fashion': [
        {
          'name': 'size',
          'label': 'Size',
          'type': 'dropdown',
          'required': true,
          'category': 'sizing',
          'options': ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'],
        },
        {
          'name': 'color',
          'label': 'Color',
          'type': 'color_picker',
          'required': true,
          'category': 'appearance',
          'options': ['Black', 'White', 'Red', 'Blue', 'Green', 'Yellow', 'Purple', 'Pink', 'Brown', 'Grey', 'Orange', 'Other'],
        },
        {
          'name': 'material',
          'label': 'Material',
          'type': 'text',
          'required': false,
          'category': 'quality',
          'hint': 'e.g., Cotton, Polyester, Silk',
        },
        {
          'name': 'gender',
          'label': 'Gender',
          'type': 'dropdown',
          'required': true,
          'category': 'classification',
          'options': ['Men', 'Women', 'Unisex', 'Kids'],
        },
      ],

      // HOME & GARDEN - New
      'Home & Garden': [
        {
          'name': 'room_type',
          'label': 'Room Type',
          'type': 'dropdown',
          'required': false,
          'category': 'classification',
          'options': ['Living Room', 'Bedroom', 'Kitchen', 'Bathroom', 'Garden', 'Office', 'Dining Room'],
        },
        {
          'name': 'material',
          'label': 'Material',
          'type': 'text',
          'required': false,
          'category': 'quality',
          'hint': 'e.g., Wood, Metal, Plastic, Glass',
        },
        {
          'name': 'assembly_required',
          'label': 'Assembly Required',
          'type': 'boolean',
          'required': false,
          'category': 'service',
        },
      ],

      // SPORTS & OUTDOOR - New
      'Sports & Outdoor': [
        {
          'name': 'sport_type',
          'label': 'Sport Type',
          'type': 'dropdown',
          'required': false,
          'category': 'classification',
          'options': ['Football', 'Basketball', 'Tennis', 'Cricket', 'Swimming', 'Cycling', 'Running', 'Gym', 'Other'],
        },
        {
          'name': 'size',
          'label': 'Size',
          'type': 'dropdown',
          'required': false,
          'category': 'sizing',
          'options': ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'One Size'],
        },
        {
          'name': 'suitable_for',
          'label': 'Suitable For',
          'type': 'dropdown',
          'required': false,
          'category': 'classification',
          'options': ['Men', 'Women', 'Kids', 'Unisex'],
        },
      ],

      // Categories that don't need condition field
      'Jobs': [],
      'Services': [],
      'Education': [],
    };
  }

  // Enhanced keyword matching with hierarchical suggestions including sub-sub-subcategories
  final Map<String, Map<String, dynamic>> _categoryKeywords = {
    'bmw': {
      'mainCategory': 'Vehicle',
      'subCategory': 'Cars',
      'subSubCategory': 'BMW',
      'subSubSubCategory': null,
      'path': ['Vehicle', 'Cars', 'BMW']
    },
    'bmw 220': {
      'mainCategory': 'Vehicle',
      'subCategory': 'Cars',
      'subSubCategory': 'BMW',
      'subSubSubCategory': 'BMW 220',
      'path': ['Vehicle', 'Cars', 'BMW', 'BMW 220']
    },
    'bmw 320': {
      'mainCategory': 'Vehicle',
      'subCategory': 'Cars',
      'subSubCategory': 'BMW',
      'subSubSubCategory': 'BMW 320',
      'path': ['Vehicle', 'Cars', 'BMW', 'BMW 320']
    },
    'bmw 520': {
      'mainCategory': 'Vehicle',
      'subCategory': 'Cars',
      'subSubCategory': 'BMW',
      'subSubSubCategory': 'BMW 520',
      'path': ['Vehicle', 'Cars', 'BMW', 'BMW 520']
    },
    'mercedes': {
      'mainCategory': 'Vehicle',
      'subCategory': 'Cars', 
      'subSubCategory': 'Mercedes',
      'subSubSubCategory': null,
      'path': ['Vehicle', 'Cars', 'Mercedes']
    },
    'toyota': {
      'mainCategory': 'Vehicle',
      'subCategory': 'Cars',
      'subSubCategory': 'Toyota',
      'subSubSubCategory': null,
      'path': ['Vehicle', 'Cars', 'Toyota']
    },
    'honda': {
      'mainCategory': 'Vehicle',
      'subCategory': 'Cars',
      'subSubCategory': 'Honda',
      'subSubSubCategory': null,
      'path': ['Vehicle', 'Cars', 'Honda']
    },
    'iphone': {
      'mainCategory': 'Mobiles & Electronics',
      'subCategory': 'Mobiles',
      'subSubCategory': 'iPhone',
      'subSubSubCategory': null,
      'path': ['Mobiles & Electronics', 'Mobiles', 'iPhone']
    },
    'samsung': {
      'mainCategory': 'Mobiles & Electronics',
      'subCategory': 'Mobiles',
      'subSubCategory': 'Samsung',
      'subSubSubCategory': null,
      'path': ['Mobiles & Electronics', 'Mobiles', 'Samsung']
    },
    'macbook': {
      'mainCategory': 'Mobiles & Electronics',
      'subCategory': 'Computers',
      'subSubCategory': 'MacBook',
      'subSubSubCategory': null,
      'path': ['Mobiles & Electronics', 'Computers', 'MacBook']
    },
    'laptop': {
      'mainCategory': 'Mobiles & Electronics',
      'subCategory': 'Computers',
      'subSubCategory': null,
      'subSubSubCategory': null,
      'path': ['Mobiles & Electronics', 'Computers']
    },
    'house': {
      'mainCategory': 'property',
      'subCategory': 'Houses',
      'subSubCategory': null,
      'subSubSubCategory': null,
      'path': ['property', 'Houses']
    },
    'apartment': {
      'mainCategory': 'property',
      'subCategory': 'Apartments',
      'subSubCategory': null,
      'subSubSubCategory': null,
      'path': ['property', 'Apartments']
    },
  };

  Map<String, dynamic>? _suggestedCategoryPath;

  @override
  void initState() {
    super.initState();
    _loadCategories();
     if (widget.productToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEditData();
      });
    }
  }
  // NEW: Load data for editing
  Future<void> _loadEditData() async {
    if (widget.productToEdit == null) return;

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    
    try {
      // Load the existing item data into the provider
      await itemProvider.loadExistingItem(widget.productToEdit!);
      itemProvider.setEditingItemId(widget.productToEdit!.id);
      
      // Pre-fill the text controllers
      _titleController.text = widget.productToEdit!.title;
      _descriptionController.text = widget.productToEdit!.description;
      
      // Pre-select categories
      await _preselectCategories();
      
      developer.log('Edit data loaded successfully');
    } catch (e) {
      developer.log('Error loading edit data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load item data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // NEW: Pre-select categories based on the product being edited
  Future<void> _preselectCategories() async {
    if (widget.productToEdit?.category == null) return;

    // Wait for categories to load
    while (_isLoadingCategories) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    try {
      final productCategory = widget.productToEdit!.category!;
      
      // Find the category in our loaded categories
      final category = _categories.firstWhere(
        (cat) => cat['id'] == productCategory,
        orElse: () => <String, dynamic>{},
      );

      if (category.isEmpty) {
        developer.log('Category not found: $productCategory');
        return;
      }

      // Determine the category hierarchy
      await _buildCategoryHierarchy(category);
      
    } catch (e) {
      developer.log('Error preselecting categories: $e');
    }
  }

  // NEW: Build category hierarchy for editing
  Future<void> _buildCategoryHierarchy(Map<String, dynamic> category) async {
    final level = category['level'] ?? 0;
    
    switch (level) {
      case 0: // Main category
        setState(() {
          _selectedMainCategoryId = category['id'];
          _selectedCategoryName = category['name'];
        });
        _loadSubCategories(_selectedMainCategoryId!);
        break;
        
      case 1: // Subcategory
        // Find parent main category
        final parentCategory = _categories.firstWhere(
          (cat) => cat['id'] == category['parentId'],
          orElse: () => <String, dynamic>{},
        );
        
        if (parentCategory.isNotEmpty) {
          setState(() {
            _selectedMainCategoryId = parentCategory['id'];
            _selectedSubCategoryId = category['id'];
            _selectedCategoryName = category['name'];
          });
          _loadSubCategories(_selectedMainCategoryId!);
          _loadSubSubCategories(_selectedSubCategoryId!);
        }
        break;
        
      case 2: // Sub-subcategory
        // Build full hierarchy
        await _buildFullHierarchy(category);
        break;
        
      case 3: // Sub-sub-subcategory
        // Build full hierarchy
        await _buildFullHierarchy(category);
        break;
    }
  }

  // NEW: Build full category hierarchy
  Future<void> _buildFullHierarchy(Map<String, dynamic> category) async {
    final categoryPath = <Map<String, dynamic>>[];
    Map<String, dynamic> currentCategory = category;
    
    // Build path from bottom to top
    while (currentCategory.isNotEmpty) {
      categoryPath.insert(0, currentCategory);
      
      final parentId = currentCategory['parentId'];
      if (parentId == null) break;
      
      currentCategory = _categories.firstWhere(
        (cat) => cat['id'] == parentId,
        orElse: () => <String, dynamic>{},
      );
    }
    
    // Apply the hierarchy
    if (categoryPath.isNotEmpty) {
      setState(() {
        if (categoryPath.length >= 1) {
          _selectedMainCategoryId = categoryPath[0]['id'];
        }
        if (categoryPath.length >= 2) {
          _selectedSubCategoryId = categoryPath[1]['id'];
        }
        if (categoryPath.length >= 3) {
          _selectedSubSubCategoryId = categoryPath[2]['id'];
        }
        if (categoryPath.length >= 4) {
          _selectedSubSubSubCategoryId = categoryPath[3]['id'];
        }
        _selectedCategoryName = categoryPath.last['name'];
      });
      
      // Load all subcategories
      if (_selectedMainCategoryId != null) {
        _loadSubCategories(_selectedMainCategoryId!);
        if (_selectedSubCategoryId != null) {
          _loadSubSubCategories(_selectedSubCategoryId!);
          if (_selectedSubSubCategoryId != null) {
            _loadSubSubSubCategories(_selectedSubSubCategoryId!);
          }
        }
      }
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Load categories from Firestore with hierarchy
  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoadingCategories = true;
      });

      print('Loading categories from Firestore...');
      
      // Try different queries to handle potential Firestore issues
      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('categories')
            .where('isActive', isEqualTo: true)
            .orderBy('level')
            .orderBy('order')
            .get();
      } catch (e) {
        print('First query failed, trying without orderBy: $e');
        // Try without orderBy if the first query fails
        snapshot = await FirebaseFirestore.instance
            .collection('categories')
            .where('isActive', isEqualTo: true)
            .get();
      }

      print('Firestore query returned ${snapshot.docs.length} documents');

      final loadedCategories = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        print('Loaded category: ${data['name']} (ID: ${doc.id}, Level: ${data['level']}, Active: ${data['isActive']})');
        return data;
      }).toList();

      // Sort categories by level and order if available
      loadedCategories.sort((a, b) {
        final levelA = (a['level'] as int?) ?? 0;
        final levelB = (b['level'] as int?) ?? 0;
        if (levelA != levelB) return levelA.compareTo(levelB);
        
        final orderA = (a['order'] as int?) ?? 0;
        final orderB = (b['order'] as int?) ?? 0;
        return orderA.compareTo(orderB);
      });

      // Separate categories by level
      _mainCategories = loadedCategories.where((cat) => cat['level'] == 0).toList();
      
      print('Main categories found: ${_mainCategories.length}');
      for (final cat in _mainCategories) {
        print('Main category: ${cat['name']} (ID: ${cat['id']}, Level: ${cat['level']})');
      }
      
      setState(() {
        _categories = loadedCategories;
        _isLoadingCategories = false;
      });

      print('Loaded ${_categories.length} categories (${_mainCategories.length} main categories)');
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
        _categories = [];
        _mainCategories = [];
      });
    }
  }

  // Load subcategories when main category is selected
  void _loadSubCategories(String mainCategoryId) {
    _subCategories = _categories
        .where((cat) => cat['parentId'] == mainCategoryId && cat['level'] == 1)
        .toList();
    
    // Reset sub-subcategories and sub-sub-subcategories
    _subSubCategories = [];
    _subSubSubCategories = [];
    _selectedSubCategoryId = null;
    _selectedSubSubCategoryId = null;
    _selectedSubSubSubCategoryId = null;
    
    // Load category-specific fields
    _loadCategorySpecificFields(mainCategoryId);
    
    setState(() {});
    
    print('Loaded ${_subCategories.length} subcategories for main category: $mainCategoryId');
    for (final cat in _subCategories) {
      print('Subcategory: ${cat['name']} (ID: ${cat['id']})');
    }
  }

  // Load sub-subcategories when subcategory is selected
  void _loadSubSubCategories(String subCategoryId) {
    _subSubCategories = _categories
        .where((cat) => cat['parentId'] == subCategoryId && cat['level'] == 2)
        .toList();
    
    // Reset sub-sub-subcategories
    _subSubSubCategories = [];
    _selectedSubSubCategoryId = null;
    _selectedSubSubSubCategoryId = null;
    
    setState(() {});
    
    print('Loaded ${_subSubCategories.length} sub-subcategories for subcategory: $subCategoryId');
    for (final cat in _subSubCategories) {
      print('Sub-subcategory: ${cat['name']} (ID: ${cat['id']})');
    }
  }

  // Load sub-sub-subcategories when sub-subcategory is selected
  void _loadSubSubSubCategories(String subSubCategoryId) {
    _subSubSubCategories = _categories
        .where((cat) => cat['parentId'] == subSubCategoryId && cat['level'] == 3)
        .toList();
    
    _selectedSubSubSubCategoryId = null;
    setState(() {});
    
    print('Loaded ${_subSubSubCategories.length} sub-sub-subcategories for parent: $subSubCategoryId');
    for (final cat in _subSubSubCategories) {
      print('Sub-sub-subcategory: ${cat['name']} (ID: ${cat['id']})');
    }
  }

  // ENHANCED: Load category-specific fields with inheritance and field organization
  void _loadCategorySpecificFields(String categoryId) {
    final category = _categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => <String, dynamic>{},
    );
    
    final categoryName = category['name'] ?? '';
    
    // Get fields from template
    List<Map<String, dynamic>> fields = [];
    
    // Check for exact match first
    if (_categoryFieldTemplates.containsKey(categoryName)) {
      fields = List<Map<String, dynamic>>.from(_categoryFieldTemplates[categoryName]!);
    } else {
      // Check for parent category inheritance
      final parentId = category['parentId'];
      if (parentId != null) {
        final parentCategory = _categories.firstWhere(
          (cat) => cat['id'] == parentId,
          orElse: () => <String, dynamic>{},
        );
        final parentName = parentCategory['name'] ?? '';
        if (_categoryFieldTemplates.containsKey(parentName)) {
          fields = List<Map<String, dynamic>>.from(_categoryFieldTemplates[parentName]!);
        }
      }
    }
    
    setState(() {
      _currentCategoryFields = fields.map((field) => field['name'] as String).toList();
      // Initialize field values
      for (final field in fields) {
        if (!_categorySpecificFields.containsKey(field['name'])) {
          _categorySpecificFields[field['name']] = null;
        }
      }
    });

    // NEW: Update ItemProvider with category template and fields
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    itemProvider.setCategoryTemplate(fields, categoryName);
    itemProvider.updateCategorySpecificFields(_categorySpecificFields);
    
    print('Loaded ${fields.length} category-specific fields for $categoryName');
  }

  // Enhanced category suggestion with hierarchical path
  void _suggestCategory(String title, String description) {
    // Don't suggest if categories are not loaded yet
    if (_isLoadingCategories || _mainCategories.isEmpty) {
      print('Categories not loaded yet, skipping suggestion');
      return;
    }
    
    String combinedText = (title + ' ' + description).toLowerCase();
    
    print('Suggesting category for text: "$combinedText"');
    print('Title: "$title"');
    print('Description: "$description"');
    print('Combined text length: ${combinedText.length}');
    print('Combined text bytes: ${combinedText.codeUnits}');
    
    // Test basic matching
    print('Testing basic matching:');
    print('combinedText.contains("bmw"): ${combinedText.contains("bmw")}');
    print('combinedText.contains("220"): ${combinedText.contains("220")}');
    print('combinedText.contains("bmw 220"): ${combinedText.contains("bmw 220")}');
    
    // Test with trimmed text
    String trimmedText = combinedText.trim();
    print('Trimmed text: "$trimmedText"');
    print('trimmedText.contains("bmw 220"): ${trimmedText.contains("bmw 220")}');
    
    // Test exact matching
    print('Exact match test:');
    print('trimmedText == "bmw 220": ${trimmedText == "bmw 220"}');
    print('trimmedText == "bmw": ${trimmedText == "bmw"}');
    
    // Test with different case
    print('Case insensitive test:');
    print('trimmedText.contains("BMW 220"): ${trimmedText.contains("BMW 220")}');
    print('trimmedText.contains("BMW"): ${trimmedText.contains("BMW")}');
    
    // Check for specific keyword matches (longer matches first)
    List<String> sortedKeywords = _categoryKeywords.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length)); // Sort by length descending
    
    print('Sorted keywords: $sortedKeywords');
    print('Keywords map contains "bmw 220": ${_categoryKeywords.containsKey("bmw 220")}');
    print('Keywords map contains "bmw": ${_categoryKeywords.containsKey("bmw")}');
    
    for (final keyword in sortedKeywords) {
      print('Checking keyword: "$keyword" against text: "$combinedText"');
      if (combinedText.contains(keyword.toLowerCase())) {
        print('Found match for keyword: "$keyword"');
        setState(() {
          _suggestedCategoryPath = _categoryKeywords[keyword];
        });
        return;
      }
    }
    
    // Try partial matching for multi-word keywords
    for (final keyword in sortedKeywords) {
      final keywordWords = keyword.toLowerCase().split(' ');
      if (keywordWords.length > 1) {
        bool allWordsFound = true;
        for (final word in keywordWords) {
          if (!combinedText.contains(word)) {
            allWordsFound = false;
            break;
          }
        }
        if (allWordsFound) {
          print('Found partial match for keyword: "$keyword"');
          setState(() {
            _suggestedCategoryPath = _categoryKeywords[keyword];
          });
          return;
        }
      }
    }
    
    print('No keyword matches found');
    // Clear suggestion if no match found
    setState(() {
      _suggestedCategoryPath = null;
    });
  }

// Enhanced _applySuggestedCategory method with proper hierarchy navigation
void _applySuggestedCategory() async {
  if (_suggestedCategoryPath == null) return;

  print('Applying suggested category path: $_suggestedCategoryPath');

  // Check if categories are loaded
  if (_isLoadingCategories) {
    print('Categories are still loading, please wait...');
    return;
  }

  if (_mainCategories.isEmpty) {
    print('No main categories available. Categories may not be loaded yet.');
    await _loadCategories();
    if (_mainCategories.isEmpty) {
      print('Still no categories after reload. Please check Firestore data.');
      return;
    }
  }

  final mainCategoryName = _suggestedCategoryPath!['mainCategory'];
  final subCategoryName = _suggestedCategoryPath!['subCategory'];
  final subSubCategoryName = _suggestedCategoryPath!['subSubCategory'];
  final subSubSubCategoryName = _suggestedCategoryPath!['subSubSubCategory'];

  print('Target path:');
  print('  Main: $mainCategoryName');
  print('  Sub: $subCategoryName');
  print('  Sub-Sub: $subSubCategoryName');
  print('  Sub-Sub-Sub: $subSubSubCategoryName');

  try {
    // Step 1: Find and set main category
    final mainCategory = _mainCategories.firstWhere(
      (cat) => cat['name']?.toString().toLowerCase() == mainCategoryName?.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );

    // if (mainCategory.isEmpty) {
    //   print('Main category "$mainCategoryName" not found');
    //   _showCategoryNotFoundDialog(mainCategoryName);
    //   return;
    // }

    print('✓ Found main category: ${mainCategory['name']} (ID: ${mainCategory['id']})');
    
    // Set main category
    setState(() {
      _selectedMainCategoryId = mainCategory['id'];
      _selectedCategoryName = mainCategory['name'];
      _selectedSubCategoryId = null;
      _selectedSubSubCategoryId = null;
      _selectedSubSubSubCategoryId = null;
    });

    // Load subcategories
    _loadSubCategories(_selectedMainCategoryId!);

    // Step 2: Find and set subcategory if specified
    if (subCategoryName != null && _subCategories.isNotEmpty) {
      final subCategory = _subCategories.firstWhere(
        (cat) => cat['name']?.toString().toLowerCase() == subCategoryName.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      if (subCategory.isNotEmpty) {
        print('✓ Found subcategory: ${subCategory['name']} (ID: ${subCategory['id']})');
        setState(() {
          _selectedSubCategoryId = subCategory['id'];
          _selectedCategoryName = subCategory['name'];
        });

        // Load sub-subcategories
        _loadSubSubCategories(_selectedSubCategoryId!);

        // Step 3: Find and set sub-subcategory if specified
        if (subSubCategoryName != null && _subSubCategories.isNotEmpty) {
          final subSubCategory = _subSubCategories.firstWhere(
            (cat) => cat['name']?.toString().toLowerCase() == subSubCategoryName.toLowerCase(),
            orElse: () => <String, dynamic>{},
          );

          if (subSubCategory.isNotEmpty) {
            print('✓ Found sub-subcategory: ${subSubCategory['name']} (ID: ${subSubCategory['id']})');
            setState(() {
              _selectedSubSubCategoryId = subSubCategory['id'];
              _selectedCategoryName = subSubCategory['name'];
            });

            // Load sub-sub-subcategories
            _loadSubSubSubCategories(_selectedSubSubCategoryId!);

            // Step 4: Find and set sub-sub-subcategory if specified
            if (subSubSubCategoryName != null && _subSubSubCategories.isNotEmpty) {
              final subSubSubCategory = _subSubSubCategories.firstWhere(
                (cat) => cat['name']?.toString().toLowerCase() == subSubSubCategoryName.toLowerCase(),
                orElse: () => <String, dynamic>{},
              );

              if (subSubSubCategory.isNotEmpty) {
                print('✓ Found sub-sub-subcategory: ${subSubSubCategory['name']} (ID: ${subSubSubCategory['id']})');
                setState(() {
                  _selectedSubSubSubCategoryId = subSubSubCategory['id'];
                  _selectedCategoryName = subSubSubCategory['name'];
                });
              } else {
                print('⚠️ Sub-sub-subcategory "$subSubSubCategoryName" not found in database');
                print('Available sub-sub-subcategories: ${_subSubSubCategories.map((cat) => cat['name']).join(', ')}');
              }
            } else if (subSubSubCategoryName != null) {
              print('⚠️ No sub-sub-subcategories available for "${subSubCategory['name']}"');
            }
          } else {
            print('⚠️ Sub-subcategory "$subSubCategoryName" not found in database');
            print('Available sub-subcategories: ${_subSubCategories.map((cat) => cat['name']).join(', ')}');
          }
        } else if (subSubCategoryName != null) {
          print('⚠️ No sub-subcategories available for "${subCategory['name']}"');
        }
      } else {
        print('⚠️ Subcategory "$subCategoryName" not found in database');
        print('Available subcategories: ${_subCategories.map((cat) => cat['name']).join(', ')}');
      }
    } else if (subCategoryName != null) {
      print('⚠️ No subcategories available for "${mainCategory['name']}"');
    }

    // Final update to ItemProvider with the deepest selected category
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final finalCategoryId = _selectedSubSubSubCategoryId ?? 
                            _selectedSubSubCategoryId ?? 
                            _selectedSubCategoryId ?? 
                            _selectedMainCategoryId;
    
    print('Final selection:');
    print('  Category ID: $finalCategoryId');
    print('  Category Name: $_selectedCategoryName');
    
    itemProvider.updateItemDetails(
      category: finalCategoryId,
      categoryName: _selectedCategoryName,
    );

    // Clear suggestion after successful application
    setState(() {
      _suggestedCategoryPath = null;
    });
    
    print('✅ Smart suggestion applied successfully!');
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category set to: $_selectedCategoryName'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

  } catch (e) {
    print('❌ Error applying suggestion: $e');
    // _showErrorDialog('Failed to apply suggestion: $e');
  }
}



  // Enhanced validation - hide errors when corrected
  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.pleaseEnterItemTitle.tr();
    }
    if (value.length < 10) {
      return AppLocalizations.titleMustBe10Characters.tr();
    }
    return null; // Return null when valid - this hides the error
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.pleaseEnterDescription.tr();
    }
    
    List<String> words = value.trim().split(RegExp(r'\s+'));
    words = words.where((word) => word.isNotEmpty).toList();
    
    if (words.length < 10) {
      return AppLocalizations.descriptionMustContain10Words.tr(args: ['${words.length}']);
    }
    return null; // Return null when valid - this hides the error
  }

  // Check if category needs condition field
  bool _shouldShowConditionField() {
    if (_selectedMainCategoryId == null) return true;
    
    final category = _mainCategories.firstWhere(
      (cat) => cat['id'] == _selectedMainCategoryId,
      orElse: () => <String, dynamic>{},
    );
    
    final categoryName = category['name'] ?? '';
    
    // Categories that don't need condition field
    final noConditionCategories = ['Jobs', 'Services', 'Education'];
    return !noConditionCategories.contains(categoryName);
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    bool isEditMode = widget.productToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: widget.isMain ? false : true,
        elevation: 0,
        title: Text(
     isEditMode ? 'Edit Item' :   AppLocalizations.itemDetails.tr(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        // Quick category selection dropdown
       actions: isEditMode ? [
          TextButton(
            onPressed: itemProvider.isPublishing ? null : () async {
              if (_formKey.currentState!.validate()) {
                final success = await itemProvider.publishOrUpdateItem(context);
                if (success) {
                  Navigator.pop(context, true); // Return true to indicate success
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Item updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text(
              itemProvider.isPublishing ? 'Updating...' : 'Update',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: itemProvider.isPublishing ? Colors.grey : ColorsController.primaryColor,
              ),
            ),
          ),
        ] : [
          PopupMenuButton<String>(
            icon: Icon(Icons.category_outlined, color: Colors.black),
            onSelected: (categoryId) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategorySelectionPage(
                    categories: _categories,
                    mainCategories: _mainCategories,
                    selectedMainCategoryId: categoryId,
                  ),
                ),
              ).then((result) {
                if (result != null) {
                  setState(() {
                    _selectedMainCategoryId = result['mainCategoryId'];
                    _selectedSubCategoryId = result['subCategoryId'];
                    _selectedSubSubCategoryId = result['subSubCategoryId'];
                    _selectedSubSubSubCategoryId = result['subSubSubCategoryId'];
                    _selectedCategoryName = result['categoryName'];
                  });

                  if (_selectedMainCategoryId != null) {
                    _loadSubCategories(_selectedMainCategoryId!);
                    if (_selectedSubCategoryId != null) {
                      _loadSubSubCategories(_selectedSubCategoryId!);
                      if (_selectedSubSubCategoryId != null) {
                        _loadSubSubSubCategories(_selectedSubSubCategoryId!);
                      }
                    }
                  }

                  final finalCategoryId = _selectedSubSubSubCategoryId ?? 
                                          _selectedSubSubCategoryId ?? 
                                          _selectedSubCategoryId ?? 
                                          _selectedMainCategoryId;
                  itemProvider.updateItemDetails(
                    category: finalCategoryId,
                    categoryName: _selectedCategoryName,
                  );
                }
              });
            },
            itemBuilder: (context) => _mainCategories.map((category) {
              return PopupMenuItem<String>(
                value: category['id'],
                child: Text(
                  category['name'] ?? 'Unknown',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              );
            }).toList(),
            tooltip: AppLocalizations.quickCategorySelection.tr(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.describeYourItem.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.completeTheseDetails.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Title Field with Character Counter
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: _titleController,
                            hint: AppLocalizations.itemTitle.tr(),
                            onChanged: (value) {
                              print('Title changed to: "$value"');
                              itemProvider.updateItemDetails(itemTitle: value);
                              _suggestCategory(value, _descriptionController.text);
                              // Trigger form validation to hide errors when fixed
                              _formKey.currentState?.validate();
                            },
                            validator: _validateTitle,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '${AppLocalizations.minimum10Characters.tr()} (${_titleController.text.length}/10)',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _titleController.text.length >= 10 
                                    ? Colors.green[600] 
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                     
                      // Hierarchical Category Selection with direct navigation
                      if (_isLoadingCategories)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(ColorsController.primaryColor),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                AppLocalizations.loadingCategories.tr(),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        _buildHierarchicalCategorySelection(itemProvider),
                     
                      const SizedBox(height: 16),
                     
                      // Conditionally show condition field
                      if (_shouldShowConditionField())
                        Column(
                          children: [
                            _buildDropdownField(
                              hint: AppLocalizations.condition.tr(),
                              items: [
                                AppLocalizations.newItem.tr(),
                                AppLocalizations.likeNew.tr(),
                                AppLocalizations.used.tr(),
                                AppLocalizations.refurbished.tr()
                              ],
                              selectedValue: itemProvider.condition.isEmpty ? null : itemProvider.condition,
                              onChanged: (value) => itemProvider.updateItemDetails(condition: value),
                              validator: (value) => value == null ? AppLocalizations.pleaseSelectCondition.tr() : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                     
                      // Description Field with Word Counter
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: _descriptionController,
                            hint: AppLocalizations.description.tr(),
                            onChanged: (value) {
                              print('Description changed to: "$value"');
                              itemProvider.updateItemDetails(description: value);
                              _suggestCategory(_titleController.text, value);
                              // Trigger form validation to hide errors when fixed
                              _formKey.currentState?.validate();
                            },
                            maxLines: 4,
                            validator: _validateDescription,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Consumer<ItemProvider>(
                              builder: (context, provider, child) {
                                List<String> words = _descriptionController.text.trim().split(RegExp(r'\s+'));
                                words = words.where((word) => word.isNotEmpty).toList();
                                int wordCount = _descriptionController.text.isEmpty ? 0 : words.length;
                               
                                return Text(
                                  '${AppLocalizations.minimum10Words.tr()} ($wordCount/10)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: wordCount >= 10 
                                        ? Colors.green[600] 
                                        : Colors.grey[600],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                     
                      // ENHANCED: Category-specific fields with better organization
                      ..._buildCategorySpecificFields(),
                     
                      // Show brand field if not in category-specific fields
                      if (!_currentCategoryFields.contains('brand'))
                        Column(
                          children: [
                            _buildTextField(
                              hint: AppLocalizations.brand.tr(),
                              onChanged: (value) => itemProvider.updateItemDetails(brand: value),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                     
                      _buildTextField(
                        hint: AppLocalizations.dimensionsSize.tr(),
                        onChanged: (value) => itemProvider.updateItemDetails(dimensions: value),
                      ),
                      const SizedBox(height: 16),
                     
                      // Show color field only if not handled by category-specific fields
                      if (!_currentCategoryFields.contains('color'))
                        Column(
                          children: [
                            _buildTextField(
                              hint: AppLocalizations.color.tr(),
                              onChanged: (value) => itemProvider.updateItemDetails(color: value),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EnhancedPricingShippingPage()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsController.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.next.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
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
    );
  }

  // Hierarchical category selection with direct navigation
  Widget _buildHierarchicalCategorySelection(ItemProvider itemProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Category Selection - Navigate directly to subcategory page
        InkWell(
          onTap: () async {
            // Navigate to category hierarchy selection page
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategorySelectionPage(
                  categories: _categories,
                  mainCategories: _mainCategories,
                ),
              ),
            );

            if (result != null) {
              setState(() {
                _selectedMainCategoryId = result['mainCategoryId'];
                _selectedSubCategoryId = result['subCategoryId'];
                _selectedSubSubCategoryId = result['subSubCategoryId'];
                _selectedSubSubSubCategoryId = result['subSubSubCategoryId'];
                _selectedCategoryName = result['categoryName'];
              });

              if (_selectedMainCategoryId != null) {
                _loadSubCategories(_selectedMainCategoryId!);
                if (_selectedSubCategoryId != null) {
                  _loadSubSubCategories(_selectedSubCategoryId!);
                  if (_selectedSubSubCategoryId != null) {
                    _loadSubSubSubCategories(_selectedSubSubCategoryId!);
                  }
                }
              }

              final finalCategoryId = _selectedSubSubSubCategoryId ?? 
                                      _selectedSubSubCategoryId ?? 
                                      _selectedSubCategoryId ?? 
                                      _selectedMainCategoryId;
              itemProvider.updateItemDetails(
                category: finalCategoryId,
                categoryName: _selectedCategoryName,
              );
            }
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCategoryName ?? AppLocalizations.selectCategory.tr(),
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: _selectedCategoryName != null ? Colors.black : Colors.grey[500],
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
       
        // Enhanced category suggestion with full path
        if (_suggestedCategoryPath != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorsController.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ColorsController.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: ColorsController.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.smartSuggestion.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: ColorsController.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        (_suggestedCategoryPath!['path'] as List).join(' > '),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: ColorsController.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _applySuggestedCategory,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    AppLocalizations.apply.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: ColorsController.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ENHANCED: Build category-specific fields with multiple field types
  List<Widget> _buildCategorySpecificFields() {
    if (_selectedMainCategoryId == null) return [];
   
    final mainCategory = _mainCategories.firstWhere(
      (cat) => cat['id'] == _selectedMainCategoryId,
      orElse: () => <String, dynamic>{},
    );
   
    final categoryName = mainCategory['name'] ?? '';
    List<Map<String, dynamic>> fields = [];
    
    // Get fields from template with inheritance logic
    if (_categoryFieldTemplates.containsKey(categoryName)) {
      fields = List<Map<String, dynamic>>.from(_categoryFieldTemplates[categoryName]!);
    } else {
      // Check for parent category inheritance
      final parentId = mainCategory['parentId'];
      if (parentId != null) {
        final parentCategory = _categories.firstWhere(
          (cat) => cat['id'] == parentId,
          orElse: () => <String, dynamic>{},
        );
        final parentName = parentCategory['name'] ?? '';
        if (_categoryFieldTemplates.containsKey(parentName)) {
          fields = List<Map<String, dynamic>>.from(_categoryFieldTemplates[parentName]!);
        }
      }
    }
   
    if (fields.isEmpty) return [];
   
    List<Widget> widgets = [
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          '${categoryName} ${AppLocalizations.specificDetails.tr()}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    ];

    // Group fields by category
    final organizedFields = <String, List<Map<String, dynamic>>>{};
    for (final field in fields) {
      final category = field['category'] ?? 'general';
      organizedFields.putIfAbsent(category, () => []).add(field);
    }

    // Build fields organized by category
    for (final categoryEntry in organizedFields.entries) {
      if (organizedFields.keys.length > 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _getCategoryDisplayName(categoryEntry.key),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorsController.primaryColor,
              ),
            ),
          ),
        );
      }

      for (final field in categoryEntry.value) {
        widgets.add(_buildDynamicField(field));
        widgets.add(const SizedBox(height: 16));
      }
    }
    
    return widgets;
  }

  // ENHANCED: Build dynamic field based on type
   Widget _buildDynamicField(Map<String, dynamic> field) {
    final fieldType = field['type'] ?? 'text';
    
    switch (fieldType) {
      case 'dropdown':
        return _buildDropdownField(
          hint: field['label'],
          items: List<String>.from(field['options'] ?? []),
          selectedValue: _categorySpecificFields[field['name']],
          onChanged: (value) {
            setState(() {
              _categorySpecificFields[field['name']] = value;
            });
            // NEW: Update ItemProvider
            final itemProvider = Provider.of<ItemProvider>(context, listen: false);
            itemProvider.updateCategoryField(field['name'], value);
          },
          validator: field['required'] == true 
              ? (value) => value == null ? AppLocalizations.pleaseSelectField.tr(args: [field['label']]) : null
              : null,
        );
      
      case 'number':
        return _buildNumberField(field);
      
      case 'boolean':
        return _buildBooleanField(field);
      
      case 'color_picker':
        return _buildColorPickerField(field);
      
      case 'year_picker':
        return _buildYearPickerField(field);
      
      case 'text':
      default:
        return _buildTextField(
          hint: field['label'],
          keyboardType: fieldType == 'number' ? TextInputType.number : TextInputType.text,
          onChanged: (value) {
            setState(() {
              _categorySpecificFields[field['name']] = value;
            });
            // NEW: Update ItemProvider
            final itemProvider = Provider.of<ItemProvider>(context, listen: false);
            itemProvider.updateCategoryField(field['name'], value);
          },
          validator: field['required'] == true 
              ? (value) => value?.isEmpty == true ? AppLocalizations.pleaseEnterField.tr(args: [field['label']]) : null
              : null,
        );
    }
  }


  // Build number field with validation
  Widget _buildNumberField(Map<String, dynamic> field) {
    return TextFormField(
      keyboardType: TextInputType.number,
      style: GoogleFonts.jost(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: field['label'],
        suffixText: field['suffix'],
        hintStyle: GoogleFonts.jost(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.grey[500],
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.black, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      onChanged: (value) {
        final numValue = double.tryParse(value);
        setState(() {
          _categorySpecificFields[field['name']] = numValue;
        });
        // NEW: Update ItemProvider
        final itemProvider = Provider.of<ItemProvider>(context, listen: false);
        itemProvider.updateCategoryField(field['name'], numValue);
      },
      validator: (value) {
        if (field['required'] == true && (value == null || value.isEmpty)) {
          return '${field['label']} is required';
        }
        
        if (value != null && value.isNotEmpty) {
          final numValue = double.tryParse(value);
          if (numValue == null) {
            return 'Please enter a valid number';
          }
          
          final validation = field['validation'] as Map<String, dynamic>?;
          if (validation != null) {
            final min = validation['min'];
            final max = validation['max'];
            
            if (min != null && numValue < min) {
              return 'Value must be at least $min';
            }
            if (max != null && numValue > max) {
              return 'Value must be at most $max';
            }
          }
        }
        
        return null;
      },
    );
  }

  // Build boolean field (switch)
  Widget _buildBooleanField(Map<String, dynamic> field) {
    final value = _categorySpecificFields[field['name']] as bool? ?? false;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: Text(
          field['label'],
          style: GoogleFonts.jost(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        subtitle: field['hint'] != null ? Text(field['hint']) : null,
        value: value,
        onChanged: (newValue) {
          setState(() {
            _categorySpecificFields[field['name']] = newValue;
          });
          // NEW: Update ItemProvider
          final itemProvider = Provider.of<ItemProvider>(context, listen: false);
          itemProvider.updateCategoryField(field['name'], newValue);
        },
        activeColor: ColorsController.primaryColor,
      ),
    );
  }

  // Build color picker field
  Widget _buildColorPickerField(Map<String, dynamic> field) {
    final options = List<String>.from(field['options'] ?? []);
    final selectedColor = _categorySpecificFields[field['name']];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field['label'],
          style: GoogleFonts.jost(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((color) {
            final isSelected = selectedColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _categorySpecificFields[field['name']] = color;
                });
                // NEW: Update ItemProvider
                final itemProvider = Provider.of<ItemProvider>(context, listen: false);
                itemProvider.updateCategoryField(field['name'], color);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? ColorsController.primaryColor : Colors.white,
                  border: Border.all(
                    color: isSelected ? ColorsController.primaryColor : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  color,
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (field['required'] == true && selectedColor == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${field['label']} is required',
              style: GoogleFonts.jost(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }


  // Build year picker field
  Widget _buildYearPickerField(Map<String, dynamic> field) {
    final currentYear = DateTime.now().year;
    final validation = field['validation'] as Map<String, dynamic>?;
    final minYear = validation?['min'] ?? 1950;
    final maxYear = validation?['max'] ?? currentYear + 1;
    
    final years = List.generate(maxYear - minYear + 1, (index) => maxYear - index);
    
    return _buildDropdownField(
      hint: field['label'],
      items: years.map((year) => year.toString()).toList(),
      selectedValue: _categorySpecificFields[field['name']]?.toString(),
      onChanged: (value) {
        final yearValue = int.tryParse(value ?? '');
        setState(() {
          _categorySpecificFields[field['name']] = yearValue;
        });
        // NEW: Update ItemProvider
        final itemProvider = Provider.of<ItemProvider>(context, listen: false);
        itemProvider.updateCategoryField(field['name'], yearValue);
      },
      validator: field['required'] == true 
          ? (value) => value == null ? '${field['label']} is required' : null
          : null,
    );
  }
}


  // Get category display name for organization
  String _getCategoryDisplayName(String categoryKey) {
    switch (categoryKey) {
      case 'basic_info': return 'Basic Information';
      case 'technical': return 'Technical Specifications';
      case 'appearance': return 'Appearance';
      case 'features': return 'Features';
      case 'comfort': return 'Comfort & Convenience';
      case 'connectivity': return 'Connectivity';
      case 'display': return 'Display';
      case 'software': return 'Software';
      case 'classification': return 'Classification';
      case 'design': return 'Design';
      case 'condition': return 'Condition';
      case 'size': return 'Size & Dimensions';
      case 'layout': return 'Layout';
      case 'amenities': return 'Amenities';
      case 'service': return 'Service & Support';
      case 'quality': return 'Quality';
      case 'sizing': return 'Sizing';
      default: return categoryKey.replaceAll('_', ' ').toUpperCase();
    }
  }

  Widget _buildDropdownField({
    required String hint,
    required List<String> items,
    String? selectedValue,
    Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      style: GoogleFonts.jost(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.jost(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.grey[500],
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.black, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.jost(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildTextField({
    required String hint,
    TextEditingController? controller,
    String? initialValue,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    // If initial value is provided and no controller, create a temporary controller
    TextEditingController? tempController;
    if (initialValue != null && controller == null) {
      tempController = TextEditingController(text: initialValue);
    }
    
    return TextFormField(
      controller: controller ?? tempController,
      initialValue: controller == null && tempController == null ? initialValue : null,
      style: GoogleFonts.jost(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.jost(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.grey[500],
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.black, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }

