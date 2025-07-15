
// import 'package:arabicmarketplace/screens/search_page/controller/search_provider.dart';
// import 'package:arabicmarketplace/screens/search_page/view/mobile_categories_page.dart';
// import 'package:arabicmarketplace/screens/search_page/view/search_page_filter.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// // Categories Page for Filter Selection
// class CategoriesPageForFilter extends StatefulWidget {
//   final Function(String) onCategorySelected;
//   final String selectedCategory;
  
//   const CategoriesPageForFilter({
//     Key? key, 
//     required this.onCategorySelected,
//     required this.selectedCategory,
//   }) : super(key: key);

//   @override
//   State<CategoriesPageForFilter> createState() => _CategoriesPageForFilterState();
// }

// class _CategoriesPageForFilterState extends State<CategoriesPageForFilter> {
//   final TextEditingController _searchController = TextEditingController();
//   List<CategoryItem> filteredCategories = [];
//   bool isLoading = true;
  
//   // Your original categories with my backend integration
//   final List<CategoryItem> categories = [
//     // Add "Any" option at the top
//     CategoryItem(
//       icon: Icons.apps,
//       iconColor: const Color(0xFF0D5E2A),
//       backgroundColor: Colors.grey[100]!,
//       title: 'Any',
//       isPopular: true,
//       searchKeywords: ['any', 'all'],
//     ),
    
//     // Popular Categories (your original design)
//     CategoryItem(
//       icon: Icons.phone_android,
//       iconColor: Colors.blue,
//       backgroundColor: Colors.grey[800]!,
//       title: 'Mobiles',
//       isPopular: true,
//       searchKeywords: ['mobile', 'phone', 'smartphone', 'iphone', 'samsung'],
//     ),
//     CategoryItem(
//       icon: Icons.computer,
//       iconColor: Colors.grey[300]!,
//       backgroundColor: Colors.grey[800]!,
//       title: 'Computers',
//       isPopular: true,
//       searchKeywords: ['computer', 'laptop', 'pc', 'desktop', 'macbook'],
//     ),
//     CategoryItem(
//       icon: Icons.headphones,
//       iconColor: Colors.purple,
//       backgroundColor: Colors.grey[100]!,
//       title: 'Computer Accessories',
//       isPopular: true,
//       searchKeywords: ['accessories', 'keyboard', 'mouse', 'headphones', 'cable'],
//     ),
//     CategoryItem(
//       icon: Icons.home,
//       iconColor: Colors.red,
//       backgroundColor: Colors.grey[100]!,
//       title: 'Property for Sale',
//       isPopular: true,
//       searchKeywords: ['property', 'house', 'apartment', 'land', 'villa'],
//     ),
//     CategoryItem(
//       icon: Icons.directions_car,
//       iconColor: Colors.grey[400]!,
//       backgroundColor: Colors.grey[800]!,
//       title: 'Vehicles',
//       isPopular: true,
//       searchKeywords: ['car', 'vehicle', 'bike', 'motorcycle', 'truck'],
//     ),
    
//     // Other Categories (your original design)
//     CategoryItem(
//       icon: Icons.pedal_bike,
//       iconColor: Colors.blue,
//       backgroundColor: Colors.grey[600]!,
//       title: 'Bikes',
//       isPopular: false,
//       searchKeywords: ['bike', 'bicycle', 'motorcycle', 'scooter'],
//     ),
//     CategoryItem(
//       icon: Icons.kitchen,
//       iconColor: Colors.grey[300]!,
//       backgroundColor: Colors.grey[700]!,
//       title: 'Home Appliances',
//       isPopular: false,
//       searchKeywords: ['appliance', 'fridge', 'washing', 'microwave', 'ac'],
//     ),
//     CategoryItem(
//       icon: Icons.build,
//       iconColor: Colors.orange,
//       backgroundColor: Colors.red,
//       title: 'Services',
//       isPopular: false,
//       searchKeywords: ['service', 'repair', 'cleaning', 'maintenance'],
//     ),
//     CategoryItem(
//       icon: Icons.pets,
//       iconColor: Colors.brown,
//       backgroundColor: Colors.orange[100]!,
//       title: 'Animals',
//       isPopular: false,
//       searchKeywords: ['animal', 'pet', 'cat', 'dog', 'bird'],
//     ),
//     CategoryItem(
//       icon: Icons.work,
//       iconColor: Colors.grey[600]!,
//       backgroundColor: Colors.grey[200]!,
//       title: 'Jobs',
//       isPopular: false,
//       searchKeywords: ['job', 'work', 'employment', 'career'],
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _initializeCategories();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _initializeCategories() async {
//     setState(() {
//       isLoading = true;
//     });

//     // Load product counts for each category (except "Any")
//     for (var category in categories) {
//       if (category.title != 'Any') {
//         category.productCount = await _getProductCountForCategory(category.title);
//       }
//     }

//     setState(() {
//       filteredCategories = List.from(categories);
//       isLoading = false;
//     });
//   }

//   void _onSearchChanged(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         filteredCategories = List.from(categories);
//       } else {
//         filteredCategories = categories.where((category) {
//           final titleMatch = category.title.toLowerCase().contains(query.toLowerCase());
//           final keywordMatch = category.searchKeywords.any(
//             (keyword) => keyword.toLowerCase().contains(query.toLowerCase())
//           );
//           return titleMatch || keywordMatch;
//         }).toList();
//       }
//     });
//   }

//   Future<int> _getProductCountForCategory(String categoryName) async {
//     try {
//       String firestoreCategory = _mapCategoryName(categoryName);
      
//       final snapshot = await FirebaseFirestore.instance
//           .collection('items')
//           .where('status', isEqualTo: 'active')
//           .where('category', isEqualTo: firestoreCategory)
//           .get();
      
//       return snapshot.docs.length;
//     } catch (e) {
//       print('Error getting product count for $categoryName: $e');
//       return 0;
//     }
//   }

//   String _mapCategoryName(String displayName) {
//     switch (displayName) {
//       case 'Mobiles':
//         return 'Mobiles';
//       case 'Computers':
//         return 'Computers';
//       case 'Computer Accessories':
//         return 'Computer Accessories';
//       case 'Property for Sale':
//         return 'Property for Sale';
//       case 'Vehicles':
//         return 'Vehicles';
//       case 'Bikes':
//         return 'Bikes';
//       case 'Home Appliances':
//         return 'Home Appliances';
//       case 'Services':
//         return 'Services';
//       case 'Animals':
//         return 'Animals';
//       case 'Jobs':
//         return 'Jobs';
//       default:
//         return displayName;
//     }
//   }

//   void _navigateToCategory(CategoryItem category) {
//     if (category.title == 'Mobiles') {
//       // Navigate to MobilesCategoryPage for subcategory selection
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => MobilesCategoryPageForFilter(
//             onCategorySelected: widget.onCategorySelected,
//           ),
//         ),
//       );
//     } else {
//       // For other categories, select directly
//       widget.onCategorySelected(category.title);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         surfaceTintColor: Colors.white,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(
//             Icons.arrow_back_ios,
//             color: Colors.black,
//             size: 20,
//           ),
//         ),
//         title: Text(
//           'Select Category',
//           style: GoogleFonts.poppins(
//             fontSize: 18,
//             fontWeight: FontWeight.w500,
//             color: Colors.black,
//           ),
//         ),
//         centerTitle: false,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Search Field (keeping your original design)
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey[300]!),
//               ),
//               child: TextField(
//                 controller: _searchController,
//                 onChanged: _onSearchChanged,
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                 ),
//                 decoration: InputDecoration(
//                   hintText: 'Search by Categories',
//                   hintStyle: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                   prefixIcon: Icon(
//                     Icons.search,
//                     color: Colors.grey[600],
//                     size: 20,
//                   ),
//                   suffixIcon: _searchController.text.isNotEmpty
//                       ? IconButton(
//                           icon: Icon(Icons.clear, color: Colors.grey[600]),
//                           onPressed: () {
//                             _searchController.clear();
//                             _onSearchChanged('');
//                           },
//                         )
//                       : null,
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                 ),
//               ),
//             ),
            
//             const SizedBox(height: 24),
            
//             if (isLoading)
//               const Expanded(
//                 child: Center(
//                   child: CircularProgressIndicator(
//                     color: Color(0xFF0D5E2A),
//                   ),
//                 ),
//               )
//             else if (filteredCategories.isEmpty)
//               _buildNoResults()
//             else
//               Expanded(
//                 child: ListView(
//                   children: [
//                     // Popular Section (keeping your original design)
//                     if (filteredCategories.any((cat) => cat.isPopular)) ...[
//                       Text(
//                         'Popular',
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       ...filteredCategories
//                           .where((cat) => cat.isPopular)
//                           .map((category) => _buildCategoryItem(category)),
//                       const SizedBox(height: 24),
//                     ],
                    
//                     // Others Section (keeping your original design)
//                     if (filteredCategories.any((cat) => !cat.isPopular)) ...[
//                       Text(
//                         'Others',
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       ...filteredCategories
//                           .where((cat) => !cat.isPopular)
//                           .map((category) => _buildCategoryItem(category)),
//                     ],
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildCategoryItem(CategoryItem category) {
//     final isSelected = category.title == widget.selectedCategory;
    
//     return Container(
//       margin: const EdgeInsets.only(bottom: 0),
//       child: InkWell(
//         onTap: () => _navigateToCategory(category),
//         borderRadius: BorderRadius.circular(8),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
//           child: Row(
//             children: [
//               // Category Icon (keeping your original design)
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   color: category.backgroundColor,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   category.icon,
//                   color: category.iconColor,
//                   size: 20,
//                 ),
//               ),
              
//               const SizedBox(width: 16),
              
//               // Category Title (keeping your original design)
//               Expanded(
//                 child: Text(
//                   category.title,
//                   style: GoogleFonts.poppins(
//                     fontSize: 15,
//                     fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
//                     color: isSelected ? const Color(0xFF0D5E2A) : Colors.black,
//                   ),
//                 ),
//               ),
              
//               // Product Count Badge (new backend feature)
//               if (category.productCount > 0)
//                 Container(
//                   margin: const EdgeInsets.only(right: 8),
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF0D5E2A).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     '${category.productCount}',
//                     style: GoogleFonts.poppins(
//                       fontSize: 11,
//                       color: const Color(0xFF0D5E2A),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
              
//               // Selection indicator and Arrow Icon
//               if (isSelected)
//                 const Icon(Icons.check, color: Color(0xFF0D5E2A), size: 20)
//               else
//                 const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNoResults() {
//     return Expanded(
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.search_off,
//               size: 64,
//               color: Colors.grey[400],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'No categories found',
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Try searching with different keywords',
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.grey[500],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }