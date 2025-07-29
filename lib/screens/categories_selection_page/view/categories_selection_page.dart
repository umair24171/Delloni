import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
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
  final bool isForSearch; // Distinguish between search and add item

  const CategorySelectionPage({
    Key? key,
    required this.categories,
    required this.mainCategories,
    this.selectedMainCategoryId,
    this.isForSearch = false,
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
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.isForSearch ? 'Select Category for Search'.tr() : AppLocalizations.selectCategoryTitle.tr(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            _buildBreadcrumb(),
            
            SizedBox(height: 16),

            // Select All section (only for search)
            if (widget.isForSearch) ...[
              _buildSelectAllSection(),
              SizedBox(height: 16),
            ],

            // Current level title
            Text(
              _getCurrentLevelTitle(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),

            // Categories list
            Expanded(
              child: ListView.builder(
                itemCount: _getCurrentCategories().length,
                itemBuilder: (context, index) {
                  final category = _getCurrentCategories()[index];
                  return _buildCategoryTile(category);
                },
              ),
            ),

            // Done button (for item adding - allow selection at any level)
            if (!widget.isForSearch && _selectedMainCategoryId != null)
              _buildDoneButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    if (_selectedMainCategoryId == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              children: [
                _buildBreadcrumbItem(_selectedMainCategoryId!, true),
                if (_selectedSubCategoryId != null) ...[
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
                  _buildBreadcrumbItem(_selectedSubCategoryId!, true),
                ],
                if (_selectedSubSubCategoryId != null) ...[
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
                  _buildBreadcrumbItem(_selectedSubSubCategoryId!, true),
                ],
                if (_selectedSubSubSubCategoryId != null) ...[
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
                  _buildBreadcrumbItem(_selectedSubSubSubCategoryId!, false),
                ],
              ],
            ),
          ),
          // Back button for navigation
          if (_selectedSubSubSubCategoryId != null || 
              _selectedSubSubCategoryId != null || 
              _selectedSubCategoryId != null)
            IconButton(
              icon: Icon(Icons.arrow_back, size: 20),
              onPressed: _goBackOneLevel,
              padding: EdgeInsets.all(4),
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(String categoryId, bool isClickable) {
    final name = _getSelectedCategoryName(categoryId, widget.categories);
    return isClickable 
        ? InkWell(
            onTap: () => _navigateToCategoryLevel(categoryId),
            child: Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 14, 
                fontWeight: FontWeight.w500,
                color: ColorsController.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          )
        : Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14, 
              fontWeight: FontWeight.w500,
            ),
          );
  }

  void _goBackOneLevel() {
    setState(() {
      if (_selectedSubSubSubCategoryId != null) {
        _selectedSubSubSubCategoryId = null;
        _subSubSubCategories = [];
      } else if (_selectedSubSubCategoryId != null) {
        _selectedSubSubCategoryId = null;
        _subSubCategories = [];
        _subSubSubCategories = [];
      } else if (_selectedSubCategoryId != null) {
        _selectedSubCategoryId = null;
        _subCategories = _subCategories; // Keep subcategories
        _subSubCategories = [];
        _subSubSubCategories = [];
      } else if (_selectedMainCategoryId != null) {
        _selectedMainCategoryId = null;
        _subCategories = [];
        _subSubCategories = [];
        _subSubSubCategories = [];
      }
    });
  }

  void _navigateToCategoryLevel(String categoryId) {
    // Navigate back to the selected category level
    final category = widget.categories.firstWhere((cat) => cat['id'] == categoryId);
    final level = category['level'] ?? 0;

    setState(() {
      if (level == 0) {
        _selectedMainCategoryId = categoryId;
        _selectedSubCategoryId = null;
        _selectedSubSubCategoryId = null;
        _selectedSubSubSubCategoryId = null;
        _loadSubCategories(categoryId);
      } else if (level == 1) {
        _selectedSubCategoryId = categoryId;
        _selectedSubSubCategoryId = null;
        _selectedSubSubSubCategoryId = null;
        _loadSubSubCategories(categoryId);
      } else if (level == 2) {
        _selectedSubSubCategoryId = categoryId;
        _selectedSubSubSubCategoryId = null;
        _loadSubSubSubCategories(categoryId);
      }
    });
  }

  String _getCurrentLevelTitle() {
    if (_selectedSubSubSubCategoryId != null) {
      return AppLocalizations.chooseSubSubSubcategory.tr();
    } else if (_selectedSubSubCategoryId != null) {
      return AppLocalizations.chooseSubSubcategory.tr();
    } else if (_selectedSubCategoryId != null) {
      return AppLocalizations.chooseSubcategory.tr();
    } else if (_selectedMainCategoryId != null) {
      return AppLocalizations.chooseSubcategory.tr();
    } else {
      return AppLocalizations.chooseMainCategory.tr();
    }
  }

  Widget _buildSelectAllSection() {
    if (!widget.isForSearch) return SizedBox.shrink();

    String selectAllText = '';
    String categoryName = '';
    bool showSelectAll = false;

    // Show "Select All" when there are subcategories to include
    if (_selectedMainCategoryId != null && _subCategories.isNotEmpty && _selectedSubCategoryId == null) {
      categoryName = _getSelectedCategoryName(_selectedMainCategoryId!, widget.categories);
      selectAllText = 'Search in all "$categoryName" subcategories';
      showSelectAll = true;
    } else if (_selectedSubCategoryId != null && _subSubCategories.isNotEmpty && _selectedSubSubCategoryId == null) {
      categoryName = _getSelectedCategoryName(_selectedSubCategoryId!, widget.categories);
      selectAllText = 'Search in all "$categoryName" subcategories';
      showSelectAll = true;
    } else if (_selectedSubSubCategoryId != null && _subSubSubCategories.isNotEmpty && _selectedSubSubSubCategoryId == null) {
      categoryName = _getSelectedCategoryName(_selectedSubSubCategoryId!, widget.categories);
      selectAllText = 'Search in all "$categoryName" subcategories';
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Include all subcategories in search results'.tr(),
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
              onPressed: () => _selectAllSubcategories(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Select All Subcategories'.tr(),
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

  void _selectAllSubcategories() {
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
      'isSelectAll': true,
    });
  }

  Widget _buildDoneButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: () => _selectCurrentCategory(),
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
    );
  }

  void _selectCurrentCategory() {

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
      'mainCategoryName': _getSelectedCategoryName(_selectedMainCategoryId!, widget.categories),
      
    });
  }

  List<Map<String, dynamic>> _getCurrentCategories() {
    if (_selectedSubSubCategoryId != null) {
      return _subSubSubCategories;
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

    // Check if this category has subcategories
    final hasSubcategories = _hasSubcategories(category['id'], category['level']);

    return InkWell(
      onTap: () => _onCategoryTap(category),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(16).copyWith(left:category['iconUrl'] == null? 50:10),
        decoration: BoxDecoration(
          color: isSelected ? ColorsController.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? ColorsController.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            // Category icon
       if(category['iconUrl'] != null)     Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                // color: ColorsController.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: category['iconUrl'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        category['iconUrl'],
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: SizedBox(width: 20,),
                          );
                        },
                      ),
                    )
                  : Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: SizedBox(width: 20,),
                  ),
            ),
            SizedBox(width: 12),
            
            // Category name and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'] ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? ColorsController.primaryColor : Colors.black,
                    ),
                  ),
                  if (hasSubcategories && widget.isForSearch)
                    Text(
                      'Has subcategories',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Select this category button (for search)
                if (widget.isForSearch && _selectedMainCategoryId != null)
                  InkWell(
                    onTap: () => _selectSpecificCategory(category),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Text(
                        'Select',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ),
                
                if (widget.isForSearch && _selectedMainCategoryId != null)
                  SizedBox(width: 8),
                
                // Navigation arrow
                Icon(
                  hasSubcategories ? Icons.arrow_forward_ios : Icons.check_circle_outline,
                  size: 16,
                  color: hasSubcategories ? Colors.grey[600] : Colors.green[600],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _hasSubcategories(String categoryId, int currentLevel) {
    return widget.categories.any((cat) => 
        cat['parentId'] == categoryId && cat['level'] == currentLevel + 1);
  }

  void _onCategoryTap(Map<String, dynamic> category) async {
    final categoryId = category['id'];
    final level = category['level'] ?? 0;
    final hasSubcategories = _hasSubcategories(categoryId, level);

    print('🏷️ Category tapped: ${category['name']} (Level: $level, Has subcategories: $hasSubcategories)');

    if (level == 0) {
      // Main category selected
      setState(() {
        _selectedMainCategoryId = categoryId;
        _selectedSubCategoryId = null;
        _selectedSubSubCategoryId = null;
        _selectedSubSubSubCategoryId = null;
      });
      print('🏷️ Main category selected: ${category['name']}');
      Provider.of<ItemProvider>(context, listen: false).setSelectedMainCategoryForImages(category['name']);
      
      if (hasSubcategories) {
        _loadSubCategories(categoryId);
      } else {
        // No subcategories - auto-select for both search and item adding
        _selectSpecificCategory(category);
      }
      
    } else if (level == 1) {
      // Subcategory selected
      setState(() {
        _selectedSubCategoryId = categoryId;
        _selectedSubSubCategoryId = null;
        _selectedSubSubSubCategoryId = null;
      });
      
      if (hasSubcategories) {
        _loadSubSubCategories(categoryId);
      } else {
        // No subcategories - auto-select for both search and item adding
        _selectSpecificCategory(category);
      }
      
    } else if (level == 2) {
      // Sub-subcategory selected
      setState(() {
        _selectedSubSubCategoryId = categoryId;
        _selectedSubSubSubCategoryId = null;
      });
      
      if (hasSubcategories) {
        _loadSubSubSubCategories(categoryId);
      } else {
        // No subcategories - auto-select for both search and item adding
        _selectSpecificCategory(category);
      }
      
    } else if (level == 3) {
      // Sub-sub-subcategory selected - always auto-select (deepest level)
      _selectSpecificCategory(category);
    }
  }

  void _selectSpecificCategory(Map<String, dynamic> category) {
    final categoryId = category['id'];
    final categoryName = category['name'] ?? 'Unknown';
    final level = category['level'] ?? 0;

    // Update state based on level
    if (level == 0) {
      _selectedMainCategoryId = categoryId;
    } else if (level == 1) {
      _selectedSubCategoryId = categoryId;
    } else if (level == 2) {
      _selectedSubSubCategoryId = categoryId;
    } else if (level == 3) {
      _selectedSubSubSubCategoryId = categoryId;
    }

    Navigator.pop(context, {
      'mainCategoryId': level >= 0 ? _selectedMainCategoryId : null,
      'subCategoryId': level >= 1 ? _selectedSubCategoryId : null,
      'subSubCategoryId': level >= 2 ? _selectedSubSubCategoryId : null,
      'subSubSubCategoryId': level >= 3 ? _selectedSubSubSubCategoryId : null,
      'finalCategoryId': categoryId,
      'categoryName': categoryName,
    });
  }

  void _loadSubCategories(String mainCategoryId) {
    _subCategories = widget.categories
        .where((cat) => cat['parentId'] == mainCategoryId && cat['level'] == 1)
        .toList();
    _subSubCategories = [];
    _subSubSubCategories = [];
    
    print('📂 Loaded ${_subCategories.length} subcategories for $mainCategoryId');
  }

  void _loadSubSubCategories(String subCategoryId) {
    _subSubCategories = widget.categories
        .where((cat) => cat['parentId'] == subCategoryId && cat['level'] == 2)
        .toList();
    _subSubSubCategories = [];
    
    print('📂 Loaded ${_subSubCategories.length} sub-subcategories for $subCategoryId');
  }

  void _loadSubSubSubCategories(String subSubCategoryId) {
    _subSubSubCategories = widget.categories
        .where((cat) => cat['parentId'] == subSubCategoryId && cat['level'] == 3)
        .toList();
    
    print('📂 Loaded ${_subSubSubCategories.length} sub-sub-subcategories for $subSubCategoryId');
  }

  String _getSelectedCategoryName(String categoryId, List<Map<String, dynamic>> categories) {
    final category = categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => <String, dynamic>{},
    );
    return category['name'] ?? 'Unknown';
  }
}