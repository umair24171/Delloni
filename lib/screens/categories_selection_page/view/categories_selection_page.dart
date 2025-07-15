import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
class CategorySelectionPage extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> mainCategories;
  final String? selectedMainCategoryId;
  final bool isForSearch; // NEW: Distinguish between search and add item

  const CategorySelectionPage({
    Key? key,
    required this.categories,
    required this.mainCategories,
    this.selectedMainCategoryId,
    this.isForSearch = false, // NEW: Default to add item behavior
  }) : super(key: key);

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedSubSubCategoryId;
  String? _selectedSubSubSubCategoryId;
  List<Map<String, dynamic>> _subCategories = [];
  List<Map<String, dynamic>> _subSubCategories = [];
  List<Map<String, dynamic>> _subSubSubCategories = [];

  @override
  void initState() {
    super.initState();
    if (widget.selectedMainCategoryId != null) {
      _selectedMainCategoryId = widget.selectedMainCategoryId;
      _loadSubCategories(widget.selectedMainCategoryId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isForSearch ? 'Select Category for Search' : AppLocalizations.selectCategoryTitle.tr(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            if (_selectedMainCategoryId != null || _selectedSubCategoryId != null || _selectedSubSubCategoryId != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_selectedMainCategoryId != null) ...[
                      Text(
                        _getSelectedCategoryName(_selectedMainCategoryId!, widget.categories),
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      if (_selectedSubCategoryId != null) ...[
                        Icon(Icons.chevron_right, size: 16),
                        Text(
                          _getSelectedCategoryName(_selectedSubCategoryId!, widget.categories),
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (_selectedSubSubCategoryId != null) ...[
                        Icon(Icons.chevron_right, size: 16),
                        Text(
                          _getSelectedCategoryName(_selectedSubSubCategoryId!, widget.categories),
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (_selectedSubSubSubCategoryId != null) ...[
                        Icon(Icons.chevron_right, size: 16),
                        Text(
                          _getSelectedCategoryName(_selectedSubSubSubCategoryId!, widget.categories),
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
           
            SizedBox(height: 16),

            // NEW: Select All button section (only for search)
            if (widget.isForSearch) ...[
              _buildSelectAllSection(),
              SizedBox(height: 16),
            ],

            Text(
              _selectedSubSubSubCategoryId != null 
                  ? AppLocalizations.chooseSubSubSubcategory.tr()
                  : _selectedSubSubCategoryId != null 
                      ? AppLocalizations.chooseSubSubcategory.tr()
                      : _selectedSubCategoryId != null 
                          ? AppLocalizations.chooseSubcategory.tr()
                          : AppLocalizations.chooseMainCategory.tr(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: _getCurrentCategories().length,
                itemBuilder: (context, index) {
                  final category = _getCurrentCategories()[index];
                  return _buildCategoryTile(category);
                },
              ),
            ),

            // Done button (only show when category is selected and no auto-selection occurred)
            if (_selectedMainCategoryId != null && 
                _getCurrentCategories().isNotEmpty && 
                _selectedSubSubSubCategoryId == null &&
                _subSubSubCategories.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: () {
                    final finalCategoryId = _selectedSubSubSubCategoryId ?? 
                                          _selectedSubSubCategoryId ?? 
                                          _selectedSubCategoryId ?? 
                                          _selectedMainCategoryId;
                    final categoryName = _getSelectedCategoryName(finalCategoryId!, widget.categories);

                    Navigator.pop(context, {
                      'mainCategoryId': _selectedMainCategoryId,
                      'subCategoryId': _selectedSubCategoryId,
                      'subSubCategoryId': _selectedSubSubCategoryId,
                      'subSubSubCategoryId': _selectedSubSubSubCategoryId,
                      'finalCategoryId': finalCategoryId,
                      'categoryName': categoryName,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsController.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.selectThisCategory.tr(),
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
    );
  }

  // NEW: Build Select All section
  Widget _buildSelectAllSection() {
    if (!widget.isForSearch) return SizedBox.shrink();

    String selectAllText = '';
    String categoryName = '';
    bool showSelectAll = false;

    if (_selectedMainCategoryId != null && _subCategories.isNotEmpty && _selectedSubCategoryId == null) {
      // Show "Select All Subcategories" under main category
      categoryName = _getSelectedCategoryName(_selectedMainCategoryId!, widget.categories);
      selectAllText = 'Select All in "$categoryName"';
      showSelectAll = true;
    } else if (_selectedSubCategoryId != null && _subSubCategories.isNotEmpty && _selectedSubSubCategoryId == null) {
      // Show "Select All Sub-subcategories" under subcategory
      categoryName = _getSelectedCategoryName(_selectedSubCategoryId!, widget.categories);
      selectAllText = 'Select All in "$categoryName"';
      showSelectAll = true;
    } else if (_selectedSubSubCategoryId != null && _subSubSubCategories.isNotEmpty && _selectedSubSubSubCategoryId == null) {
      // Show "Select All Sub-sub-subcategories" under sub-subcategory
      categoryName = _getSelectedCategoryName(_selectedSubSubCategoryId!, widget.categories);
      selectAllText = 'Select All in "$categoryName"';
      showSelectAll = true;
    }

    if (!showSelectAll) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.select_all, color: Colors.blue[700], size: 32),
          SizedBox(height: 8),
          Text(
            selectAllText,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Search in all subcategories at once',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.blue[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Return the current selected category as "select all"
                final finalCategoryId = _selectedSubSubCategoryId ?? 
                                      _selectedSubCategoryId ?? 
                                      _selectedMainCategoryId;
                final finalCategoryName = _getSelectedCategoryName(finalCategoryId!, widget.categories);

                Navigator.pop(context, {
                  'mainCategoryId': _selectedMainCategoryId,
                  'subCategoryId': _selectedSubCategoryId,
                  'subSubCategoryId': _selectedSubSubCategoryId,
                  'subSubSubCategoryId': null,
                  'finalCategoryId': finalCategoryId,
                  'categoryName': finalCategoryName,
                  'isSelectAll': true, // NEW: Flag to indicate this is a "select all"
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Select All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getCurrentCategories() {
    if (_selectedSubSubSubCategoryId != null) {
      return _subSubSubCategories;
    } else if (_selectedSubSubCategoryId != null) {
      return _subSubCategories;
    } else if (_selectedSubCategoryId != null) {
      return _subSubCategories;
    } else if (_selectedMainCategoryId != null) {
      return _subCategories;
    } else {
      return widget.mainCategories;
    }
  }

  Widget _buildCategoryTile(Map<String, dynamic> category) {
    final isSelected = category['id'] == _selectedMainCategoryId ||
                      category['id'] == _selectedSubCategoryId ||
                      category['id'] == _selectedSubSubCategoryId ||
                      category['id'] == _selectedSubSubSubCategoryId;

    return InkWell(
      onTap: () async {
        final categoryId = category['id'];
        final level = category['level'] ?? 0;

        if (level == 0) {
          // Main category selected
          setState(() {
            _selectedMainCategoryId = categoryId;
            _selectedSubCategoryId = null;
            _selectedSubSubCategoryId = null;
            _selectedSubSubSubCategoryId = null;
            _loadSubCategories(categoryId);
          });
          
          // Check if there are no subcategories - auto-select
          await Future.delayed(Duration(milliseconds: 200));
          if (_subCategories.isEmpty || !widget.isForSearch) {
            final finalCategoryId = categoryId;
            final categoryName = category['name'] ?? 'Unknown';
            
            Navigator.pop(context, {
              'mainCategoryId': finalCategoryId,
              'subCategoryId': null,
              'subSubCategoryId': null,
              'subSubSubCategoryId': null,
              'finalCategoryId': finalCategoryId,
              'categoryName': categoryName,
            });
          }
        } else if (level == 1) {
          // Subcategory selected
          setState(() {
            _selectedSubCategoryId = categoryId;
            _selectedSubSubCategoryId = null;
            _selectedSubSubSubCategoryId = null;
            _loadSubSubCategories(categoryId);
          });
          
          // Check if there are no sub-subcategories - auto-select
          await Future.delayed(Duration(milliseconds: 200));
          if (_subSubCategories.isEmpty || !widget.isForSearch) {
            final finalCategoryId = categoryId;
            final categoryName = category['name'] ?? 'Unknown';
            
            Navigator.pop(context, {
              'mainCategoryId': _selectedMainCategoryId,
              'subCategoryId': finalCategoryId,
              'subSubCategoryId': null,
              'subSubSubCategoryId': null,
              'finalCategoryId': finalCategoryId,
              'categoryName': categoryName,
            });
          }
        } else if (level == 2) {
          // Sub-subcategory selected
          setState(() {
            _selectedSubSubCategoryId = categoryId;
            _selectedSubSubSubCategoryId = null;
            _loadSubSubSubCategories(categoryId);
          });
          
          // Check if there are no sub-sub-subcategories - auto-select
          await Future.delayed(Duration(milliseconds: 200));
          if (_subSubSubCategories.isEmpty || !widget.isForSearch) {
            final finalCategoryId = categoryId;
            final categoryName = category['name'] ?? 'Unknown';
            
            Navigator.pop(context, {
              'mainCategoryId': _selectedMainCategoryId,
              'subCategoryId': _selectedSubCategoryId,
              'subSubCategoryId': finalCategoryId,
              'subSubSubCategoryId': null,
              'finalCategoryId': finalCategoryId,
              'categoryName': categoryName,
            });
          }
        } else if (level == 3) {
          // Sub-sub-subcategory selected - Auto-select and return
          setState(() {
            _selectedSubSubSubCategoryId = categoryId;
          });
          
          // Auto-return with the selected category
          final finalCategoryId = categoryId;
          final categoryName = category['name'] ?? 'Unknown';
          
          Navigator.pop(context, {
            'mainCategoryId': _selectedMainCategoryId,
            'subCategoryId': _selectedSubCategoryId,
            'subSubCategoryId': _selectedSubSubCategoryId,
            'subSubSubCategoryId': finalCategoryId,
            'finalCategoryId': finalCategoryId,
            'categoryName': categoryName,
          });
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ColorsController.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? ColorsController.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            if (category['icon'] != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorsController.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.category,
                  color: ColorsController.primaryColor,
                  size: 20,
                ),
              ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                category['name'] ?? 'Unknown',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? ColorsController.primaryColor : Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _loadSubCategories(String mainCategoryId) {
    _subCategories = widget.categories
        .where((cat) => cat['parentId'] == mainCategoryId && cat['level'] == 1)
        .toList();
    _subSubCategories = [];
    _subSubSubCategories = [];
  }

  void _loadSubSubCategories(String subCategoryId) {
    _subSubCategories = widget.categories
        .where((cat) => cat['parentId'] == subCategoryId && cat['level'] == 2)
        .toList();
    _subSubSubCategories = [];
  }

  void _loadSubSubSubCategories(String subSubCategoryId) {
    _subSubSubCategories = widget.categories
        .where((cat) => cat['parentId'] == subSubCategoryId && cat['level'] == 3)
        .toList();
  }

  String _getSelectedCategoryName(String categoryId, List<Map<String, dynamic>> categories) {
    final category = categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => <String, dynamic>{},
    );
    return category['name'] ?? 'Unknown';
  }
}