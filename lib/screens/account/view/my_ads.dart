// screens/my_ads_page.dart - Complete Implementation
import 'package:arabicmarketplace/screens/account/controller/my_ads_provider.dart';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:arabicmarketplace/screens/sell_items/view/item_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
class MyAdsPage extends StatefulWidget {
  const MyAdsPage({Key? key}) : super(key: key);

  @override
  State<MyAdsPage> createState() => _MyAdsPageState();
}

class _MyAdsPageState extends State<MyAdsPage> with TickerProviderStateMixin {
  late MyAdsProvider _adsProvider;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _adsProvider = MyAdsProvider();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _adsProvider.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _adsProvider,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'My Ads',
            style: GoogleFonts.jost(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: false,
          actions: [
            Consumer<MyAdsProvider>(
              builder: (context, provider, child) {
                return Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.search, color: Colors.black),
                      onPressed: () => _showSearchDialog(provider),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.black),
                      onPressed: provider.isLoading ? null : () => provider.refreshAds(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer<MyAdsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading your ads...',
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      provider.error!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refreshAds(),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (provider.allAds.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                // Stats Section
                _buildStatsSection(provider),
                
                // Tab Bar
                _buildTabBar(provider),
                
                // Content
                Expanded(
                  child: _buildAdsList(provider),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsPage()));
          },
          backgroundColor: Colors.green[700],
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bicycle
                Positioned(
                  child: Icon(
                    Icons.directions_bike,
                    size: 120,
                    color: Colors.black87,
                  ),
                ),
                // Orange house
                Positioned(
                  top: 20,
                  left: 40,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // Blue squares
                Positioned(
                  top: 30,
                  right: 20,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  right: 10,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Red circle
                Positioned(
                  bottom: 20,
                  left: 30,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Main text
          Text(
            'you haven\'t listed anything yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            'let go of what you don\'t use anymore',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          // Add Product Button
          ElevatedButton.icon(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsPage()));
            },
            icon: Icon(Icons.add),
            label: Text('List Your First Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(MyAdsProvider provider) {
    final stats = provider.getAdStats();
    
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'My Ads Overview',
            style: GoogleFonts.jost(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', stats['total']!, Colors.blue),
              _buildStatItem('Active', stats['active']!, Colors.green),
              _buildStatItem('Sold', stats['sold']!, Colors.orange),
              _buildStatItem('Views', stats['totalViews']!, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(MyAdsProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabButton('All', 0, provider),
          _buildTabButton('Active', 1, provider),
          _buildTabButton('Sold', 2, provider),
          _buildTabButton('Inactive', 3, provider),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, MyAdsProvider provider) {
    final isSelected = provider.selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.changeTab(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.green[700]! : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.jost(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdsList(MyAdsProvider provider) {
    final ads = provider.currentAds;
    
    if (ads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No ads in this category',
              style: GoogleFonts.jost(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshAds(),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: ads.length,
        itemBuilder: (context, index) {
          final ad = ads[index];
          return _buildAdCard(ad, provider);
        },
      ),
    );
  }

  Widget _buildAdCard(ProductModel ad, MyAdsProvider provider) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: ad.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Product Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ad.imageUrls.isNotEmpty
                          ? Image.network(
                              ad.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.image, color: Colors.grey[400]);
                              },
                            )
                          : Icon(Icons.image, color: Colors.grey[400]),
                    ),
                  ),
                  SizedBox(width: 12),
                  
                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad.title,
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          ad.getFormattedPrice(),
                          style: GoogleFonts.jost(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusChip(ad.status),
                            if (ad.isPromoted) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.amber),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 10, color: Colors.amber),
                                    SizedBox(width: 2),
                                    Text(
                                      'PROMOTED',
                                      style: GoogleFonts.jost(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              ad.viewCount.toString(),
                              style: GoogleFonts.jost(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.favorite, size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              ad.favoriteCount.toString(),
                              style: GoogleFonts.jost(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Spacer(),
                            Text(
                              ad.getTimeSincePosted(),
                              style: GoogleFonts.jost(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions Menu
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    onSelected: (value) => _handleAdAction(value, ad, provider),
                    itemBuilder: (context) => [
                      if (ad.status == 'active') ...[
                        PopupMenuItem(
                          value: 'sold', 
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 18, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Mark as Sold'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'inactive', 
                          child: Row(
                            children: [
                              Icon(Icons.pause_circle, size: 18, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Mark as Inactive'),
                            ],
                          ),
                        ),
                      ],
                      if (ad.status == 'sold') ...[
                        PopupMenuItem(
                          value: 'active', 
                          child: Row(
                            children: [
                              Icon(Icons.play_circle, size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Mark as Active'),
                            ],
                          ),
                        ),
                      ],
                      if (ad.status == 'inactive') ...[
                        PopupMenuItem(
                          value: 'active', 
                          child: Row(
                            children: [
                              Icon(Icons.play_circle, size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Mark as Active'),
                            ],
                          ),
                        ),
                      ],
                      PopupMenuItem(
                        value: 'promote', 
                        child: Row(
                          children: [
                            Icon(
                              ad.isPromoted ? Icons.star : Icons.star_border,
                              size: 18,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 8),
                            Text(ad.isPromoted ? 'Remove Promotion' : 'Promote Ad'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit', 
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit Ad'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Ad', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Quick Action Buttons
              if (ad.status == 'active') ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPromoteDialog(ad, provider),
                        icon: Icon(
                          ad.isPromoted ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        ),
                        label: Text(
                          ad.isPromoted ? 'Promoted' : 'Promote',
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            color: Colors.amber[700],
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.amber),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editAd(ad),
                        icon: Icon(Icons.edit, size: 16, color: Colors.blue),
                        label: Text(
                          'Edit',
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blue),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'active':
        color = Colors.green;
        text = 'Active';
        break;
      case 'sold':
        color = Colors.orange;
        text = 'Sold';
        break;
      case 'inactive':
        color = Colors.grey;
        text = 'Inactive';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.jost(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // Enhanced promote dialog
  void _showPromoteDialog(ProductModel ad, MyAdsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text(
              ad.isPromoted ? 'Remove Promotion' : 'Promote Your Ad',
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!ad.isPromoted) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✨ Promotion Benefits:',
                      style: GoogleFonts.jost(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Your ad will appear at the top of search results\n'
                      '• Increased visibility to potential buyers\n'
                      '• Higher chance of quick sale\n'
                      '• Promotion lasts for 30 days',
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Promote "${ad.title}" for better visibility?',
                style: GoogleFonts.jost(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ] else ...[
              Text(
                'Remove promotion for "${ad.title}"?',
                style: GoogleFonts.jost(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your ad will return to normal listing position.',
                style: GoogleFonts.jost(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success;
              if (ad.isPromoted) {
                success = await provider.removePromotion(ad.id);
                _showActionResult(success, 'Promotion removed successfully');
              } else {
                success = await provider.promoteAd(ad.id);
                _showActionResult(success, 'Ad promoted successfully');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ad.isPromoted ? Colors.grey[600] : Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: Text(
              ad.isPromoted ? 'Remove' : 'Promote',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Edit ad functionality
  void _editAd(ProductModel ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text(
              'Edit Options',
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.title, color: Colors.blue),
              title: Text('Edit Title & Description', style: GoogleFonts.jost()),
              subtitle: Text('Update basic information', style: GoogleFonts.jost(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _editBasicInfo(ad);
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_money, color: Colors.green),
              title: Text('Edit Price', style: GoogleFonts.jost()),
              subtitle: Text('Update pricing and negotiation', style: GoogleFonts.jost(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _editPrice(ad);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.orange),
              title: Text('Edit Photos', style: GoogleFonts.jost()),
              subtitle: Text('Add or remove images', style: GoogleFonts.jost(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _editPhotos(ad);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editBasicInfo(ProductModel ad) {
    final titleController = TextEditingController(text: ad.title);
    final descriptionController = TextEditingController(text: ad.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Basic Information',
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: GoogleFonts.jost(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: GoogleFonts.jost(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              style: GoogleFonts.jost(fontSize: 14),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: GoogleFonts.jost(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.jost(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _adsProvider.updateAdBasicInfo(
                ad.id,
                titleController.text,
                descriptionController.text,
              );
              _showActionResult(success, 'Ad information updated successfully');
            },
            child: Text('Save', style: GoogleFonts.jost()),
          ),
        ],
      ),
    );
  }

  void _editPrice(ProductModel ad) {
    final priceController = TextEditingController(text: ad.price.toString());
    bool allowNegotiation = ad.allowPriceNegotiation;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit Price',
            style: GoogleFonts.jost(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                style: GoogleFonts.jost(fontSize: 14),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price',
                  labelStyle: GoogleFonts.jost(fontSize: 14),
                  prefixText: 'Rs ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 16),
              CheckboxListTile(
                title: Text('Allow Price Negotiation', style: GoogleFonts.jost(fontSize: 14)),
                value: allowNegotiation,
                onChanged: (value) => setState(() => allowNegotiation = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.jost(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await _adsProvider.updateAdPrice(
                  ad.id,
                  double.tryParse(priceController.text) ?? ad.price,
                  allowNegotiation,
                );
                _showActionResult(success, 'Price updated successfully');
              },
              child: Text('Save', style: GoogleFonts.jost()),
            ),
          ],
        ),
      ),
    );
  }

  void _editPhotos(ProductModel ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Photos',
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Photo editing functionality will open the full edit screen where you can add, remove, or reorder photos.',
          style: GoogleFonts.jost(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.jost(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to a full photo editing screen
              // You can create a dedicated photo editing page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Photo editing feature coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: Text('Edit Photos', style: GoogleFonts.jost()),
          ),
        ],
      ),
    );
  }

  void _handleAdAction(String action, ProductModel ad, MyAdsProvider provider) async {
    switch (action) {
      case 'sold':
        final success = await provider.markAsSold(ad.id);
        _showActionResult(success, 'Ad marked as sold');
        break;
      case 'active':
        final success = await provider.markAsActive(ad.id);
        _showActionResult(success, 'Ad marked as active');
        break;
      case 'inactive':
        final success = await provider.markAsInactive(ad.id);
        _showActionResult(success, 'Ad marked as inactive');
        break;
      case 'promote':
        _showPromoteDialog(ad, provider);
        break;
      case 'edit':
        _editAd(ad);
        break;
      case 'delete':
        _showDeleteConfirmation(ad, provider);
        break;
    }
  }

  void _showActionResult(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(success ? message : 'Action failed'),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showDeleteConfirmation(ProductModel ad, MyAdsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              'Delete Ad',
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${ad.title}"?',
              style: GoogleFonts.jost(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All associated data will be permanently removed.',
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteAd(ad.id);
              _showActionResult(success, 'Ad deleted successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(MyAdsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Search My Ads',
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: TextField(
          controller: _searchController,
          style: GoogleFonts.jost(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter search terms...',
            hintStyle: GoogleFonts.jost(fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final results = provider.searchAds(_searchController.text);
              _showSearchResults(results);
            },
            child: Text(
              'Search',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(List<ProductModel> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Search Results (${results.length})',
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No ads found',
                        style: GoogleFonts.jost(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final ad = results[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: ad.imageUrls.isNotEmpty
                              ? Image.network(
                                  ad.imageUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.image, size: 20, color: Colors.grey[400]);
                                  },
                                )
                              : Icon(Icons.image, size: 20, color: Colors.grey[400]),
                        ),
                      ),
                      title: Text(
                        ad.title,
                        style: GoogleFonts.jost(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        ad.getFormattedPrice(),
                        style: GoogleFonts.jost(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(productId: ad.id),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}