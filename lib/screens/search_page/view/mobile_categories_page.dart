import 'package:arabicmarketplace/screens/home/view/iphones_page.dart';
import 'package:arabicmarketplace/screens/search_page/controller/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MobilesCategoryPage extends StatefulWidget {
  const MobilesCategoryPage({Key? key}) : super(key: key);

  @override
  State<MobilesCategoryPage> createState() => _MobilesCategoryPageState();
}

class _MobilesCategoryPageState extends State<MobilesCategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> filteredMobileModels = [];
  
  final List<String> iPhoneModels = const [
    'See all in mobile phones',
    'Iphones',
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

  void _navigateToSubcategory(String model) {
    if (model == 'See all in mobile phones') {
      // Use SearchProvider to search all mobile phones
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);
      searchProvider.searchByCategory('Mobiles');
      Navigator.pop(context); // Go back to search page with results
    } else if (model.toLowerCase().contains('iphone')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => IphonesPage()),
      );
    } else {
      // Navigate to brand-specific search
      _searchByBrand(model);
    }
  }

  void _searchByBrand(String brand) {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    
    // Create a search query for the specific brand in mobile category
    final filters = SearchFilters(
      selectedCategory: 'Mobiles',
    );
    
    searchProvider.updateFilters(filters);
    searchProvider.performImmediateSearch(brand);
    Navigator.pop(context); // Go back to search page with results
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
                            onTap: () => _navigateToSubcategory(model),
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
                                  // Add a small indicator for available products
                                  FutureBuilder<int>(
                                    future: _getProductCount(model),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData && snapshot.data! > 0) {
                                        return Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D5E2A).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${snapshot.data}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: const Color(0xFF0D5E2A),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D5E2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Clear Search',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Backend function to get product count for each category/brand
  Future<int> _getProductCount(String model) async {
    try {
      if (model == 'See all in mobile phones') {
        // Count all mobile phones
        final snapshot = await FirebaseFirestore.instance
            .collection('items')
            .where('status', isEqualTo: 'active')
            .where('category', isEqualTo: 'Mobiles')
            .get();
        return snapshot.docs.length;
      } else {
        // Count products for specific brand
        final snapshot = await FirebaseFirestore.instance
            .collection('items')
            .where('status', isEqualTo: 'active')
            .where('category', isEqualTo: 'Mobiles')
            .get();

        // Filter by brand/model name in the title or brand field
        int count = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['itemTitle'] ?? '').toString().toLowerCase();
          final brand = (data['brand'] ?? '').toString().toLowerCase();
          final modelLower = model.toLowerCase();
          
          if (title.contains(modelLower) || brand.contains(modelLower)) {
            count++;
          }
        }
        return count;
      }
    } catch (e) {
      print('Error getting product count: $e');
      return 0;
    }
  }
}

// // Enhanced Search Filters class (if not already defined)
// class SearchFilters {
//   final String? selectedCategory;
//   final double? minPrice;
//   final double? maxPrice;
//   final double? minRadius;
//   final double? maxRadius;
//   final String? adType;
//   final double? latitude;
//   final double? longitude;
//   final double? radiusKm;
//   final String? location;

//   const SearchFilters({
//     this.selectedCategory,
//     this.minPrice,
//     this.maxPrice,
//     this.minRadius,
//     this.maxRadius,
//     this.adType,
//     this.latitude,
//     this.longitude,
//     this.radiusKm,
//     this.location,
//   });

//   bool get hasActiveFilters {
//     return selectedCategory != null ||
//            minPrice != null ||
//            maxPrice != null ||
//            minRadius != null ||
//            maxRadius != null ||
//            (adType != null && adType != 'All') ||
//            latitude != null;
//   }

//   SearchFilters copyWith({
//     String? selectedCategory,
//     double? minPrice,
//     double? maxPrice,
//     double? minRadius,
//     double? maxRadius,
//     String? adType,
//     double? latitude,
//     double? longitude,
//     double? radiusKm,
//     String? location,
//   }) {
//     return SearchFilters(
//       selectedCategory: selectedCategory ?? this.selectedCategory,
//       minPrice: minPrice ?? this.minPrice,
//       maxPrice: maxPrice ?? this.maxPrice,
//       minRadius: minRadius ?? this.minRadius,
//       maxRadius: maxRadius ?? this.maxRadius,
//       adType: adType ?? this.adType,
//       latitude: latitude ?? this.latitude,
//       longitude: longitude ?? this.longitude,
//       radiusKm: radiusKm ?? this.radiusKm,
//       location: location ?? this.location,
//     );
//   }
// }