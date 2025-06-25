import 'dart:io';
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/view/success_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ReviewPublishPage extends StatelessWidget {
  const ReviewPublishPage({Key? key}) : super(key: key);

  void _showLocationDialog(BuildContext context, ItemProvider itemProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Choose Location',
            style: GoogleFonts.jost(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.my_location, color: Colors.blue),
                title: Text(
                  'Use Current Location',
                  style: GoogleFonts.jost(fontSize: 16),
                ),
                subtitle: Text(
                  'Get your current GPS location',
                  style: GoogleFonts.jost(fontSize: 12, color: Colors.grey),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await itemProvider.fetchUserLocation(context);
                  if (!success && itemProvider.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(itemProvider.error!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_location, color: Colors.orange),
                title: Text(
                  'Enter Custom Address',
                  style: GoogleFonts.jost(fontSize: 16),
                ),
                subtitle: Text(
                  'Manually enter your location',
                  style: GoogleFonts.jost(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCustomLocationDialog(context, itemProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomLocationDialog(BuildContext context, ItemProvider itemProvider) {
    final TextEditingController addressController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Enter Location',
            style: GoogleFonts.jost(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: addressController,
            decoration: InputDecoration(
              hintText: 'Enter your address',
              hintStyle: GoogleFonts.jost(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.jost(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (addressController.text.trim().isNotEmpty) {
                  // Set custom location with default coordinates
                  itemProvider.updateLocation(
                    latitude: 0.0, // You can integrate with geocoding service
                    longitude: 0.0,
                    locationAddress: addressController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Custom location set!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsController.primaryColor,
              ),
              child: Text(
                'Set Location',
                style: GoogleFonts.jost(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ItemProvider, UserProvider>(
      builder: (context, itemProvider, userProvider, child) {
        final user = userProvider.currentUser;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            surfaceTintColor: Colors.white,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Review & Publish',
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            actions: [
              SvgPicture.asset("assets/icons/Notification.svg", height: 27, width: 27),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review & Publish Your Listing',
                  style: GoogleFonts.jost(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s a preview of how your listing will appear to potential buyers.',
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Error display
                if (itemProvider.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            itemProvider.error!,
                            style: GoogleFonts.jost(
                              fontSize: 14,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 350,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: itemProvider.images.isNotEmpty
                                    ? DecorationImage(
                                        image: FileImage(File(itemProvider.images[0].path)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: itemProvider.images.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No Image',
                                        style: GoogleFonts.jost(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            if (itemProvider.images.length > 1)
                              Positioned(
                                bottom: 16,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    itemProvider.images.length,
                                    (index) => Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: index == 0 ? Colors.black : Colors.grey[400],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                itemProvider.condition?.isNotEmpty == true
                                    ? itemProvider.condition!
                                    : 'Unknown',
                                style: GoogleFonts.jost(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.favorite_border,
                              color: Colors.red,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            itemProvider.brand?.isNotEmpty == true
                                ? itemProvider.brand!
                                : 'No Brand',
                            style: GoogleFonts.jost(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            itemProvider.itemTitle?.isNotEmpty == true
                                ? itemProvider.itemTitle!
                                : 'Untitled',
                            style: GoogleFonts.jost(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              itemProvider.price != null && itemProvider.price! > 0
                                  ? '${itemProvider.price!.toStringAsFixed(2)}'
                                  : 'Free',
                              style: GoogleFonts.jost(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                            if (itemProvider.allowPriceNegotiation)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Negotiable',
                                  style: GoogleFonts.jost(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          itemProvider.description?.isNotEmpty == true
                              ? itemProvider.description!
                              : 'No description provided',
                          style: GoogleFonts.jost(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: user?.profileImage != null
                                  ? ClipOval(
                                      child: Image.network(
                                        user!.profileImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.type == 'company' 
                                      ? (user?.companyName ?? 'Anonymous Company')
                                      : 'Individual Seller',
                                  style: GoogleFonts.jost(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'Contact seller',
                              style: GoogleFonts.jost(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Colors.black,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Location',
                              style: GoogleFonts.jost(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showLocationDialog(context, itemProvider),
                              icon: const Icon(Icons.edit_location, size: 16),
                              label: Text(
                                'Change',
                                style: GoogleFonts.jost(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: itemProvider.locationAddress != null 
                                ? Colors.grey[100] 
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: itemProvider.locationAddress != null 
                                  ? Colors.grey[300]! 
                                  : Colors.red[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                itemProvider.locationAddress != null 
                                    ? Icons.location_on 
                                    : Icons.location_off,
                                color: itemProvider.locationAddress != null 
                                    ? Colors.grey[600] 
                                    : Colors.red[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  itemProvider.locationAddress?.isNotEmpty == true
                                      ? itemProvider.locationAddress!
                                      : 'Location not set - Click "Change" to set location',
                                  style: GoogleFonts.jost(
                                    fontSize: 14,
                                    color: itemProvider.locationAddress != null 
                                        ? Colors.black 
                                        : Colors.red[600],
                                    fontWeight: itemProvider.locationAddress != null 
                                        ? FontWeight.normal 
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Back',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: itemProvider.isPublishing ? null : () async {
                          try {
                            final success = await itemProvider.publishItem(context);
                            if (success) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => SuccessPage()),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorsController.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: itemProvider.isPublishing 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Publish',
                                style: GoogleFonts.jost(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}