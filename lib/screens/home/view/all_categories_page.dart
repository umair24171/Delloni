// =====================================================
// ALL CATEGORIES PAGE
// =====================================================
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/home/controller/home_provider.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:arabicmarketplace/widgets/image_optimise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AllCategoriesPage extends StatefulWidget {
  @override
  _AllCategoriesPageState createState() => _AllCategoriesPageState();
}

class _AllCategoriesPageState extends State<AllCategoriesPage> {
  bool _isMultiSelectMode = false;
  Set<String> _selectedCategoryIds = {};
  Map<String, String> _selectedCategoryNames = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isMultiSelectMode 
            ? 'Select Categories (${_selectedCategoryIds.length})' 
            : 'All Categories'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Multi-select toggle button
          IconButton(
            icon: Icon(_isMultiSelectMode ? Icons.close : Icons.checklist),
            onPressed: () {
              setState(() {
                _isMultiSelectMode = !_isMultiSelectMode;
                if (!_isMultiSelectMode) {
                  _selectedCategoryIds.clear();
                  _selectedCategoryNames.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          if (homeProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Multi-select info banner
              if (_isMultiSelectMode)
                Container(
                  width: double.infinity,
                  color: ColorsController.primaryColor.withOpacity(0.1),
                  padding: EdgeInsets.all(12),
                  child: Text(
                    _selectedCategoryIds.isEmpty 
                        ? 'Tap categories to select them'
                        : 'Selected: ${_selectedCategoryNames.values.join(', ')}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: ColorsController.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Categories grid
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: homeProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = homeProvider.categories[index];
                    return _buildCategoryCard(category);
                  },
                ),
              ),
              
              // View selected products button
              if (_isMultiSelectMode && _selectedCategoryIds.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _viewSelectedProducts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsController.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'View Products from ${_selectedCategoryIds.length} Categories',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final categoryId = category['id'] ?? '';
    final isSelected = _selectedCategoryIds.contains(categoryId);

    return InkWell(
      onTap: () {
        if (_isMultiSelectMode) {
          _toggleCategorySelection(category);
        } else {
          _navigateToCategoryHierarchy(category);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: _isMultiSelectMode && isSelected
              ? Border.all(color: ColorsController.primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getColorFromHex(category['color'] ?? '#666666').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: UniversalImage(
                    imageUrl: category['iconUrl'] ?? '',
                    fit: BoxFit.cover,
                    height: 60,
                    width: 60,
                    errorWidget: Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.category, size: 30, color: Colors.grey[400]),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    category['name'] ?? 'Category',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            // Selection checkbox
            if (_isMultiSelectMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? ColorsController.primaryColor : Colors.white,
                    border: Border.all(
                      color: isSelected ? ColorsController.primaryColor : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleCategorySelection(Map<String, dynamic> category) {
    final categoryId = category['id'] ?? '';
    final categoryName = category['name'] ?? 'Category';
    
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
        _selectedCategoryNames.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
        _selectedCategoryNames[categoryId] = categoryName;
      }
    });
  }

  void _viewSelectedProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiCategoryProductsPage(
          categoryIds: _selectedCategoryIds.toList(),
          categoryNames: _selectedCategoryNames,
        ),
      ),
    );
  }

  void _navigateToCategoryHierarchy(Map<String, dynamic> category) {
    final categoryId = category['id'] ?? '';
    final categoryName = category['name'] ?? '';
    final level = category['level'] ?? 0;

    if (level == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubCategoriesPage(
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        ),
      );
    } else if (level == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubSubCategoriesPage(
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryProductsPage(
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        ),
      );
    }
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
// =====================================================
// SUB CATEGORIES PAGE (Level 1)
// =====================================================
class SubCategoriesPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const SubCategoriesPage({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _SubCategoriesPageState createState() => _SubCategoriesPageState();
}

class _SubCategoriesPageState extends State<SubCategoriesPage> {
  List<Map<String, dynamic>> subCategories = [];
  bool isLoading = true;
  bool _isMultiSelectMode = false;
  Set<String> _selectedCategoryIds = {};
  Map<String, String> _selectedCategoryNames = {};

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
  }

  Future<void> _loadSubCategories() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('parentId', isEqualTo: widget.categoryId)
          .where('level', isEqualTo: 1)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      setState(() {
        subCategories = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading subcategories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isMultiSelectMode 
            ? 'Select Subcategories (${_selectedCategoryIds.length})' 
            : widget.categoryName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (subCategories.isNotEmpty)
            IconButton(
              icon: Icon(_isMultiSelectMode ? Icons.close : Icons.checklist),
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = !_isMultiSelectMode;
                  if (!_isMultiSelectMode) {
                    _selectedCategoryIds.clear();
                    _selectedCategoryNames.clear();
                  }
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : subCategories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No subcategories found',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductsPage(
                                categoryId: widget.categoryId,
                                categoryName: widget.categoryName,
                              ),
                            ),
                          );
                        },
                        child: Text('View Products'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Multi-select info banner
                    if (_isMultiSelectMode)
                      Container(
                        width: double.infinity,
                        color: ColorsController.primaryColor.withOpacity(0.1),
                        padding: EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              _selectedCategoryIds.isEmpty 
                                  ? 'Tap subcategories to select them'
                                  : 'Selected: ${_selectedCategoryNames.values.join(', ')}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: ColorsController.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_selectedCategoryIds.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        for (var category in subCategories) {
                                          final id = category['id'] ?? '';
                                          final name = category['name'] ?? '';
                                          _selectedCategoryIds.add(id);
                                          _selectedCategoryNames[id] = name;
                                        }
                                      });
                                    },
                                    icon: Icon(Icons.select_all, size: 16),
                                    label: Text('Select All'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: ColorsController.primaryColor,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedCategoryIds.clear();
                                        _selectedCategoryNames.clear();
                                      });
                                    },
                                    icon: Icon(Icons.clear, size: 16),
                                    label: Text('Clear All'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    
                    // Subcategories list
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: subCategories.length,
                        itemBuilder: (context, index) {
                          final subCategory = subCategories[index];
                          return _buildSubCategoryItem(subCategory);
                        },
                      ),
                    ),
                    
                    // View selected products button
                    if (_isMultiSelectMode && _selectedCategoryIds.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: _viewSelectedProducts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsController.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'View Products from ${_selectedCategoryIds.length} Subcategories',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildSubCategoryItem(Map<String, dynamic> subCategory) {
    final categoryId = subCategory['id'] ?? '';
    final isSelected = _selectedCategoryIds.contains(categoryId);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (_isMultiSelectMode) {
            _toggleCategorySelection(subCategory);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubSubCategoriesPage(
                  categoryId: subCategory['id'],
                  categoryName: subCategory['name'],
                ),
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: _isMultiSelectMode && isSelected
                ? Border.all(color: ColorsController.primaryColor, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Selection checkbox
              if (_isMultiSelectMode)
                Container(
                  width: 24,
                  height: 24,
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? ColorsController.primaryColor : Colors.white,
                    border: Border.all(
                      color: isSelected ? ColorsController.primaryColor : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              
              // Category icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getColorFromHex(subCategory['color'] ?? '#666666').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: UniversalImage(
                  imageUrl: subCategory['iconUrl'] ?? '',
                  fit: BoxFit.cover,
                  height: 50,
                  width: 50,
                  errorWidget: Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.category, size: 25, color: Colors.grey[400]),
                  ),
                ),
              ),
              SizedBox(width: 16),
              
              // Category info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subCategory['name'] ?? 'Subcategory',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (subCategory['description'] != null)
                      Text(
                        subCategory['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              // Arrow or selection indicator
              if (!_isMultiSelectMode)
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleCategorySelection(Map<String, dynamic> category) {
    final categoryId = category['id'] ?? '';
    final categoryName = category['name'] ?? 'Category';
    
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
        _selectedCategoryNames.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
        _selectedCategoryNames[categoryId] = categoryName;
      }
    });
  }

  void _viewSelectedProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiCategoryProductsPage(
          categoryIds: _selectedCategoryIds.toList(),
          categoryNames: _selectedCategoryNames,
        ),
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

// =====================================================
// SUB-SUB CATEGORIES PAGE (Level 2)
// =====================================================
class SubSubCategoriesPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const SubSubCategoriesPage({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _SubSubCategoriesPageState createState() => _SubSubCategoriesPageState();
}

class _SubSubCategoriesPageState extends State<SubSubCategoriesPage> {
  List<Map<String, dynamic>> subSubCategories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubSubCategories();
  }

  Future<void> _loadSubSubCategories() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('parentId', isEqualTo: widget.categoryId)
          .where('level', isEqualTo: 2)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      setState(() {
        subSubCategories = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading sub-subcategories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : subSubCategories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No sub-subcategories found',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductsPage(
                                categoryId: widget.categoryId,
                                categoryName: widget.categoryName,
                              ),
                            ),
                          );
                        },
                        child: Text('View Products'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: subSubCategories.length,
                  itemBuilder: (context, index) {
                    final subSubCategory = subSubCategories[index];
                    return _buildSubSubCategoryItem(subSubCategory);
                  },
                ),
    );
  }

  Widget _buildSubSubCategoryItem(Map<String, dynamic> subSubCategory) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryProductsPage(
                categoryId: subSubCategory['id'],
                categoryName: subSubCategory['name'],
              ),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getColorFromHex(subSubCategory['color'] ?? '#666666').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: UniversalImage(
                  imageUrl: subSubCategory['iconUrl'] ?? '',
                  fit: BoxFit.cover,
                  height: 50,
                  width: 50,
                  errorWidget: Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.category, size: 25, color: Colors.grey[400]),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subSubCategory['name'] ?? 'Sub-subcategory',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,color: Colors.black
                      ),
                    ),
                    if (subSubCategory['description'] != null)
                      Text(
                        subSubCategory['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

// =====================================================
// CATEGORY PRODUCTS PAGE (Final Level)
// =====================================================
class CategoryProductsPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsPage({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _CategoryProductsPageState createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  String sortBy = 'createdAt';
  bool ascending = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        isLoading = true;
      });

      Query query = FirebaseFirestore.instance
          .collection('items')
          .where('category', isEqualTo: widget.categoryId)
          .where('status', isEqualTo: 'active');

      if (sortBy == 'price') {
        query = query.orderBy('price', descending: !ascending);
      } else if (sortBy == 'createdAt') {
        query = query.orderBy('createdAt', descending: !ascending);
      } else if (sortBy == 'viewCount') {
        query = query.orderBy('viewCount', descending: !ascending);
      }

      final querySnapshot = await query.get();

      setState(() {
        products = querySnapshot.docs
            .map<Map<String, dynamic>>((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                if (data != null) ...Map<String, dynamic>.from(data as Map),
              };
            })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == sortBy) {
                  ascending = !ascending;
                } else {
                  sortBy = value;
                  ascending = false;
                }
              });
              _loadProducts();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'createdAt', child: Text('Sort by Date',style:  TextStyle(color: Colors.black
              ),)),
              PopupMenuItem(value: 'price', child: Text('Sort by Price',style:  TextStyle(color: Colors.black
              ))),
              PopupMenuItem(value: 'viewCount', child: Text('Sort by Views',style:  TextStyle(color: Colors.black
              ))),
            ],
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No products found in this category',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product);
                  },
                ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product['id']),
          ),
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
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: _buildProductImage(product),
                    ),
                    if (product['allowPriceNegotiation'] == true)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.yellow[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Negotiable',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Content Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['itemTitle'] ?? 'Product Title',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getFormattedPrice(product['price']),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Spacer(),
                    Text(
                      product['condition'] ?? 'Used',
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    final imageUrls = product['imageUrls'] as List<dynamic>?;
    
    if (imageUrls != null && imageUrls.isNotEmpty) {
      return UniversalImage(
        imageUrl: imageUrls.first.toString(),
        fit: BoxFit.cover,
        width: double.infinity,
        errorWidget: Container(
          color: Colors.grey[200],
          child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
      );
    }
  }

  String _getFormattedPrice(dynamic price) {
    if (price == null) return 'Price not set';
    
    try {
      final priceValue = price is num ? price.toDouble() : double.parse(price.toString());
      return 'PKR ${priceValue.toStringAsFixed(0)}';
    } catch (e) {
      return 'Price not set';
    }
  }
}

class MultiCategoryProductsPage extends StatefulWidget {
  final List<String> categoryIds;
  final Map<String, String> categoryNames;

  const MultiCategoryProductsPage({
    Key? key,
    required this.categoryIds,
    required this.categoryNames,
  }) : super(key: key);

  @override
  _MultiCategoryProductsPageState createState() => _MultiCategoryProductsPageState();
}

class _MultiCategoryProductsPageState extends State<MultiCategoryProductsPage> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  String sortBy = 'createdAt';
  bool ascending = false;
  Map<String, int> categoryProductCounts = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        isLoading = true;
      });

      List<Map<String, dynamic>> allProducts = [];
      Map<String, int> counts = {};

      // Load products from each selected category
      for (String categoryId in widget.categoryIds) {
        Query query = FirebaseFirestore.instance
            .collection('items')
            .where('category', isEqualTo: categoryId)
            .where('status', isEqualTo: 'active');

        if (sortBy == 'price') {
          query = query.orderBy('price', descending: !ascending);
        } else if (sortBy == 'createdAt') {
          query = query.orderBy('createdAt', descending: !ascending);
        } else if (sortBy == 'viewCount') {
          query = query.orderBy('viewCount', descending: !ascending);
        }

        final querySnapshot = await query.get();
        final categoryProducts = querySnapshot.docs
            .map<Map<String, dynamic>>((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                if (data != null) ...Map<String, dynamic>.from(data as Map),
              };
            })
            .toList();

        allProducts.addAll(categoryProducts);
        counts[categoryId] = categoryProducts.length;
      }

      // Remove duplicates (in case a product belongs to multiple selected categories)
      final Map<String, Map<String, dynamic>> uniqueProducts = {};
      for (var product in allProducts) {
        uniqueProducts[product['id']] = product;
      }

      // Sort all products together
      final List<Map<String, dynamic>> sortedProducts = uniqueProducts.values.toList();
      if (sortBy == 'price') {
        sortedProducts.sort((a, b) => ascending 
            ? (a['price'] ?? 0).compareTo(b['price'] ?? 0)
            : (b['price'] ?? 0).compareTo(a['price'] ?? 0));
      } else if (sortBy == 'createdAt') {
        sortedProducts.sort((a, b) {
          final aDate = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bDate = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
        });
      } else if (sortBy == 'viewCount') {
        sortedProducts.sort((a, b) => ascending
            ? (a['viewCount'] ?? 0).compareTo(b['viewCount'] ?? 0)
            : (b['viewCount'] ?? 0).compareTo(a['viewCount'] ?? 0));
      }

      setState(() {
        products = sortedProducts;
        categoryProductCounts = counts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected Categories'),
            Text(
              '${products.length} products from ${widget.categoryIds.length} categories',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == sortBy) {
                  ascending = !ascending;
                } else {
                  sortBy = value;
                  ascending = false;
                }
              });
              _loadProducts();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'createdAt', child: Text('Sort by Date', style: TextStyle(color: Colors.black))),
              PopupMenuItem(value: 'price', child: Text('Sort by Price', style: TextStyle(color: Colors.black))),
              PopupMenuItem(value: 'viewCount', child: Text('Sort by Views', style: TextStyle(color: Colors.black))),
            ],
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Selected categories summary
                Container(
                  width: double.infinity,
                  color: Colors.grey[50],
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categories:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: widget.categoryNames.entries.map((entry) {
                          final count = categoryProductCounts[entry.key] ?? 0;
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ColorsController.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${entry.value} ($count)',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: ColorsController.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                // Products grid
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No products found in selected categories',
                                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _buildProductCard(product);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product['id']),
          ),
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
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: _buildProductImage(product),
                    ),
                    // Category badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: ColorsController.primaryColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.categoryNames[product['category']] ?? 'Category',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (product['allowPriceNegotiation'] == true)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.yellow[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Negotiable',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Content Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['itemTitle'] ?? 'Product Title',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getFormattedPrice(product['price']),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Spacer(),
                    Text(
                      product['condition'] ?? 'Used',
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    final imageUrls = product['imageUrls'] as List<dynamic>?;
    
    if (imageUrls != null && imageUrls.isNotEmpty) {
      return UniversalImage(
        imageUrl: imageUrls.first.toString(),
        fit: BoxFit.cover,
        width: double.infinity,
        errorWidget: Container(
          color: Colors.grey[200],
          child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
      );
    }
  }

  String _getFormattedPrice(dynamic price) {
    if (price == null) return 'Price not set';
    
    try {
      final priceValue = price is num ? price.toDouble() : double.parse(price.toString());
      return 'PKR ${priceValue.toStringAsFixed(0)}';
    } catch (e) {
      return 'Price not set';
    }
  }
}

// =====================================================
// PRODUCT LIST PAGE (for "See all" buttons)
// =====================================================
class ProductListPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> products;

  const ProductListPage({
    Key? key,
    required this.title,
    required this.products,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(context, product);
              },
            ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product['id']),
          ),
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
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: _buildProductImage(product),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['itemTitle'] ?? 'Product Title',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getFormattedPrice(product['price']),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Spacer(),
                    Text(
                      product['condition'] ?? 'Used',
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    final imageUrls = product['imageUrls'] as List<dynamic>?;
    
    if (imageUrls != null && imageUrls.isNotEmpty) {
      return UniversalImage(
        imageUrl: imageUrls.first.toString(),
        fit: BoxFit.cover,
        width: double.infinity,
        errorWidget: Container(
          color: Colors.grey[200],
          child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
      );
    }
  }

  String _getFormattedPrice(dynamic price) {
    if (price == null) return 'Price not set';
    
    try {
      final priceValue = price is num ? price.toDouble() : double.parse(price.toString());
      return 'PKR ${priceValue.toStringAsFixed(0)}';
    } catch (e) {
      return 'Price not set';
    }
  }
}