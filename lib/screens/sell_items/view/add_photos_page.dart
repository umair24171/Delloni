import 'dart:io';
import 'package:arabicmarketplace/main.dart';
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/view/review_publish.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart'; // ADDED: For temp directory

class EnhancedAddPhotosPage extends StatefulWidget {
  const EnhancedAddPhotosPage({super.key});

  @override
  State<EnhancedAddPhotosPage> createState() => _EnhancedAddPhotosPageState();
}

class _EnhancedAddPhotosPageState extends State<EnhancedAddPhotosPage> {
  bool _isProcessingImage = false;
  bool _isDialogShowing = false;
  int _maxImages = 10; // Default max images
  
  // Store the context for safe usage
  BuildContext? _contextRef;
  
  // Categories that allow unlimited photos
  final Set<String> _unlimitedCategories = {
    'house',
    'houses',
    'real estate',
    'property',
    'apartment',
    'villa',
    'land',
    'commercial',
    'residential',
    'warehouse',
    'office',
    'shop',
    'building',
    'vehicle',
    'vehicles',
    'car',
    'cars',
    'motorcycle',
    'motorcycles',
    'truck',
    'trucks',
    'bus',
    'buses',
    'boat',
    'boats',
    'yacht',
    'yachts',
    'aircraft',
    'airplanes',
    'helicopter',
    'helicopters',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determineMaxImages();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contextRef = context; // Store context reference
  }

  // Determine max images based on category
  void _determineMaxImages() {
    if (!mounted) return;
    
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final category = itemProvider.categoryName?.toLowerCase() ?? '';
    
    // Check if category allows unlimited photos
    bool isUnlimited = _unlimitedCategories.any((cat) => category.contains(cat));
    
    if (mounted) {
      setState(() {
        _maxImages = isUnlimited ? 50 : 10; // 50 for unlimited categories, 10 for others
      });
    }
  }

  // Get category-specific photo requirements
  Map<String, dynamic> _getCategoryPhotoRequirements() {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final category = itemProvider.categoryName?.toLowerCase() ?? '';
    
    if (_unlimitedCategories.any((cat) => category.contains(cat))) {
      // Check if it's a vehicle category
      final vehicleKeywords = ['vehicle', 'vehicles', 'car', 'cars', 'motorcycle', 'motorcycles', 'truck', 'trucks', 'bus', 'buses', 'boat', 'boats', 'yacht', 'yachts', 'aircraft', 'airplanes', 'helicopter', 'helicopters'];
      final isVehicle = vehicleKeywords.any((keyword) => category.contains(keyword));
      
      if (isVehicle) {
        return {
          'min': 5, // Vehicles need minimum 5 photos
          'max': 50,
          'recommended': 15,
          'type': AppLocalizations.vehicle.tr(),
          'suggestions': [
            AppLocalizations.frontView.tr(),
            AppLocalizations.sideView.tr(),
            AppLocalizations.rearView.tr(),
            AppLocalizations.interiorDashboard.tr(),
            AppLocalizations.engineBay.tr(),
            AppLocalizations.wheelsTires.tr(),
            AppLocalizations.interiorSeats.tr(),
            AppLocalizations.trunkCargoArea.tr(),
          ],
        };
      } else {
        return {
          'min': 5, // Real estate needs minimum 5 photos
          'max': 50,
          'recommended': 15,
          'type': AppLocalizations.realEstate.tr(),
          'suggestions': [
            AppLocalizations.exteriorFrontView.tr(),
            AppLocalizations.interiorRooms.tr(),
            AppLocalizations.kitchen.tr(),
            AppLocalizations.bathroom.tr(),
            AppLocalizations.bedrooms.tr(),
            AppLocalizations.livingAreas.tr(),
            AppLocalizations.gardenYard.tr(),
            AppLocalizations.nearbyAmenities.tr(),
          ],
        };
      }
    }
    
    return {
      'min': 2,
      'max': 10,
      'recommended': 5,
      'type': AppLocalizations.generalItem.tr(),
      'suggestions': [
        AppLocalizations.mainProductView.tr(),
        AppLocalizations.differentAngles.tr(),
        AppLocalizations.closeUpDetails.tr(),
        AppLocalizations.packagingAccessories.tr(),
      ],
    };
  }

  // Safe context getter - uses navigator key if context is invalid
  BuildContext get _safeContext {
    if (_contextRef != null && Navigator.maybeOf(_contextRef!) != null) {
      return _contextRef!;
    }
    // Use navigator key's current context as fallback
    return navigatorKey.currentContext ?? context;
  }

  // Pick single image
  Future<void> _pickImage(BuildContext dialogContext, {ImageSource source = ImageSource.gallery}) async {
    if (_isProcessingImage || !mounted) return;
    
    // Close the source selection dialog first
    if (Navigator.canPop(dialogContext)) {
      Navigator.pop(dialogContext);
    }
    
    final itemProvider = Provider.of<ItemProvider>(_safeContext, listen: false);
    
    if (itemProvider.images.length >= _maxImages) {
      _showErrorSnackBar(AppLocalizations.maximumPhotosLimitReached.tr(args: ['$_maxImages']));
      return;
    }
    
    if (mounted) {
      setState(() {
        _isProcessingImage = true;
      });
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFile != null && mounted) {
        // Show processing dialog
        _showProcessingDialog(AppLocalizations.addingWatermark.tr());
        
        // Add watermark to image
        final watermarkedImage = await _addWatermarkToImage(pickedFile);
        
        // Hide dialog safely
        _hideProcessingDialog();
        
        if (watermarkedImage != null && mounted) {
          final success = await itemProvider.addImage(watermarkedImage);
          
          if (mounted) {
            if (!success && itemProvider.error != null) {
              _showErrorSnackBar(itemProvider.error!);
            } else if (success) {
              _showSuccessSnackBar(AppLocalizations.photoAddedWithWatermark.tr());
              // Force rebuild to show the new image
              setState(() {});
            }
          }
        } else if (mounted) {
          _showErrorSnackBar(AppLocalizations.failedToProcessImage.tr());
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      _hideProcessingDialog();
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.errorPickingImage.tr(args: ['$e']));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  // Pick multiple images with intelligent batching
  Future<void> _pickMultipleImages(BuildContext dialogContext) async {
    if (_isProcessingImage || !mounted) return;
    
    // Close the source selection dialog first
    if (Navigator.canPop(dialogContext)) {
      Navigator.pop(dialogContext);
    }
    
    final itemProvider = Provider.of<ItemProvider>(_safeContext, listen: false);
    final remainingSlots = _maxImages - itemProvider.images.length;
    
    if (remainingSlots <= 0) {
      _showErrorSnackBar(AppLocalizations.maximumPhotosLimitReached.tr(args: ['$_maxImages']));
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessingImage = true;
      });
    }

    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      print('Multiple images picked: ${pickedFiles.length}');
      
      if (pickedFiles.isNotEmpty && mounted) {
        // Limit to remaining slots
        final filesToProcess = pickedFiles.take(remainingSlots).toList();
        
        // Show processing dialog
        _showProcessingDialog(AppLocalizations.processingImagesCount.tr(args: ['${filesToProcess.length}']));
        
        int successCount = 0;
        int failCount = 0;
        
        // Process in batches of 3 to avoid memory issues
        const batchSize = 3;
        for (int i = 0; i < filesToProcess.length; i += batchSize) {
          if (!mounted) break; // Check if widget is still mounted
          
          final batch = filesToProcess.skip(i).take(batchSize).toList();
          
          // Process batch sequentially to avoid overwhelming the system
          for (final file in batch) {
            if (!mounted) break;
            
            try {
              final watermarkedImage = await _addWatermarkToImage(file);
              if (watermarkedImage != null && mounted) {
                final success = await itemProvider.addImage(watermarkedImage);
                if (success) {
                  successCount++;
                } else {
                  failCount++;
                }
              } else {
                failCount++;
              }
            } catch (e) {
              print('Error processing image: $e');
              failCount++;
            }
          }
          
          // Small delay between batches and update UI
          if (i + batchSize < filesToProcess.length && mounted) {
            setState(() {}); // Update UI to show progress
            await Future.delayed(Duration(milliseconds: 300));
          }
        }
        
        // Hide dialog safely
        _hideProcessingDialog();
        
        // Show result message and update UI
        if (mounted) {
          setState(() {}); // Force rebuild to show all new images
          
          if (successCount > 0 && failCount == 0) {
            _showSuccessSnackBar(AppLocalizations.photosAddedSuccessfully.tr(args: ['$successCount']));
          } else if (successCount > 0 && failCount > 0) {
            _showErrorSnackBar(AppLocalizations.photosAddedFailed.tr(args: ['$successCount', '$failCount']));
          } else {
            _showErrorSnackBar(AppLocalizations.failedToAddPhotos.tr());
          }
        }
      }
    } catch (e) {
      print('Error picking multiple images: $e');
      _hideProcessingDialog();
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.errorPickingImages.tr(args: ['$e']));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  void _showProcessingDialog(String message) {
    if (!_isDialogShowing && mounted) {
      _isDialogShowing = true;
      showDialog(
        context: _safeContext,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(ColorsController.primaryColor),
                ),
                SizedBox(height: 16),
                Text(
                  message,
                  style: GoogleFonts.jost(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _hideProcessingDialog() {
    if (_isDialogShowing) {
      _isDialogShowing = false;
      final context = _safeContext;
      final navigator = Navigator.maybeOf(context);
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
      }
    }
  }

  void _showErrorSnackBar(String message) {
    final context = _safeContext;
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    final context = _safeContext;
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Enhanced watermark function with better positioning and styling
  Future<XFile?> _addWatermarkToImage(XFile originalImage) async {
    try {
      // Read original image
      final bytes = await originalImage.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Create a recorder for drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw original image
      canvas.drawImage(image, Offset.zero, Paint());
      
      // Calculate watermark size based on image size
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final watermarkFontSize = (imageSize.width * 0.04).clamp(16.0, 32.0);
      
      // Create watermark text
      final textSpan = TextSpan(
        text: 'Delloni',
        style: TextStyle(
          color: Colors.white,
          fontSize: watermarkFontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 3,
              color: Colors.black.withOpacity(0.8),
              offset: Offset(1, 1),
            ),
            Shadow(
              blurRadius: 6,
              color: Colors.black.withOpacity(0.3),
              offset: Offset(2, 2),
            ),
          ],
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      
      // Position watermark at bottom right with padding
      final padding = imageSize.width * 0.03;
      final position = Offset(
        imageSize.width - textPainter.width - padding,
        imageSize.height - textPainter.height - padding,
      );
      
      // Add semi-transparent background for better visibility
      final backgroundRect = Rect.fromLTWH(
        position.dx - 8,
        position.dy - 4,
        textPainter.width + 16,
        textPainter.height + 8,
      );
      
      final backgroundPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(backgroundRect, Radius.circular(4)),
        backgroundPaint,
      );
      
      // Paint the watermark text
      textPainter.paint(canvas, position);
      
      // Convert to image
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(image.width, image.height);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        // Save watermarked image
        final tempDir = await Directory.systemTemp.createTemp();
        final watermarkedFile = File('${tempDir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.png');
        await watermarkedFile.writeAsBytes(byteData.buffer.asUint8List());
        
        return XFile(watermarkedFile.path);
      }
    } catch (e) {
      print('Error adding watermark: $e');
    }
    
    // Return original image if watermarking fails
    return originalImage;
  }
void _showImageSourceDialog(BuildContext context) {
  final requirements = _getCategoryPhotoRequirements();
  final isUnlimitedCategory = requirements['type'] == AppLocalizations.realEstate.tr() || requirements['type'] == AppLocalizations.vehicle.tr();
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext dialogContext) => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                AppLocalizations.addPhotosCategory.tr(),
                style: GoogleFonts.jost(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              // Text(
              //   AppLocalizations.recommendedPhotos.tr(args: ['${requirements['recommended']}', '${requirements['max']}']),
              //   style: GoogleFonts.jost(
              //     fontSize: 12,
              //     color: Colors.grey[600],
              //   ),
              // ),
              SizedBox(height: 16),
              
              // Photo suggestions for unlimited categories
              if (isUnlimitedCategory) ...[
                Text(
                  AppLocalizations.suggestedPhotos.tr(),
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: (requirements['suggestions'] as List<String>).map((suggestion) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorsController.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ColorsController.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        suggestion,
                        style: GoogleFonts.jost(
                          fontSize: 10,
                          color: ColorsController.primaryColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
              ],
              
              // Photo source options
              // Row(
              //   children: [
              //     Expanded(
              //       child: _buildImageSourceOption(
              //         AppLocalizations.camera.tr(),
              //         Icons.camera_alt,
              //         Colors.blue,
              //         () => _pickImage(dialogContext, source: ImageSource.camera),
              //       ),
              //     ),
              //     SizedBox(width: 16),
              //     Expanded(
              //       child: _buildImageSourceOption(
              //         AppLocalizations.gallery.tr(),
              //         Icons.photo_library,
              //         Colors.green,
              //         () => _pickImage(dialogContext, source: ImageSource.gallery),
              //       ),
              //     ),
              //   ],
              // ),
              
              SizedBox(height: 16),
              
              // Multiple photos option - FIXED: Always show the dialog and use proper dialogContext
              Container(
                width: double.infinity,
                child: _buildImageSourceOption(
                  AppLocalizations.multiplePhotos.tr(),
                  Icons.photo_library_outlined,
                  ColorsController.primaryColor,
                  () => _pickMultipleImages(dialogContext), // Use dialogContext here
                  subtitle:' ${AppLocalizations.selectMultiplePhotos.tr()}${_maxImages - Provider.of<ItemProvider>(context, listen: false).images.length}' ,
                ),
              ),
              
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    ),
  );
}
  Widget _buildImageSourceOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: subtitle != null 
          ? Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.jost(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.jost(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building UI with ${Provider.of<ItemProvider>(context, listen: false).images.length} images');
    
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        final requirements = _getCategoryPhotoRequirements();
        final minPhotos = requirements['min'] as int;
        final maxPhotos = requirements['max'] as int;
        final categoryType = requirements['type'] as String;
        
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              '${AppLocalizations.photos.tr()}',
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with category info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.addPhotos.tr()}',
                            style: GoogleFonts.jost(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            categoryType == AppLocalizations.realEstate.tr()
                                ? AppLocalizations.showPropertyDetails.tr()
                                : '${AppLocalizations.greatPhotosHelp.tr()}',
                            style: GoogleFonts.jost(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Category indicator
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (categoryType == 'Real Estate' || categoryType == 'Vehicle')
                            ? Colors.blue[50] 
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (categoryType == 'Real Estate' || categoryType == 'Vehicle')
                              ? Colors.blue 
                              : Colors.grey,
                        ),
                      ),
                      child: Text(
                        categoryType,
                        style: GoogleFonts.jost(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: (categoryType == 'Real Estate' || categoryType == 'Vehicle')
                              ? Colors.blue[700] 
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Enhanced Progress Indicator
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: itemProvider.images.length >= minPhotos 
                        ? Colors.green[50] 
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: itemProvider.images.length >= minPhotos 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            itemProvider.images.length >= minPhotos 
                                ? Icons.check_circle 
                                : Icons.info_outline,
                            size: 20,
                            color: itemProvider.images.length >= minPhotos 
                                ? Colors.green[700] 
                                : Colors.orange[700],
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${itemProvider.images.length}/$maxPhotos photos',
                            style: GoogleFonts.jost(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: itemProvider.images.length >= minPhotos 
                                  ? Colors.green[700] 
                                  : Colors.orange[700],
                            ),
                          ),
                          Spacer(),
                          if (categoryType == AppLocalizations.realEstate.tr() || categoryType == AppLocalizations.vehicle.tr())
                            Text(
                              AppLocalizations.unlimited.tr(),
                              style: GoogleFonts.jost(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (itemProvider.images.length / maxPhotos).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            itemProvider.images.length >= minPhotos 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        itemProvider.images.length < minPhotos
                            ? '"Minimum $maxPhotos photos required'
                            // AppLocalizations.minimumPhotosRequired.tr(args: ['$minPhotos'])
                            : (categoryType == AppLocalizations.realEstate.tr() || categoryType == AppLocalizations.vehicle.tr())
                                ? categoryType == AppLocalizations.vehicle.tr() 
                                    ? AppLocalizations.addMorePhotosVehicle.tr()
                                    : AppLocalizations.addMorePhotosProperty.tr()
                                : AppLocalizations.greatAddMorePhotos.tr(args: ['${maxPhotos - itemProvider.images.length}']),
                        style: GoogleFonts.jost(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Upload Area
                GestureDetector(
                  onTap: itemProvider.images.length < maxPhotos && !_isProcessingImage 
                      ? () => _showImageSourceDialog(context)
                      : null,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: itemProvider.images.length < maxPhotos 
                            ? ColorsController.primaryColor.withOpacity(0.3)
                            : Colors.grey[300]!,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: itemProvider.images.length < maxPhotos 
                          ? ColorsController.primaryColor.withOpacity(0.05)
                          : Colors.grey[50],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: itemProvider.images.length < maxPhotos 
                                ? ColorsController.primaryColor.withOpacity(0.1)
                                : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isProcessingImage 
                                ? Icons.hourglass_empty
                                : itemProvider.images.length < maxPhotos 
                                    ? Icons.camera_alt_outlined
                                    : Icons.block,
                            size: 32,
                            color: _isProcessingImage 
                                ? Colors.orange
                                : itemProvider.images.length < maxPhotos 
                                    ? ColorsController.primaryColor
                                    : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isProcessingImage 
                              ? AppLocalizations.processingImages.tr()
                              : itemProvider.images.length < maxPhotos 
                                  ? AppLocalizations.tapToAddPhotos.tr()
                                  : AppLocalizations.maximumPhotosReached.tr(),
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _isProcessingImage 
                                ? Colors.orange
                                : itemProvider.images.length < maxPhotos 
                                    ? Colors.black
                                    : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (categoryType == 'Real Estate' || categoryType == 'Vehicle')
                              ? AppLocalizations.selectMultiplePhotosGallery.tr()
                              : AppLocalizations.singleMultiplePhotos.tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Photo Grid Header
                if (itemProvider.images.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        '${AppLocalizations.yourPhotos.tr()}',
                        style: GoogleFonts.jost(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ColorsController.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${itemProvider.images.length}',
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ColorsController.primaryColor,
                          ),
                        ),
                      ),
                      Spacer(),
                      if (itemProvider.images.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _showClearAllDialog(itemProvider),
                          icon: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          label: Text(
                            '${AppLocalizations.clearAll.tr()}',
                            style: GoogleFonts.jost(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
                
                // Photo Grid
                Expanded(
                  child: itemProvider.images.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                easy.tr('no_photos_added_yet'),
                                style: GoogleFonts.jost(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                easy.tr('add_at_least_photos', args: ['${minPhotos}']),
                                style: GoogleFonts.jost(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: (categoryType == 'Real Estate' || categoryType == 'Vehicle') ? 2 : 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: (categoryType == 'Real Estate' || categoryType == 'Vehicle') ? 1.2 : 1,
                          ),
                          itemCount: itemProvider.images.length + (itemProvider.images.length < maxPhotos ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < itemProvider.images.length) {
                              return _buildPhotoItem(itemProvider, index, categoryType == 'Real Estate' || categoryType == 'Vehicle');
                            } else {
                              return _buildAddMoreButton();
                            }
                          },
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Bottom Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          AppLocalizations.back.tr(),
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
                        onPressed: itemProvider.images.length >= minPhotos && !_isProcessingImage ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ReviewPublishPage()),
                          );
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: itemProvider.images.length >= minPhotos && !_isProcessingImage
                              ? ColorsController.primaryColor
                              : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _isProcessingImage 
                              ? AppLocalizations.processing.tr()
                              : itemProvider.images.length >= minPhotos 
                                  ? AppLocalizations.next.tr()
                                  : AppLocalizations.addMorePhotos.tr(args: ['${minPhotos - itemProvider.images.length}']),
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

  Widget _buildPhotoItem(ItemProvider itemProvider, int index, bool isRealEstate) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Photo
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(File(itemProvider.images[index].path)),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Photo number indicator
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Main photo indicator
          if (index == 0)
            Positioned(
              top: 6,
              right: 30,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  easy.tr('main'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // Watermark indicator
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.white, size: 10),
                  SizedBox(width: 2),
                  Text(
                    easy.tr('watermark'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Remove button
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _showRemovePhotoDialog(itemProvider, index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return GestureDetector(
      onTap: !_isProcessingImage ? () => _showImageSourceDialog(context) : null,
      child: Container(
        decoration: BoxDecoration(
          color: ColorsController.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ColorsController.primaryColor.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 24,
              color: ColorsController.primaryColor,
            ),
            SizedBox(height: 4),
            Text(
              easy.tr('add_more'),
              style: GoogleFonts.jost(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: ColorsController.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemovePhotoDialog(ItemProvider itemProvider, int index) {
    showDialog(
      context: _safeContext,
      builder: (context) => AlertDialog(
        title: Text(
          easy.tr('remove_photo'),
          style: GoogleFonts.jost(fontWeight: FontWeight.w600),
        ),
        content: Text(
          easy.tr('remove_photo_confirmation'),
          style: GoogleFonts.jost(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              easy.tr('cancel'),
              style: GoogleFonts.jost(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              itemProvider.removeImage(index);
              _showSuccessSnackBar(easy.tr('photo_removed'));
              setState(() {}); // Force rebuild to update UI
            },
            child: Text(
              easy.tr('remove'),
              style: GoogleFonts.jost(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(ItemProvider itemProvider) {
    showDialog(
      context: _safeContext,
      builder: (context) => AlertDialog(
        title: Text(
          easy.tr('clear_all_photos'),
          style: GoogleFonts.jost(fontWeight: FontWeight.w600),
        ),
        content: Text(
          easy.tr('clear_all_photos_confirmation'),
          style: GoogleFonts.jost(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              easy.tr('cancel'),
              style: GoogleFonts.jost(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear all images
              while (itemProvider.images.isNotEmpty) {
                itemProvider.removeImage(0);
              }
              _showSuccessSnackBar(easy.tr('all_photos_cleared'));
              setState(() {}); // Force rebuild to update UI
            },
            child: Text(
              easy.tr('remove'),
              style: GoogleFonts.jost(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Make sure to close any open dialogs
    if (_isDialogShowing) {
      _hideProcessingDialog();
    }
    super.dispose();
  }
}