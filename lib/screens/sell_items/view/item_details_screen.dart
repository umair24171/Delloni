import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/view/add_photos_page.dart';
import 'package:arabicmarketplace/screens/sell_items/view/pricing_shipping.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemDetailsPage extends StatefulWidget {
  const ItemDetailsPage({Key? key, this.isMain = false}) : super(key: key);
  final bool isMain;

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
  // Dropdown field builder for category-specific and condition fields
  
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Categories from Firestore
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _mainCategories = [];
  List<Map<String, dynamic>> _subCategories = [];
  List<Map<String, dynamic>> _subSubCategories = [];
  
  bool _isLoadingCategories = true;
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedSubSubCategoryId;
  String? _selectedCategoryName;

  // Category-specific fields
  Map<String, dynamic> _categorySpecificFields = {};
  List<String> _currentCategoryFields = [];

  // Category field templates
  final Map<String, List<Map<String, dynamic>>> _categoryFieldTemplates = {
    'Vehicles': [
      {'name': 'year', 'label': 'Year', 'type': 'number', 'required': true},
      {'name': 'mileage', 'label': 'Mileage (km)', 'type': 'number', 'required': false},
      {'name': 'fuel_type', 'label': 'Fuel Type', 'type': 'dropdown', 'options': ['Petrol', 'Diesel', 'Electric', 'Hybrid'], 'required': true},
      {'name': 'transmission', 'label': 'Transmission', 'type': 'dropdown', 'options': ['Manual', 'Automatic'], 'required': true},
      {'name': 'engine_capacity', 'label': 'Engine Capacity (cc)', 'type': 'number', 'required': false},
      {'name': 'body_type', 'label': 'Body Type', 'type': 'dropdown', 'options': ['Sedan', 'Hatchback', 'SUV', 'Coupe', 'Convertible'], 'required': false},
    ],
    'Electronics': [
      {'name': 'warranty', 'label': 'Warranty', 'type': 'dropdown', 'options': ['No Warranty', '1 Month', '3 Months', '6 Months', '1 Year', '2+ Years'], 'required': false},
      {'name': 'storage', 'label': 'Storage/Memory', 'type': 'text', 'required': false},
      {'name': 'screen_size', 'label': 'Screen Size', 'type': 'text', 'required': false},
    ],
    'Mobiles': [
      {'name': 'storage', 'label': 'Storage', 'type': 'dropdown', 'options': ['16GB', '32GB', '64GB', '128GB', '256GB', '512GB', '1TB'], 'required': false},
      {'name': 'ram', 'label': 'RAM', 'type': 'dropdown', 'options': ['2GB', '3GB', '4GB', '6GB', '8GB', '12GB', '16GB'], 'required': false},
      {'name': 'warranty', 'label': 'Warranty', 'type': 'dropdown', 'options': ['No Warranty', '1 Month', '3 Months', '6 Months', '1 Year'], 'required': false},
    ],
    'Property for Sale': [
      {'name': 'area', 'label': 'Area (sq ft)', 'type': 'number', 'required': true},
      {'name': 'bedrooms', 'label': 'Bedrooms', 'type': 'number', 'required': false},
      {'name': 'bathrooms', 'label': 'Bathrooms', 'type': 'number', 'required': false},
      {'name': 'furnished', 'label': 'Furnished', 'type': 'dropdown', 'options': ['Furnished', 'Semi-Furnished', 'Unfurnished'], 'required': false},
    ],
  };

  // Enhanced keyword matching with more specific patterns
  final Map<String, List<String>> _categoryKeywords = {
    'Vehicles': ['car', 'vehicle', 'auto', 'toyota', 'honda', 'suzuki', 'mercedes', 'bmw', 'audi', 'bike', 'motorcycle'],
    'Electronics': ['phone', 'laptop', 'computer', 'tablet', 'camera', 'tv', 'headphones', 'speaker', 'electronic'],
    'Mobiles': ['iphone', 'samsung', 'mobile', 'smartphone', 'cell phone', 'android'],
    'Computer & Laptop': ['laptop', 'computer', 'pc', 'desktop', 'macbook', 'dell', 'hp', 'lenovo'],
    'Computer Accessories': ['mouse', 'keyboard', 'monitor', 'cable', 'headset', 'webcam'],
    'Property for Sale': ['house', 'flat', 'apartment', 'land', 'property', 'villa', 'plot'],
    'Home Appliances': ['fridge', 'washing machine', 'microwave', 'oven', 'ac', 'air conditioner'],
    'Clothing': ['shirt', 'dress', 'shoes', 'pants', 'jacket', 'clothes', 'fashion'],
    'Home & Garden': ['furniture', 'chair', 'table', 'sofa', 'bed', 'plant', 'garden'],
    'Sports': ['ball', 'gym', 'fitness', 'bicycle', 'sports', 'equipment', 'exercise'],
    'Books': ['book', 'novel', 'textbook', 'magazine', 'literature'],
  };

  String? _suggestedCategoryName;
  String? _suggestedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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

      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('level')
          .orderBy('order')
          .get();

      final loadedCategories = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Separate categories by level
      _mainCategories = loadedCategories.where((cat) => cat['level'] == 0).toList();
      
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
    
    // Reset sub-subcategories
    _subSubCategories = [];
    _selectedSubCategoryId = null;
    _selectedSubSubCategoryId = null;
    
    // Load category-specific fields
    _loadCategorySpecificFields(mainCategoryId);
    
    setState(() {});
  }

  // Load sub-subcategories when subcategory is selected
  void _loadSubSubCategories(String subCategoryId) {
    _subSubCategories = _categories
        .where((cat) => cat['parentId'] == subCategoryId && cat['level'] == 2)
        .toList();
    
    _selectedSubSubCategoryId = null;
    setState(() {});
  }

  // Load category-specific fields
  void _loadCategorySpecificFields(String categoryId) {
    final category = _categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => <String, dynamic>{},
    );
    
    final categoryName = category['name'] ?? '';
    final fields = _categoryFieldTemplates[categoryName] ?? [];
    
    setState(() {
      _currentCategoryFields = fields.map((field) => field['name'] as String).toList();
      // Initialize field values
      for (final field in fields) {
        if (!_categorySpecificFields.containsKey(field['name'])) {
          _categorySpecificFields[field['name']] = null;
        }
      }
    });
  }

  // Enhanced category suggestion with better matching
  void _suggestCategory(String title, String description) {
    String combinedText = (title + ' ' + description).toLowerCase();
    
    // First try exact matches with main categories
    for (final category in _mainCategories) {
      final categoryName = category['name']?.toString().toLowerCase() ?? '';
      final keywords = _categoryKeywords[category['name']] ?? [];
      
      // Check if any keyword matches
      for (final keyword in keywords) {
        if (combinedText.contains(keyword.toLowerCase())) {
          setState(() {
            _suggestedCategoryName = category['name'];
            _suggestedCategoryId = category['id'];
          });
          return;
        }
      }
    }
    
    // Clear suggestion if no match found
    setState(() {
      _suggestedCategoryName = null;
      _suggestedCategoryId = null;
    });
  }

  // FIXED: Apply suggested category properly
  void _applySuggestedCategory() {
    if (_suggestedCategoryId != null && _suggestedCategoryName != null) {
      setState(() {
        _selectedMainCategoryId = _suggestedCategoryId;
        _selectedCategoryName = _suggestedCategoryName;
        // Clear suggestion after applying
        _suggestedCategoryName = null;
        _suggestedCategoryId = null;
      });
      
      // Load subcategories for the selected main category
      _loadSubCategories(_selectedMainCategoryId!);
      
      // Update item provider
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      itemProvider.updateItemDetails(
        category: _selectedMainCategoryId,
        categoryName: _selectedCategoryName,
      );
    }
  }

  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter item title';
    }
    if (value.length < 10) {
      return 'Title must be at least 10 characters long';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a description';
    }
    
    List<String> words = value.trim().split(RegExp(r'\s+'));
    words = words.where((word) => word.isNotEmpty).toList();
    
    if (words.length < 10) {
      return 'Description must contain at least 10 words (${words.length}/10)';
    }
    return null;
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

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: widget.isMain ? false : true,
        elevation: 0,
        title: Text(
          'Item Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        // FIXED: Removed cart and notification icons, added category navigation
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.category_outlined, color: Colors.black),
            onSelected: (categoryId) {
              setState(() {
                _selectedMainCategoryId = categoryId;
                final category = _mainCategories.firstWhere((cat) => cat['id'] == categoryId);
                _selectedCategoryName = category['name'];
              });
              _loadSubCategories(categoryId);
              itemProvider.updateItemDetails(
                category: categoryId,
                categoryName: _selectedCategoryName,
              );
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
            tooltip: 'Quick Category Selection',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: itemProvider.formKey,
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Describe Your Item',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete these details to make your item stand out to buyers.',
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
                            hint: 'Item Title',
                            onChanged: (value) {
                              itemProvider.updateItemDetails(itemTitle: value);
                              _suggestCategory(value, _descriptionController.text);
                            },
                            validator: _validateTitle,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'Minimum 10 characters (${_titleController.text.length}/10)',
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
                      
                      // ENHANCED: Hierarchical Category Selection
                      _buildHierarchicalCategorySelection(itemProvider),
                      
                      const SizedBox(height: 16),
                      
                      // FIXED: Only show condition if no category is selected or if validation fails
                      if (itemProvider.condition.isEmpty)
                        Column(
                          children: [
                            _buildDropdownField(
                              hint: 'Condition',
                              items: ['New', 'Like New', 'Used', 'Refurbished'],
                              selectedValue: itemProvider.condition.isEmpty ? null : itemProvider.condition,
                              onChanged: (value) => itemProvider.updateItemDetails(condition: value),
                              validator: (value) => value == null ? 'Please select a condition' : null,
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
                            hint: 'Description',
                            onChanged: (value) {
                              itemProvider.updateItemDetails(description: value);
                              _suggestCategory(_titleController.text, value);
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
                                  'Minimum 10 words ($wordCount/10)',
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
                      
                      // ENHANCED: Category-specific fields
                      ..._buildCategorySpecificFields(),
                      
                      _buildTextField(
                        hint: 'Brand',
                        onChanged: (value) => itemProvider.updateItemDetails(brand: value),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        hint: 'Dimensions/Size',
                        onChanged: (value) => itemProvider.updateItemDetails(dimensions: value),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        hint: 'Color',
                        onChanged: (value) => itemProvider.updateItemDetails(color: value),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (itemProvider.validateForm()) {
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
                    'Next',
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

  // ENHANCED: Hierarchical category selection with proper navigation
  Widget _buildHierarchicalCategorySelection(ItemProvider itemProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Category Selection
        _buildCategoryDropdown(
          hint: 'Main Category',
          categories: _mainCategories,
          selectedValue: _selectedMainCategoryId,
          onChanged: (value) {
            setState(() {
              _selectedMainCategoryId = value;
              if (value != null) {
                final category = _mainCategories.firstWhere((cat) => cat['id'] == value);
                _selectedCategoryName = category['name'];
                _loadSubCategories(value);
              }
            });
            itemProvider.updateItemDetails(
              category: value,
              categoryName: _selectedCategoryName,
            );
          },
        ),
        
        // Category suggestion
        if (_suggestedCategoryName != null) ...[
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
                  Icons.lightbulb_outline,
                  color: ColorsController.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Suggested category: $_suggestedCategoryName',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: ColorsController.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _applySuggestedCategory, // FIXED: Use the new method
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Use',
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
        
        // Subcategory Selection (if available)
        if (_subCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildCategoryDropdown(
            hint: 'Subcategory',
            categories: _subCategories,
            selectedValue: _selectedSubCategoryId,
            onChanged: (value) {
              setState(() {
                _selectedSubCategoryId = value;
                if (value != null) {
                  _loadSubSubCategories(value);
                }
              });
            },
          ),
        ],
        
        // Sub-subcategory Selection (if available)
        if (_subSubCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildCategoryDropdown(
            hint: 'Sub-subcategory',
            categories: _subSubCategories,
            selectedValue: _selectedSubSubCategoryId,
            onChanged: (value) {
              setState(() {
                _selectedSubSubCategoryId = value;
              });
            },
          ),
        ],
      ],
    );
  }

  // Build category dropdown for different levels
  Widget _buildCategoryDropdown({
    required String hint,
    required List<Map<String, dynamic>> categories,
    String? selectedValue,
    required Function(String?) onChanged,
  }) {
    if (categories.isEmpty) {
      return SizedBox.shrink();
    }

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
      ),
      items: categories.map((category) {
        final categoryId = category['id']?.toString() ?? '';
        final categoryName = category['name']?.toString() ?? 'Unknown';
        
        return DropdownMenuItem<String>(
          value: categoryId,
          child: Text(
            categoryName,
            style: GoogleFonts.jost(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: hint == 'Main Category' 
          ? (value) => value == null ? 'Please select a category' : null
          : null,
    );
  }

  // Build category-specific fields
  List<Widget> _buildCategorySpecificFields() {
    if (_selectedMainCategoryId == null) return [];
    
    final mainCategory = _mainCategories.firstWhere(
      (cat) => cat['id'] == _selectedMainCategoryId,
      orElse: () => <String, dynamic>{},
    );
    
    final categoryName = mainCategory['name'] ?? '';
    final fields = _categoryFieldTemplates[categoryName] ?? [];
    
    if (fields.isEmpty) return [];
    
    List<Widget> widgets = [
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          '$categoryName Specific Details',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    ];
    
    for (final field in fields) {
      if (field['type'] == 'dropdown') {
        widgets.add(
          Column(
            children: [
              _buildDropdownField(
                hint: field['label'],
                items: List<String>.from(field['options'] ?? []),
                selectedValue: _categorySpecificFields[field['name']],
                onChanged: (value) {
                  setState(() {
                    _categorySpecificFields[field['name']] = value;
                  });
                },
                validator: field['required'] == true 
                    ? (value) => value == null ? 'Please select ${field['label']}' : null
                    : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      } else {
        widgets.add(
          Column(
            children: [
              _buildTextField(
                hint: field['label'],
                keyboardType: field['type'] == 'number' ? TextInputType.number : TextInputType.text,
                onChanged: (value) {
                  setState(() {
                    _categorySpecificFields[field['name']] = value;
                  });
                },
                validator: field['required'] == true 
                    ? (value) => value?.isEmpty == true ? 'Please enter ${field['label']}' : null
                    : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    }
    
    return widgets;
  }

  Widget _buildTextField({
    required String hint,
    TextEditingController? controller,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
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
}
