// screens/my_ads_page.dart - Complete Implementation
import 'package:arabicmarketplace/screens/account/controller/my_ads_provider.dart';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/view/item_details_screen.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
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
       // NEW: Load edit data if in edit mode
       
   
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onBackground),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.myAds.tr(),
            style: GoogleFonts.jost(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          centerTitle: false,
          actions: [
            Consumer<MyAdsProvider>(
              builder: (context, provider, child) {
                return Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onBackground),
                      onPressed: () => _showSearchDialog(provider),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onBackground),
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
                      AppLocalizations.loadingYourAds.tr(),
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                    SizedBox(height: 16),
                    Text(
                      provider.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refreshAds(),
                      child: Text(AppLocalizations.retry.tr()),
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsPage(productToEdit:null,)));
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                      color: Theme.of(context).colorScheme.secondary,
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
                      color: Theme.of(context).colorScheme.primary,
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
                      color: Theme.of(context).colorScheme.primary,
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
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
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
            AppLocalizations.noAdsYet.tr(),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            AppLocalizations.letGoUnused.tr(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 30),
          // Add Product Button
          ElevatedButton.icon(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsPage()));
            },
            icon: Icon(Icons.add),
            label: Text(AppLocalizations.listFirstItem.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
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
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
           AppLocalizations.myAdsOverview.tr(),
            style: GoogleFonts.jost(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(AppLocalizations.total.tr(), stats['total']!, Theme.of(context).colorScheme.primary),
              _buildStatItem(AppLocalizations.active.tr(), stats['active']!, Theme.of(context).colorScheme.primary),
              _buildStatItem(AppLocalizations.sold.tr(), stats['sold']!, Theme.of(context).colorScheme.error),
              _buildStatItem(AppLocalizations.views.tr(), stats['totalViews']!, Theme.of(context).colorScheme.secondary),
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
          _buildTabButton(AppLocalizations.all.tr(), 0, provider),
          _buildTabButton(AppLocalizations.active.tr(), 1, provider),
          _buildTabButton(AppLocalizations.sold.tr(), 2, provider),
          _buildTabButton(AppLocalizations.inactive.tr(), 3, provider),
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
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
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
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
            Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              AppLocalizations.noAdsInCategory.tr(),
              style: GoogleFonts.jost(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
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
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ad.imageUrls.isNotEmpty
                          ? Image.network(
                              ad.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.image, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5));
                              },
                            )
                          : Icon(Icons.image, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
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
                            color: Theme.of(context).colorScheme.onBackground,
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
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusChip(ad.status),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.visibility, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                            SizedBox(width: 4),
                            Text(
                              ad.viewCount.toString(),
                              style: GoogleFonts.jost(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.favorite, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                            SizedBox(width: 4),
                            Text(
                              ad.favoriteCount.toString(),
                              style: GoogleFonts.jost(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            Spacer(),
                            Text(
                              ad.getTimeSincePosted(),
                              style: GoogleFonts.jost(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions Menu
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    color: Theme.of(context).colorScheme.surface,
                    onSelected: (value) => _handleAdAction(value, ad, provider),
                    itemBuilder: (context) => [
                      if (ad.status == 'active') ...[
                        PopupMenuItem(
                          value: 'sold', 
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 18, color: Theme.of(context).colorScheme.error),
                              SizedBox(width: 8),
                              Text(AppLocalizations.markAsSold.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'inactive', 
                          child: Row(
                            children: [
                              Icon(Icons.pause_circle, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                              SizedBox(width: 8),
                              Text(AppLocalizations.markAsInactive.tr()),
                            ],
                          ),
                        ),
                      ],
                      if (ad.status == 'sold') ...[
                        PopupMenuItem(
                          value: 'active', 
                          child: Row(
                            children: [
                              Icon(Icons.play_circle, size: 18, color: Theme.of(context).colorScheme.primary),
                              SizedBox(width: 8),
                              Text(AppLocalizations.markAsActive.tr()),
                            ],
                          ),
                        ),
                      ],
                      if (ad.status == 'inactive') ...[
                        PopupMenuItem(
                          value: 'active', 
                          child: Row(
                            children: [
                              Icon(Icons.play_circle, size: 18, color: Theme.of(context).colorScheme.primary),
                              SizedBox(width: 8),
                              Text(AppLocalizations.markAsActive.tr()),
                            ],
                          ),
                        ),
                      ],

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
                            Icon(Icons.delete, size: 18, color: Theme.of(context).colorScheme.error),
                            SizedBox(width: 8),
                            Text(AppLocalizations.deleteAd.tr(), style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                        onPressed: () => _editAd(ad),
                        icon: Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.primary),
                        label: Text(
                          AppLocalizations.edit.tr(),
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
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
        color = Theme.of(context).colorScheme.primary;
        text = AppLocalizations.active.tr();
        break;
      case 'sold':
        color = Theme.of(context).colorScheme.error;
        text = AppLocalizations.sold.tr();
        break;
      case 'inactive':
        color = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
        text = AppLocalizations.inactive.tr();
        break;
      default:
        color = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
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



  // Edit ad functionality
  // ENHANCED: Edit ad functionality - Navigate to ItemDetailsPage
void _editAd(ProductModel ad) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider(
        create: (context) => ItemProvider(),
        child: ItemDetailsPage(
          productToEdit: ad, // Pass the product to edit
        ),
      ),
    ),
  ).then((result) {
    // If edit was successful, refresh the ads list
    if (result == true) {
      _adsProvider.refreshAds();
    }
  });
}


  void _editBasicInfo(ProductModel ad) {
    final titleController = TextEditingController(text: ad.title);
    final descriptionController = TextEditingController(text: ad.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.editBasicInfo.tr(),
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: GoogleFonts.jost(fontSize: 14),
              decoration: InputDecoration(
                labelText:AppLocalizations.itemTitle.tr(),
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
                labelText:AppLocalizations.description.tr(),
                labelStyle: GoogleFonts.jost(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.cancel.tr(), style: GoogleFonts.jost(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _adsProvider.updateAdBasicInfo(
                ad.id,
                titleController.text,
                descriptionController.text,
              );
              _showActionResult(success, AppLocalizations.adInfoUpdatedSuccessfully.tr());
            },
            child: Text(AppLocalizations.save.tr()),
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
            AppLocalizations.editItem.tr(), // Fallback to 'editItem' if 'editPrice' does not exist
            style: GoogleFonts.jost(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
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
                  labelText: AppLocalizations.price.tr(),
                  labelStyle: GoogleFonts.jost(fontSize: 14),
                  prefixText: 'Rs ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 16),
              CheckboxListTile(
                title: Text(AppLocalizations.allowPriceNegotiation.tr(), style: GoogleFonts.jost(fontSize: 14)),
                value: allowNegotiation,
                onChanged: (value) => setState(() => allowNegotiation = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.cancel.tr(), style: GoogleFonts.jost(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await _adsProvider.updateAdPrice(
                  ad.id,
                  double.tryParse(priceController.text) ?? ad.price,
                  allowNegotiation,
                );
                _showActionResult(success, AppLocalizations.priceUpdatedSuccessfully.tr());
              },
              child: Text(AppLocalizations.save.tr()),
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
          AppLocalizations.photos.tr(), // Fallback to 'photos' if 'editPhotos' does not exist
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        content: Text(
          AppLocalizations.photoEditingFeatureComingSoon.tr(),
          style: GoogleFonts.jost(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.cancel.tr(), style: GoogleFonts.jost(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to a full photo editing screen
              // You can create a dedicated photo editing page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.photoEditingFeatureComingSoon.tr()),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
            child: Text(AppLocalizations.photos.tr()),
          ),
        ],
      ),
    );
  }

  void _handleAdAction(String action, ProductModel ad, MyAdsProvider provider) async {
    switch (action) {
      case 'sold':
        final success = await provider.markAsSold(ad.id);
        _showActionResult(success, AppLocalizations.adMarkedSold.tr());
        break;
      case 'active':
        final success = await provider.markAsActive(ad.id);
        _showActionResult(success, AppLocalizations.adMarkedActive.tr());
        break;
      case 'inactive':
        final success = await provider.markAsInactive(ad.id);
        _showActionResult(success, AppLocalizations.adMarkedInactive.tr());
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
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(success ? message : AppLocalizations.actionFailed.tr()),
          ],
        ),
        backgroundColor: success ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
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
            Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 24),
            SizedBox(width: 8),
            Text(
              AppLocalizations.deleteAd.tr(),
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.areYouSureDelete.tr(), // Use generic confirmation
              style: GoogleFonts.jost(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).colorScheme.error, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.thisActionCannotBeUndone.tr(),
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
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
              AppLocalizations.cancel.tr(),
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteAd(ad.id);
              _showActionResult(success, AppLocalizations.adDeletedSuccessfully.tr());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(
              AppLocalizations.delete.tr(),
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
          AppLocalizations.searchMyAds.tr(),
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        content: TextField(
          controller: _searchController,
          style: GoogleFonts.jost(fontSize: 14),
          decoration: InputDecoration(
            hintText: AppLocalizations.enterSearchTerms.tr(),
            hintStyle: GoogleFonts.jost(fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.cancel.tr(),
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
              AppLocalizations.search.tr(),
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
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
          '${AppLocalizations.searchResults.tr()} (${results.length})',
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
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
                      Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      SizedBox(height: 16),
                      Text(
                        AppLocalizations.noAdsFound.tr(),
                        style: GoogleFonts.jost(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: ad.imageUrls.isNotEmpty
                              ? Image.network(
                                  ad.imageUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.image, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5));
                                  },
                                )
                              : Icon(Icons.image, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
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
                          color: Theme.of(context).colorScheme.primary,
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
              AppLocalizations.close.tr(),
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}