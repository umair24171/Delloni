import 'dart:developer' as developer;
import 'dart:math' as math;

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
import 'package:flutter/material.dart' as math;

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
  
  // Add this line to define _suggestedCategoryPath
  Map<String, dynamic>? _suggestedCategoryPath;

  bool _debugMode = true; // Add this flag for detailed logging

  void _log(String message) {
    if (_debugMode) {
      print('CategoryDebug: $message');
    }
  }

   @override
  void initState() {
    super.initState();
    _loadCategories();  // Move this here, outside of the if statement
    
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
  // Replace static _categoryKeywords with dynamic one
  Map<String, dynamic> _categoryKeywords = {};

  


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

  // Category-specific fields - NOW DYNAMIC
  Map<String, dynamic> _categorySpecificFields = {};
  List<Map<String, dynamic>> _currentCategoryFieldTemplate = [];
  bool _isLoadingCategoryFields = false;
  // UPDATED: Load category-specific fields based on your actual structure

  Future<void> _loadCategorySpecificFields(String categoryId) async {
  setState(() {
    _isLoadingCategoryFields = true;
  });

  try {
    // Get the hierarchy path from selected categories
    List<String> categoryHierarchy = [];
    
    // Build hierarchy from main to deepest selected
    if (_selectedMainCategoryId != null) {
      categoryHierarchy.add(_selectedMainCategoryId!);
    }
    if (_selectedSubCategoryId != null) {
      categoryHierarchy.add(_selectedSubCategoryId!);
    }
    if (_selectedSubSubCategoryId != null) {
      categoryHierarchy.add(_selectedSubSubCategoryId!);
    }
    if (_selectedSubSubSubCategoryId != null) {
      categoryHierarchy.add(_selectedSubSubSubCategoryId!);
    }

    developer.log('Loading fields for hierarchy: $categoryHierarchy');

    // Collect fields from all categories in the hierarchy (inheritance)
    List<Map<String, dynamic>> allFields = [];
    
    // Start from the main category and go down to collect all inherited fields
    for (String catId in categoryHierarchy) {
      developer.log('Loading fields for category: $catId');
      
      final categoryFields = await _fetchCategoryFieldsFromYourStructure(catId);
      
      // Add fields that don't already exist (avoid duplicates, keep first occurrence)
      for (final field in categoryFields) {
        final fieldName = field['fieldName']?.toString() ?? field['name']?.toString() ?? '';
        
        // Check if field already exists in allFields
        bool fieldExists = allFields.any((existingField) {
          final existingFieldName = existingField['fieldName']?.toString() ?? 
                                   existingField['name']?.toString() ?? '';
          return existingFieldName == fieldName;
        });
        
        if (!fieldExists && fieldName.isNotEmpty) {
          allFields.add(field);
          developer.log('Added field: $fieldName from category: $catId');
        } else {
          developer.log('Field $fieldName already exists, skipping from category: $catId');
        }
      }
    }

    // Get the category name from the deepest selected category
    final targetCategoryId = _selectedSubSubSubCategoryId ?? 
                            _selectedSubSubCategoryId ?? 
                            _selectedSubCategoryId ?? 
                            _selectedMainCategoryId;

    final category = _categories.firstWhere(
      (cat) => cat['id'] == targetCategoryId,
      orElse: () => <String, dynamic>{},
    );
    
    final categoryName = category['name'] ?? '';
    
    // Sort fields by order and category
    allFields.sort((a, b) {
      final orderA = a['order'] as int? ?? 999;
      final orderB = b['order'] as int? ?? 999;
      return orderA.compareTo(orderB);
    });

    setState(() {
      _currentCategoryFieldTemplate = allFields;
      _isLoadingCategoryFields = false;
      
      // Initialize field values if not already set
      for (final field in allFields) {
        final fieldName = field['fieldName']?.toString() ?? field['name']?.toString() ?? '';
        if (fieldName.isNotEmpty && !_categorySpecificFields.containsKey(fieldName)) {
          _categorySpecificFields[fieldName] = null;
        }
      }
    });

    // Update ItemProvider with category template and fields
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    itemProvider.setCategoryTemplate(allFields, categoryName);
    itemProvider.updateCategorySpecificFields(_categorySpecificFields);
    
    developer.log('Loaded ${allFields.length} inherited fields for $categoryName');
    developer.log('Field names: ${allFields.map((f) => f['fieldName'] ?? f['name']).join(', ')}');

  } catch (e, stack) {
    developer.log('Error loading category fields: $e');
    developer.log('Stack trace: $stack');
    setState(() {
      _currentCategoryFieldTemplate = [];
      _isLoadingCategoryFields = false;
    });
  }
}

  // Future<void> _loadCategorySpecificFields(String categoryId) async {
  //   setState(() {
  //     _isLoadingCategoryFields = true;
  //   });

  //   try {
  //     // Get the deepest selected category (most specific)
  //     final targetCategoryId = _selectedSubSubSubCategoryId ?? 
  //                             _selectedSubSubCategoryId ?? 
  //                             _selectedSubCategoryId ?? 
  //                             _selectedMainCategoryId;

  //     if (targetCategoryId == null) {
  //       setState(() {
  //         _currentCategoryFieldTemplate = [];
  //         _isLoadingCategoryFields = false;
  //       });
  //       return;
  //     }

  //     developer.log('Loading category fields for: $targetCategoryId');

  //     // Fetch category fields with your specific structure
  //     final categoryFields = await _fetchCategoryFieldsFromYourStructure(targetCategoryId);
      
  //     final category = _categories.firstWhere(
  //       (cat) => cat['id'] == targetCategoryId,
  //       orElse: () => <String, dynamic>{},
  //     );
      
  //     final categoryName = category['name'] ?? '';
      
  //     setState(() {
  //       _currentCategoryFieldTemplate = categoryFields;
  //       _isLoadingCategoryFields = false;
        
  //       // Initialize field values if not already set
  //       for (final field in categoryFields) {
  //         final fieldName = field['name'] ?? field['key'] ?? '';
  //         if (fieldName.isNotEmpty && !_categorySpecificFields.containsKey(fieldName)) {
  //           _categorySpecificFields[fieldName] = null;
  //         }
  //       }
  //     });

  //     // Update ItemProvider with category template and fields
  //     final itemProvider = Provider.of<ItemProvider>(context, listen: false);
  //     itemProvider.setCategoryTemplate(categoryFields, categoryName);
  //     itemProvider.updateCategorySpecificFields(_categorySpecificFields);
      
  //     developer.log('Loaded ${categoryFields.length} dynamic category-specific fields for $categoryName');

  //   } catch (e) {
  //     developer.log('Error loading category fields: $e');
  //     setState(() {
  //       _currentCategoryFieldTemplate = [];
  //       _isLoadingCategoryFields = false;
  //     });
  //   }
  // }
  // NEW: Fetch category fields based on your specific structure
 Future<List<Map<String, dynamic>>> _fetchCategoryFieldsFromYourStructure(String categoryId) async {
  try {
    developer.log('Starting to fetch fields for category: $categoryId');
    
    // First, get the category document
    final categoryDoc = await FirebaseFirestore.instance
        .collection('categories')
        .doc(categoryId)
        .get();

    if (!categoryDoc.exists) {
      developer.log('Category document not found: $categoryId');
      return [];
    }

    final categoryData = categoryDoc.data() ?? {};
    developer.log('Category data: $categoryData');

    List<Map<String, dynamic>> allFields = [];

    // 1. First check configuredFields as they have highest priority
    if (categoryData['configuredFields'] is List) {
      final configuredFields = List<Map<String, dynamic>>.from(categoryData['configuredFields']);
      developer.log('Found ${configuredFields.length} configuredFields');
      allFields.addAll(configuredFields);
    }

    // 2. Then check fieldTemplate if exists
    final fieldTemplateId = categoryData['fieldTemplate'];
    if (fieldTemplateId != null && fieldTemplateId.toString().isNotEmpty) {
      developer.log('Found fieldTemplate: $fieldTemplateId');
      
      // Updated to use field_templates collection (your dynamic templates)
      final templateDoc = await FirebaseFirestore.instance
          .collection('field_templates')  // Updated collection name
          .doc(fieldTemplateId.toString())
          .get();

      if (templateDoc.exists) {
        final templateData = templateDoc.data() ?? {};
        developer.log('Template data: $templateData');

        // Check all possible field locations in template
        if (templateData['fields'] is List) {
          final fields = List<Map<String, dynamic>>.from(templateData['fields']);
          developer.log('Found ${fields.length} fields in template');
          allFields.addAll(fields);
        }
        if (templateData['configuredFields'] is List) {
          final fields = List<Map<String, dynamic>>.from(templateData['configuredFields']);
          developer.log('Found ${fields.length} configuredFields in template');
          allFields.addAll(fields);
        }
        if (templateData['template'] is List) {
          final fields = List<Map<String, dynamic>>.from(templateData['template']);
          developer.log('Found ${fields.length} template fields');
          allFields.addAll(fields);
        }
      }
    }

    // 3. Check inheritedTemplates
    if (categoryData['inheritedTemplates'] is List) {
      final inheritedTemplates = List<String>.from(categoryData['inheritedTemplates']);
      for (final templateId in inheritedTemplates) {
        if (templateId.isNotEmpty) {
          developer.log('Processing inherited template: $templateId');
          final templateDoc = await FirebaseFirestore.instance
              .collection('field_templates')  // Updated collection name
              .doc(templateId)
              .get();

          if (templateDoc.exists) {
            final templateData = templateDoc.data() ?? {};
            if (templateData['fields'] is List) {
              final fields = List<Map<String, dynamic>>.from(templateData['fields']);
              allFields.addAll(fields);
            }
          }
        }
      }
    }

    // Remove duplicates based on field name
    final uniqueFields = <String, Map<String, dynamic>>{};
    for (final field in allFields) {
      // Updated to handle both fieldName and name properties
      final fieldName = field['fieldName']?.toString() ?? field['name']?.toString() ?? '';
      if (fieldName.isNotEmpty) {
        // If field already exists, keep the one with more complete data
        if (!uniqueFields.containsKey(fieldName) || 
            (field['label'] != null && uniqueFields[fieldName]!['label'] == null)) {
          uniqueFields[fieldName] = _normalizeFieldStructureWithIcons(field);
        }
      }
    }

    final finalFields = uniqueFields.values.toList();
    
    // Sort fields by order
    finalFields.sort((a, b) {
      final orderA = a['order'] as int? ?? 999;
      final orderB = b['order'] as int? ?? 999;
      return orderA.compareTo(orderB);
    });
    
    developer.log('Final fields count: ${finalFields.length}');
    developer.log('Final fields: $finalFields');

    return finalFields;
  } catch (e, stack) {
    developer.log('Error fetching category fields: $e');
    developer.log('Stack trace: $stack');
    return [];
  }
}
// UPDATED: Normalize field structure with icon support
Map<String, dynamic> _normalizeFieldStructureWithIcons(Map<String, dynamic> field) {
  final normalizedField = Map<String, dynamic>.from(field);
  
  // Handle both fieldName and name properties (for backward compatibility)
  final fieldName = field['fieldName']?.toString() ?? field['name']?.toString() ?? '';
  normalizedField['name'] = fieldName;
  normalizedField['fieldName'] = fieldName;
  
  // Ensure required fields exist
  normalizedField['label'] = field['label'] ?? fieldName;
  normalizedField['type'] = _normalizeFieldType(field['fieldType'] ?? field['type']);
  normalizedField['required'] = field['isRequired'] ?? field['required'] ?? false;
  
  // NEW: Handle icon configuration
  normalizedField['showFieldIcon'] = field['showFieldIcon'] ?? false;
  if (field['fieldIconUrl'] != null && field['fieldIconUrl'].toString().isNotEmpty) {
    normalizedField['fieldIconUrl'] = field['fieldIconUrl'];
  }
  
  // Handle order
  normalizedField['order'] = field['order'] ?? 1;
  
  // Handle placeholder
  if (field['placeholder'] != null && field['placeholder'].toString().isNotEmpty) {
    normalizedField['placeholder'] = field['placeholder'];
  }
  
  // Handle options for dropdown/select fields
  if (normalizedField['type'] == 'select' || normalizedField['type'] == 'dropdown') {
    if (field['options'] is List) {
      normalizedField['options'] = List<String>.from(field['options']);
    } else {
      normalizedField['options'] = [];
    }
  }

  // Add category grouping if exists
  if (field['category'] != null) {
    normalizedField['category'] = field['category'];
  }

  return normalizedField;
}


 

  // Helper method to normalize field types
  String _normalizeFieldType(dynamic type) {
    final fieldType = type?.toString().toLowerCase() ?? 'text';
    switch (fieldType) {
      case 'dropdown':
        return 'select';
      case 'textarea':
        return 'text';
      case 'number':
      case 'integer':
      case 'decimal':
        return 'number';
      case 'boolean':
      case 'checkbox':
        return 'switch';
      default:
        return fieldType;
    }
  }

  // NEW: Fetch field template by ID from Firestore
  Future<List<Map<String, dynamic>>> _fetchFieldTemplateById(String templateId) async {
    try {
      developer.log('Fetching field template with ID: $templateId');
      
      final doc = await FirebaseFirestore.instance
          .collection('fieldTemplates')
          .doc(templateId)
          .get();

      if (!doc.exists) {
        developer.log('Field template not found: $templateId');
        return [];
      }

      final data = doc.data();
      if (data == null) {
        developer.log('Field template data is null: $templateId');
        return [];
      }

      developer.log('Field template data: $data');
      
      // Handle different possible structures for template data
      List<Map<String, dynamic>> fields = [];
      
      if (data['fields'] is List) {
        fields = List<Map<String, dynamic>>.from(data['fields']);
      } else if (data['configuredFields'] is List) {
        fields = List<Map<String, dynamic>>.from(data['configuredFields']);
      } else if (data['template'] is List) {
        fields = List<Map<String, dynamic>>.from(data['template']);
      }
      
      developer.log('Extracted ${fields.length} fields from template $templateId');
      return fields;
    } catch (e) {
      developer.log('Error fetching field template $templateId: $e');
      return [];
    }
  }



  // NEW: Fetch category fields with inheritance logic
  Future<List<Map<String, dynamic>>> _fetchCategoryFieldsWithInheritance(String categoryId) async {
    try {
      List<Map<String, dynamic>> allFields = [];
      String? currentCategoryId = categoryId;

      // Traverse up the category hierarchy to collect inherited fields
      while (currentCategoryId != null) {
        final category = _categories.firstWhere(
          (cat) => cat['id'] == currentCategoryId,
          orElse: () => <String, dynamic>{},
        );

        if (category.isEmpty) break;

        // Get fields from current category
        final specificFields = category['specificFields'] as Map<String, dynamic>?;
        if (specificFields != null) {
          // If specificFields contains template array
          if (specificFields['template'] is List) {
            final categoryTemplate = List<Map<String, dynamic>>.from(specificFields['template']);
            // Add category-specific fields to the beginning (higher priority)
            allFields.insertAll(0, categoryTemplate);
          }
          
          // If specificFields contains individual field definitions
          if (specificFields['fields'] is List) {
            final categoryFields = List<Map<String, dynamic>>.from(specificFields['fields']);
            allFields.insertAll(0, categoryFields);
          }

          // Handle direct field definitions in specificFields
          final directFields = _extractDirectFields(specificFields);
          if (directFields.isNotEmpty) {
            allFields.insertAll(0, directFields);
          }
        }

        // Move to parent category
        currentCategoryId = category['parentId'];
      }

      // Remove duplicates (keep the first occurrence - higher priority)
      final uniqueFields = <String, Map<String, dynamic>>{};
      for (final field in allFields) {
        final fieldName = field['name'] ?? field['key'] ?? '';
        if (fieldName.isNotEmpty && !uniqueFields.containsKey(fieldName)) {
          uniqueFields[fieldName] = field;
        }
      }

      final finalFields = uniqueFields.values.toList();
      developer.log('Fetched ${finalFields.length} fields with inheritance for category: $categoryId');
      
      return finalFields;

    } catch (e) {
      developer.log('Error fetching category fields with inheritance: $e');
      return [];
    }
  }

  // NEW: Extract direct field definitions from specificFields
  List<Map<String, dynamic>> _extractDirectFields(Map<String, dynamic> specificFields) {
    List<Map<String, dynamic>> fields = [];
    
    // Look for common field definition patterns
    specificFields.forEach((key, value) {
      if (key != 'template' && key != 'fields' && value is Map<String, dynamic>) {
        // This might be a field definition
        if (value.containsKey('type') || value.containsKey('label') || value.containsKey('options')) {
          fields.add({
            'name': key,
            ...value,
          });
        }
      }
    });

    return fields;
  }

  // UPDATED: Load subcategories and their fields
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
    
    // Load category-specific fields for main category
    _loadCategorySpecificFields(mainCategoryId);
    
    setState(() {});
    
    print('Loaded ${_subCategories.length} subcategories for main category: $mainCategoryId');
  }

  // UPDATED: Load sub-subcategories and their fields
  void _loadSubSubCategories(String subCategoryId) {
    _subSubCategories = _categories
        .where((cat) => cat['parentId'] == subCategoryId && cat['level'] == 2)
        .toList();
    
    // Reset sub-sub-subcategories
    _subSubSubCategories = [];
    _selectedSubSubCategoryId = null;
    _selectedSubSubSubCategoryId = null;
    
    // Load category-specific fields for subcategory
    _loadCategorySpecificFields(subCategoryId);
    
    setState(() {});
  }

  // UPDATED: Load sub-sub-subcategories and their fields
  void _loadSubSubSubCategories(String subSubCategoryId) {
    _subSubSubCategories = _categories
        .where((cat) => cat['parentId'] == subSubCategoryId && cat['level'] == 3)
        .toList();
    
    _selectedSubSubSubCategoryId = null;
    
    // Load category-specific fields for sub-subcategory
    _loadCategorySpecificFields(subSubCategoryId);
    
    setState(() {});
  }

  // UPDATED: Build category-specific fields with dynamic templates
 List<Widget> _buildCategorySpecificFields() {
  if (_currentCategoryFieldTemplate.isEmpty) return [];
 
  List<Widget> widgets = [];

  // Show loading indicator while fetching fields
  if (_isLoadingCategoryFields) {
    widgets.add(
      Container(
        padding: EdgeInsets.all(16),
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
              'Loading category fields...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
    return widgets;
  }

  // Add section title
  widgets.add(
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            color: ColorsController.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedCategoryName ?? 'Category'} Specific Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );

  // Group fields by category if they have category property
  final organizedFields = <String, List<Map<String, dynamic>>>{};
  for (final field in _currentCategoryFieldTemplate) {
    final category = field['category'] ?? 'general';
    organizedFields.putIfAbsent(category, () => []).add(field);
  }

  // Build fields organized by category
  for (final categoryEntry in organizedFields.entries) {
    if (organizedFields.keys.length > 1) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: ColorsController.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getCategoryDisplayName(categoryEntry.key),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorsController.primaryColor,
                ),
              ),
            ],
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

  // UPDATED: Build dynamic field based on type with enhanced field mapping
 Widget _buildDynamicField(Map<String, dynamic> field) {
  final fieldType = _normalizeFieldType(field['type']);
  final fieldName = field['name']?.toString() ?? '';
  final fieldLabel = field['label']?.toString() ?? fieldName;
  final isRequired = field['required'] == true;
  final showFieldIcon = field['showFieldIcon'] == true;
  final fieldIconUrl = field['fieldIconUrl'];
  
  developer.log('Building field with icon: $fieldName ($fieldType) - Required: $isRequired, ShowIcon: $showFieldIcon');

  switch (fieldType) {
    case 'select':
    case 'dropdown':
      return _buildDropdownFieldWithIcon(field);
    
    case 'number':
      return _buildNumberFieldWithIcon(field);
    
    case 'switch':
      return _buildBooleanFieldWithIcon(field);
    
    case 'text':
    default:
      return _buildTextFieldWithIcon(field);
  }
}
// NEW: Build dropdown field with icon support
Widget _buildDropdownFieldWithIcon(Map<String, dynamic> field) {
  final fieldName = field['name']?.toString() ?? '';
  final fieldLabel = field['label']?.toString() ?? fieldName;
  final isRequired = field['required'] == true;
  final showFieldIcon = field['showFieldIcon'] == true;
  final fieldIconUrl = field['fieldIconUrl'];
  
  // Extract options from your field structure
  List<String> options = [];
  if (field['options'] is List) {
    options = List<String>.from(field['options']);
  } else if (field['values'] is List) {
    options = List<String>.from(field['values']);
  } else if (field['choices'] is List) {
    options = List<String>.from(field['choices']);
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Field label with icon
      if (showFieldIcon || fieldIconUrl != null) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Field icon
              if (showFieldIcon && fieldIconUrl != null) ...[
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      fieldIconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        _getDefaultIconForFieldType(field['type'] ?? 'text'),
                        size: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Field label
              Text(
                fieldLabel + (isRequired ? ' *' : ''),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
      
      // Dropdown field
      DropdownButtonFormField<String>(
        value: _categorySpecificFields[fieldName]?.toString(),
        style: GoogleFonts.jost(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          hintText: showFieldIcon && fieldIconUrl == null ? fieldLabel : 
                   !showFieldIcon ? fieldLabel : 'Select ${fieldLabel.toLowerCase()}',
          hintStyle: GoogleFonts.poppins(
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
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              style: GoogleFonts.jost(fontSize: 16, fontWeight: FontWeight.w400),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _categorySpecificFields[fieldName] = value;
          });
          _updateItemProviderField(fieldName, value);
        },
        validator: isRequired 
            ? (value) => value == null ? 'Please select $fieldLabel'.tr() : null
            : null,
      ),
    ],
  );
}

// NEW: Build text field with icon support
Widget _buildTextFieldWithIcon(Map<String, dynamic> field, {int maxLines = 1}) {
  final fieldName = field['name'] ?? '';
  final fieldLabel = field['label'] ?? fieldName;
  final isRequired = field['required'] == true || field['required'] == 'true';
  final showFieldIcon = field['showFieldIcon'] == true;
  final fieldIconUrl = field['fieldIconUrl'];
  final placeholder = field['placeholder']?.toString() ?? fieldLabel;
  final currentValue = _categorySpecificFields[fieldName]?.toString() ?? '';
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Field label with icon
      if (showFieldIcon || fieldIconUrl != null) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Field icon
              if (showFieldIcon && fieldIconUrl != null) ...[
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      fieldIconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        _getDefaultIconForFieldType(field['type'] ?? 'text'),
                        size: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Field label
              Text(
                fieldLabel + (isRequired ? ' *' : ''),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
      
      // Text field
      TextFormField(
        initialValue: currentValue,
        style: GoogleFonts.jost(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black
        ),
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: showFieldIcon && fieldIconUrl == null ? placeholder : 
                   !showFieldIcon ? placeholder : 'Enter ${fieldLabel.toLowerCase()}',
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
          setState(() {
            _categorySpecificFields[fieldName] = value;
          });
          _updateItemProviderField(fieldName, value);
        },
        validator: isRequired 
            ? (value) => value?.isEmpty == true ? 'Please enter $fieldLabel' : null
            : null,
      ),
    ],
  );
}

// NEW: Build number field with icon support
Widget _buildNumberFieldWithIcon(Map<String, dynamic> field) {
  final fieldName = field['name'] ?? '';
  final fieldLabel = field['label'] ?? fieldName;
  final isRequired = field['required'] == true || field['required'] == 'true';
  final showFieldIcon = field['showFieldIcon'] == true;
  final fieldIconUrl = field['fieldIconUrl'];
  final placeholder = field['placeholder']?.toString() ?? fieldLabel;
  final currentValue = _categorySpecificFields[fieldName];
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Field label with icon
      if (showFieldIcon || fieldIconUrl != null) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Field icon
              if (showFieldIcon && fieldIconUrl != null) ...[
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      fieldIconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        _getDefaultIconForFieldType(field['type'] ?? 'number'),
                        size: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Field label
              Text(
                fieldLabel + (isRequired ? ' *' : ''),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
      
      // Number field
      TextFormField(
        initialValue: currentValue?.toString() ?? '',
        keyboardType: TextInputType.number,
        style: GoogleFonts.jost(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: showFieldIcon && fieldIconUrl == null ? placeholder : 
                   !showFieldIcon ? placeholder : 'Enter ${fieldLabel.toLowerCase()}',
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
            _categorySpecificFields[fieldName] = numValue;
          });
          _updateItemProviderField(fieldName, numValue);
        },
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return '$fieldLabel is required';
          }
          
          if (value != null && value.isNotEmpty) {
            final numValue = double.tryParse(value);
            if (numValue == null) {
              return 'Please enter a valid number';
            }
          }
          
          return null;
        },
      ),
    ],
  );
}

// NEW: Build boolean field with icon support
Widget _buildBooleanFieldWithIcon(Map<String, dynamic> field) {
  final fieldName = field['name'] ?? '';
  final fieldLabel = field['label'] ?? fieldName;
  final showFieldIcon = field['showFieldIcon'] == true;
  final fieldIconUrl = field['fieldIconUrl'];
  final value = _categorySpecificFields[fieldName] as bool? ?? false;
  
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
    ),
    child: SwitchListTile(
      title: Row(
        children: [
          // Field icon
          if (showFieldIcon && fieldIconUrl != null) ...[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  fieldIconUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    _getDefaultIconForFieldType(field['type'] ?? 'checkbox'),
                    size: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Field label
          Expanded(
            child: Text(
              fieldLabel,
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
      value: value,
      onChanged: (newValue) {
        setState(() {
          _categorySpecificFields[fieldName] = newValue;
        });
        _updateItemProviderField(fieldName, newValue);
      },
      activeColor: ColorsController.primaryColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}

// NEW: Get default icon for field type
IconData _getDefaultIconForFieldType(String fieldType) {
  switch (fieldType.toLowerCase()) {
    case 'text':
    case 'textarea':
      return Icons.text_fields;
    case 'number':
    case 'integer':
    case 'decimal':
      return Icons.numbers;
    case 'dropdown':
    case 'select':
      return Icons.arrow_drop_down;
    case 'checkbox':
    case 'switch':
      return Icons.check_box;
    case 'radio':
      return Icons.radio_button_checked;
    case 'date':
      return Icons.calendar_today;
    case 'time':
      return Icons.access_time;
    case 'datetime':
      return Icons.date_range;
    case 'file':
      return Icons.attach_file;
    case 'image':
      return Icons.image;
    case 'color':
      return Icons.palette;
    default:
      return Icons.input;
  }
}
 
  // NEW: Update ItemProvider field
  void _updateItemProviderField(String fieldName, dynamic value) {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    itemProvider.updateCategoryField(fieldName, value);
  }
  // Load categories from Firestore with hierarchy
  Future<void> _loadCategories() async {
    // if (_isLoadingCategories) {
    //   _log('Already loading categories, skipping duplicate load');
    //   return;
    // }
    
    try {
      _log('Starting category load process...');
      setState(() {
        _isLoadingCategories = true;
        _categories = [];
        _mainCategories = [];
        _categoryKeywords = {};
      });

      _log('Fetching categories from Firestore...');
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      _log('Received ${snapshot.docs.length} categories from Firestore');

      if (!mounted) {
        _log('Widget unmounted during category load, aborting');
        return;
      }

      if (snapshot.docs.isEmpty) {
        _log('No categories found in Firestore!');
        setState(() {
          _isLoadingCategories = false;
        });
        return;
      }

      // Print first few documents for debugging
      _log('\nFirst few categories in Firestore:');
      for (var i = 0; i < math.min(5, snapshot.docs.length); i++) {
        final doc = snapshot.docs[i];
        _log('Category $i:');
        _log('  ID: ${doc.id}');
        _log('  Data: ${doc.data()}');
      }

      final loadedCategories = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          final name = (data['name'] ?? 'Unnamed Category').toString();
          final parentId = (data['parentId'] ?? '').toString();
          final level = data['level'] ?? 0;
          final isActive = data['isActive'] ?? true;
          
          if (!isActive) {
            _log('Skipping inactive category: $name');
            return null;
          }
          
          _log('Processing category: $name (ID: ${doc.id}, Level: $level, ParentID: $parentId)');
          
          return {
            'id': doc.id,
            'name': name,
            'level': level,
            'isActive': isActive,
            'order': data['order'] ?? 0,
            'parentId': parentId,
          };
        } catch (e) {
          _log('Error processing category document ${doc.id}: $e');
          return null;
        }
      })
      .where((cat) => cat != null)
      .cast<Map<String, dynamic>>()
      .toList();

      _log('Successfully processed ${loadedCategories.length} valid categories');

      if (loadedCategories.isEmpty) {
        _log('No valid categories found after processing!');
        setState(() {
          _isLoadingCategories = false;
        });
        return;
      }

      // Build keywords map
      final keywords = <String, Map<String, dynamic>>{};
      _log('Building category keywords...');
      
      for (final category in loadedCategories) {
        try {
          final name = category['name'] as String;
          if (name.isEmpty) continue;

          // Build category path
          final path = <String>[];
          var currentCat = category;
          var depth = 0;
          
          _log('Building path for category: $name');
          
          while (currentCat != null && currentCat.isNotEmpty && depth < 5) {
            path.insert(0, currentCat['name'] as String);
            
            final parentId = currentCat['parentId'] as String;
            if (parentId.isEmpty) {
              _log('Reached root category for: $name');
              break;
            }
            
            currentCat = loadedCategories.firstWhere(
              (cat) => cat['id'] == parentId,
              orElse: () => {},
            );
            
            if (currentCat.isEmpty) {
              _log('Parent category not found for: $name (ParentID: $parentId)');
              break;
            }
            depth++;
          }

          if (path.isNotEmpty) {
            final keywordData = {
              'mainCategory': path.first,
              'subCategory': path.length > 1 ? path[1] : null,
              'subSubCategory': path.length > 2 ? path[2] : null,
              'subSubSubCategory': path.length > 3 ? path[3] : null,
              'path': path,
            };
            
            _log('Created keyword for "$name": ${path.join(' > ')}');
            keywords[name.toLowerCase()] = keywordData;

            // Add combinations
            if (path.length > 1) {
              final key = '${path[0]} ${path[1]}'.toLowerCase();
              keywords[key] = Map<String, dynamic>.from(keywordData);
              _log('Added combination keyword: "$key"');
            }
          }
        } catch (e) {
          _log('Error processing category ${category['name']}: $e');
        }
      }

      if (!mounted) {
        _log('Widget unmounted during keyword building, aborting');
        return;
      }

      _log('Updating state with loaded categories...');
      setState(() {
        _categories = loadedCategories;
        _mainCategories = loadedCategories.where((cat) => cat['level'] == 0).toList();
        _categoryKeywords = keywords;
        _isLoadingCategories = false;
      });

      _log('Category loading complete:');
      _log('- Total categories: ${loadedCategories.length}');
      _log('- Main categories: ${_mainCategories.length}');
      _log('- Keywords: ${keywords.length}');
      _log('- Available keywords: ${keywords.keys.join(', ')}');

    } catch (e, stack) {
      _log('Error loading categories:');
      _log('Error: $e');
      _log('Stack trace: $stack');
      
      if (!mounted) {
        _log('Widget unmounted during error handling');
        return;
      }
      
      setState(() {
        _isLoadingCategories = false;
        _categories = [];
        _mainCategories = [];
        _categoryKeywords = {};
      });
    }
  }

  void _suggestCategory(String title, String description) {
    if (_isLoadingCategories || _categories.isEmpty || _categoryKeywords.isEmpty) {
      print('Cannot suggest category: ${_isLoadingCategories ? 'still loading' : _categories.isEmpty ? 'no categories' : 'no keywords'}');
      return;
    }

    final text = '$title $description'.toLowerCase().trim();
    if (text.length < 3) return;

    print('Looking for category match in text: "$text"');

    // Try exact matches first
    for (final entry in _categoryKeywords.entries) {
      if (text.contains(entry.key)) {
        print('Found exact match: "${entry.key}" -> ${entry.value['path']?.join(' > ')}');
        setState(() {
          _suggestedCategoryPath = Map<String, dynamic>.from(entry.value);
        });
        return;
      }
    }

    // Try word matching
    final words = text.split(RegExp(r'\s+'))
      ..removeWhere((w) => w.length < 3);
    
    if (words.isEmpty) return;

    var bestMatch = '';
    var bestScore = 0;

    for (final entry in _categoryKeywords.entries) {
      final keyword = entry.key;
      var score = 0;

      for (final word in words) {
        if (keyword.contains(word)) {
          score += word.length;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = keyword;
      }
    }

    if (bestScore > 0 && _categoryKeywords.containsKey(bestMatch)) {
      print('Best partial match: "$bestMatch" -> ${_categoryKeywords[bestMatch]!['path']?.join(' > ')}');
      setState(() {
        _suggestedCategoryPath = Map<String, dynamic>.from(_categoryKeywords[bestMatch]!);
      });
    } else {
      setState(() {
        _suggestedCategoryPath = null;
      });
    }
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

      print('✓ Found main category: ${mainCategory['name']} (ID: ${mainCategory['id']})');
      
      // Set main category
      setState(() {
        _selectedMainCategoryId = mainCategory['id'];
        _selectedCategoryName = mainCategory['name'];
        _selectedSubCategoryId = null;
        _selectedSubSubCategoryId = null;
        _selectedSubSubSubCategoryId = null;
      });

      // Load subcategories and category-specific fields
      _loadSubCategories(_selectedMainCategoryId!);
      await _loadCategorySpecificFields(_selectedMainCategoryId!);

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

          // Load sub-subcategories and category-specific fields
          _loadSubSubCategories(_selectedSubCategoryId!);
          await _loadCategorySpecificFields(_selectedSubCategoryId!);

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

              // Load sub-sub-subcategories and category-specific fields
              _loadSubSubSubCategories(_selectedSubSubCategoryId!);
              await _loadCategorySpecificFields(_selectedSubSubCategoryId!);

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
                  
                  // Load category-specific fields for the final level
                  await _loadCategorySpecificFields(_selectedSubSubSubCategoryId!);
                }
              }
            }
          }
        }
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
      // backgroundColor: Colors.white,
      appBar: AppBar(
         surfaceTintColor:Theme.of(context).appBarTheme.backgroundColor ,
        // surfaceTintColor: Colors.white,
        // backgroundColor: Colors.white,
        automaticallyImplyLeading: widget.isMain ? false : true,
        elevation: 0,
        title: Text(
     isEditMode ? 'Edit Item' :   AppLocalizations.itemDetails.tr(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            // color: Colors.black,
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
                  style: GoogleFonts.poppins(fontSize: 14,color: Colors.black),
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
                      // color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.completeTheseDetails.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      // color: Colors.grey[600],
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
                                AppLocalizations.newItem,
                                AppLocalizations.likeNew,
                                AppLocalizations.used,
                                AppLocalizations.refurbished
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
                      if (!_currentCategoryFieldTemplate.map((f) => f['name']).toList().contains('brand'))
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    hint: '${AppLocalizations.brand.tr()} (${AppLocalizations.optional.tr()})',
                                    onChanged: (value) => itemProvider.updateItemDetails(brand: value),
                                  ),
                                ),
                              ],
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
                      if (!_currentCategoryFieldTemplate.map((f) => f['name']).toList().contains('color'))
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    hint: '${AppLocalizations.color.tr()} (${AppLocalizations.optional.tr()})',
                                    onChanged: (value) => itemProvider.updateItemDetails(color: value),
                                  ),
                                ),
                              ],
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
        hintStyle: GoogleFonts.poppins(
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
            item.tr(),
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
        color: Colors.black
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