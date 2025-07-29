import 'dart:io';
import 'dart:typed_data';
import 'package:arabicmarketplace/main.dart';
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/view/review_publish.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart'; // ADDED: For temp directory

// Add these imports at the top of your file
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class EnhancedAddPhotosPage extends StatefulWidget {
  const EnhancedAddPhotosPage({super.key});

  @override
  State<EnhancedAddPhotosPage> createState() => _EnhancedAddPhotosPageState();
}

class _EnhancedAddPhotosPageState extends State<EnhancedAddPhotosPage> {
  bool _isProcessingImage = false;
  bool _isDialogShowing = false;
  
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
      // _determineMaxImages();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contextRef = context; // Store context reference
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

  // ✅ ADD THIS COLOR FIX FUNCTION
  Future<File> fixImageColor(File originalImage) async {
    // Only apply fix on iOS devices
    if (!Platform.isIOS) {
      return originalImage;
    }
     
    try {
      return await compute(
        (Map<String, dynamic> params) async {
          File file = params['file'];
          final bytes = await file.readAsBytes();
                 
          // 🔥 Use img. prefix for all image package functions
          img.Image? image = img.decodeImage(bytes);
                 
          if (image == null) {
            print("❌ Failed to decode image: ${file.path}");
            return file; // Return original if decoding fails
          }
                 
          print("✅ Image decoded successfully, applying color fix...");
                 
          // Re-encode without resizing to preserve quality, just fix color profile
          image = img.copyResize(image, width: image.width, height: image.height);
                 
          // Create fixed file
          final outputFile = File('${file.parent.path}/fixed_${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}');
                 
          // Encode as JPG with high quality
          final encodedBytes = img.encodeJpg(image, quality: 90);
          await outputFile.writeAsBytes(encodedBytes);
                 
          print("✅ iOS color fix applied: ${outputFile.path}");
          return outputFile;
        },
        {'file': originalImage}
      );
    } catch (e) {
      print("❌ Error in fixImageColor: $e");
      return originalImage; // Return original file if fix fails
    }
  }

  // ✅ MODIFIED: Pick single image with color fix for camera photos
  Future<void> _pickImage(BuildContext dialogContext, {ImageSource source = ImageSource.gallery, required ItemProvider itemPro}) async {
    if (_isProcessingImage || !mounted) return;
    
    // Close the source selection dialog first
    if (Navigator.canPop(dialogContext)) {
      Navigator.pop(dialogContext);
    }
    
    final itemProvider = Provider.of<ItemProvider>(_safeContext, listen: false);
    
    if (itemProvider.images.length >= itemProvider.maxImages) {
      _showErrorSnackBar(AppLocalizations.maximumPhotosLimitReached.tr(args: ['$itemProvider.maxImages']));
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
        String processingMessage = source == ImageSource.camera 
          ?  "Processing camera image..."
          : AppLocalizations.addingWatermark.tr();
        _showProcessingDialog(processingMessage);
        
        XFile processedFile = pickedFile;
        
        // ✅ Apply color fix ONLY for camera photos
        if (source == ImageSource.camera) {
          print("📷 Camera image detected, applying color fix...");
          final fixedFile = await fixImageColor(File(pickedFile.path));
          processedFile = XFile(fixedFile.path);
          print("✅ Color fix completed for camera image");
        }
        
        // Add watermark to image (whether fixed or original)
        final watermarkedImage = await _addWatermarkToImage(processedFile);
        
        // Hide dialog safely
        _hideProcessingDialog();
        
        if (watermarkedImage != null && mounted) {
          final success = await itemProvider.addImage(watermarkedImage);
          
          if (mounted) {
            if (!success && itemProvider.error != null) {
              _showErrorSnackBar(itemProvider.error!);
            } else if (success) {
              String successMessage = source == ImageSource.camera
                ?"Camera photo processed and added successfully!"
                : AppLocalizations.photoAddedWithWatermark.tr();
              _showSuccessSnackBar(successMessage);
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

  // Pick multiple images with intelligent batching (no changes needed here since it's gallery only)
  Future<void> _pickMultipleImages(BuildContext dialogContext) async {
    if (_isProcessingImage || !mounted) return;
    
    // Close the source selection dialog first
    if (Navigator.canPop(dialogContext)) {
      Navigator.pop(dialogContext);
    }
    
    final itemProvider = Provider.of<ItemProvider>(_safeContext, listen: false);
    final remainingSlots = itemProvider.maxImages - itemProvider.images.length;
    
    if (remainingSlots <= 0) {
      _showErrorSnackBar(AppLocalizations.maximumPhotosLimitReached.tr(args: ['${itemProvider.maxImages}']));
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

  // Enhanced watermark function with logo image
  Future<XFile?> _addWatermarkToImage(XFile originalImage) async {
    try {
      print('Starting watermark process for: ${originalImage.path}');
      
      // Read original image
      final bytes = await originalImage.readAsBytes();
      print('Original image size: ${bytes.length} bytes');
      
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      print('Original image dimensions: ${image.width}x${image.height}');

      // Load logo from assets
      final ByteData logoData = await rootBundle.load('assets/icons/logo_two.jpeg');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      print('Logo loaded, size: ${logoBytes.length} bytes');
      
      final ui.Codec logoCodec = await ui.instantiateImageCodec(logoBytes);
      final ui.FrameInfo logoFrame = await logoCodec.getNextFrame();
      final ui.Image logoImage = logoFrame.image;
      print('Logo dimensions: ${logoImage.width}x${logoImage.height}');

      // Create a recorder for drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw original image
      canvas.drawImage(image, Offset.zero, Paint());
      
      // Calculate logo size (smaller and safer positioning)
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final logoWidth = imageSize.width * 0.08; // Reduced from 0.10 to 0.08
      final logoAspectRatio = logoImage.width / logoImage.height;
      final logoHeight = logoWidth / logoAspectRatio;
      
      print('Calculated logo size: ${logoWidth}x${logoHeight}');
      
      // IMPROVED: Calculate safe zone for watermark (avoids crop areas)
      final safeMarginX = imageSize.width * 0.05; // 5% margin from edges
      final safeMarginY = imageSize.height * 0.05; // 5% margin from edges
      
      // Position logo in bottom right but within safe zone
      final logoPosition = Offset(
        imageSize.width - logoWidth - safeMarginX,
        imageSize.height - logoHeight - safeMarginY,
      );
      
      print('Logo position: ${logoPosition.dx}, ${logoPosition.dy}');
      
      // Add semi-transparent background for better visibility
      final backgroundRect = Rect.fromLTWH(
        logoPosition.dx - 6,
        logoPosition.dy - 6,
        logoWidth + 12,
        logoHeight + 12,
      );
      
      final backgroundPaint = Paint()
        ..color = Colors.black.withOpacity(0.7) // Darker background for better visibility
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(backgroundRect, Radius.circular(6)),
        backgroundPaint,
      );
      
      // Draw the logo with slight transparency
      final logoPaint = Paint()
        ..colorFilter = ColorFilter.mode(
          Colors.white.withOpacity(0.9),
          BlendMode.modulate,
        );
      
      final logoRect = Rect.fromLTWH(logoPosition.dx, logoPosition.dy, logoWidth, logoHeight);
      canvas.drawImageRect(
        logoImage,
        Rect.fromLTWH(0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
        logoRect,
        logoPaint,
      );
      
      print('Logo drawn successfully');
      
      // Convert to image
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(image.width, image.height);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        // Save watermarked image
        final tempDir = await Directory.systemTemp.createTemp();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final watermarkedFile = File('${tempDir.path}/watermarked_$timestamp.png');
        await watermarkedFile.writeAsBytes(byteData.buffer.asUint8List());
        
        print('Watermarked image saved: ${watermarkedFile.path}');
        print('Watermarked image size: ${await watermarkedFile.length()} bytes');
        
        return XFile(watermarkedFile.path);
      }
      
      print('Failed to generate byteData');
      return originalImage;
      
    } catch (e) {
      print('Error adding watermark: $e');
      print('Stack trace: ${StackTrace.current}');
      return originalImage;
    }
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
                Text(
                  AppLocalizations.recommendedPhotos.tr(),
                  style: GoogleFonts.jost(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
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
                
                // Photo source options - SINGLE PHOTO
                Text(
                  'Single Photo',
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Consumer<ItemProvider>(
                        builder: (context, itemProvider, child) {
                          return _buildImageSourceOption(
                            AppLocalizations.camera.tr(),
                            Icons.camera_alt,
                            Colors.blue,
                            () => _pickImage(dialogContext, source: ImageSource.camera, itemPro: itemProvider),
                          );
                        }
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Consumer<ItemProvider>(
                        builder: (context, itemProvider, child) {
                          return _buildImageSourceOption(
                            AppLocalizations.gallery.tr(),
                            Icons.photo_library,
                            Colors.green,
                            () => _pickImage(dialogContext, source: ImageSource.gallery, itemPro: itemProvider),
                          );
                        }
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                // Multiple photos option
                Text(
                  AppLocalizations.multiplePhotos.tr() ?? 'Multiple Photos',
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  child: _buildImageSourceOption(
                    AppLocalizations.gallery.tr(),
                    Icons.photo_library_outlined,
                    ColorsController.primaryColor,
                    () => _pickMultipleImages(dialogContext),
                    subtitle: '${AppLocalizations.selectMultiplePhotos.tr()}',
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
        final maxPhotos = itemProvider.maxImages;
        final categoryType = requirements['type'] as String;
        
        return Scaffold(
          // backgroundColor: Colors.white,
          appBar: AppBar(
            // backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              '${AppLocalizations.photos.tr()}',
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w600,
               
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
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
                                      // color: Colors.black,
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
                                    '${itemProvider.images.length}/$maxPhotos ${"photos".tr()}',
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
                                    ? '"${"Minimum".tr()} $minPhotos ${"photos required".tr()}'
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
                        itemProvider.images.isEmpty
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
                                '${"Add at least".tr()} $minPhotos ${"photos to continue"}',
                                // easy.tr('add_at_least_photos', args: ['${minPhotos}']),
                                style: GoogleFonts.jost(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                            : GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
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

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

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
                                  :"${"Add More".tr()} ${'${minPhotos - itemProvider.images.length}'}",
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