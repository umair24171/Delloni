import 'dart:io';
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/view/review_publish.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

class EnhancedAddPhotosPage extends StatefulWidget { 
  const EnhancedAddPhotosPage({super.key});

  @override
  State<EnhancedAddPhotosPage> createState() => _EnhancedAddPhotosPageState();
}

class _EnhancedAddPhotosPageState extends State<EnhancedAddPhotosPage> {
  bool _isProcessingImage = false;
  bool _isDialogShowing = false;
  
  // Pick single image
  Future<void> _pickImage(BuildContext context, {ImageSource source = ImageSource.gallery}) async {
    if (_isProcessingImage) return;
    
    setState(() {
      _isProcessingImage = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        // Show processing dialog
        _showProcessingDialog(context, 'Adding watermark...');
        
        // Add watermark to image
        final watermarkedImage = await _addWatermarkToImage(pickedFile);
        
        // Hide processing dialog safely
        _hideProcessingDialog();
        
        if (watermarkedImage != null) {
          final itemProvider = Provider.of<ItemProvider>(context, listen: false);
          final success = await itemProvider.addImage(watermarkedImage);
          
          if (!success && itemProvider.error != null) {
            _showErrorSnackBar(context, itemProvider.error!);
          } else if (success) {
            _showSuccessSnackBar(context, 'Photo added with watermark!');
          }
        } else {
          _showErrorSnackBar(context, 'Failed to process image');
        }
      }
    } catch (e) {
      _hideProcessingDialog();
      _showErrorSnackBar(context, 'Error picking image: $e');
    } finally {
      setState(() {
        _isProcessingImage = false;
      });
    }
  }

  // Pick multiple images
  Future<void> _pickMultipleImages(BuildContext context) async {
    if (_isProcessingImage) return;
    
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final remainingSlots = 10 - itemProvider.images.length;
    
    if (remainingSlots <= 0) {
      _showErrorSnackBar(context, 'Maximum photos limit reached');
      return;
    }

    setState(() {
      _isProcessingImage = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFiles.isNotEmpty) {
        // Limit to remaining slots
        final filesToProcess = pickedFiles.take(remainingSlots).toList();
        
        // Show processing dialog
        _showProcessingDialog(context, 'Processing ${filesToProcess.length} images...');
        
        int successCount = 0;
        int failCount = 0;
        
        for (int i = 0; i < filesToProcess.length; i++) {
          try {
            // Update dialog message
            if (_isDialogShowing) {
              // You could update the dialog text here if needed
            }
            
            // Add watermark to image
            final watermarkedImage = await _addWatermarkToImage(filesToProcess[i]);
            
            if (watermarkedImage != null) {
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
            failCount++;
          }
        }
        
        // Hide processing dialog
        _hideProcessingDialog();
        
        // Show result message
        if (successCount > 0 && failCount == 0) {
          _showSuccessSnackBar(context, '$successCount photos added successfully!');
        } else if (successCount > 0 && failCount > 0) {
          _showErrorSnackBar(context, '$successCount photos added, $failCount failed');
        } else {
          _showErrorSnackBar(context, 'Failed to add photos');
        }
      }
    } catch (e) {
      _hideProcessingDialog();
      _showErrorSnackBar(context, 'Error picking images: $e');
    } finally {
      setState(() {
        _isProcessingImage = false;
      });
    }
  }

  void _showProcessingDialog(BuildContext context, String message) {
    if (!_isDialogShowing && mounted) {
      _isDialogShowing = true;
      showDialog(
        context: context,
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
    if (_isDialogShowing && mounted) {
      _isDialogShowing = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
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

  void _showSuccessSnackBar(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
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
        text: 'Delloni', // Replace with your app name
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Add Photos',
                  style: GoogleFonts.jost(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                
                // Single photo options
                Row(
                  children: [
                    Expanded(
                      child: _buildImageSourceOption(
                        context,
                        'Camera',
                        Icons.camera_alt,
                        Colors.blue,
                        () {
                          Navigator.pop(context);
                          _pickImage(context, source: ImageSource.camera);
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildImageSourceOption(
                        context,
                        'Gallery',
                        Icons.photo_library,
                        Colors.green,
                        () {
                          Navigator.pop(context);
                          _pickImage(context, source: ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Multiple photos option
                Container(
                  width: double.infinity,
                  child: _buildImageSourceOption(
                    context,
                    'Multiple Photos',
                    Icons.photo_library_outlined,
                    ColorsController.primaryColor,
                    () {
                      // Navigator.pop(context);
                      _pickMultipleImages(context);
                    },
                    subtitle: 'Select multiple photos at once',
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
    BuildContext context,
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
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
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
              'Photos',
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
                // Header Section
                Text(
                  'Add Photos',
                  style: GoogleFonts.jost(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Great photos help your item sell faster! Upload at least 2 images from different angles. Watermark will be added automatically.',
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Progress Indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: itemProvider.images.length >= 2 
                            ? Colors.green[50] 
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: itemProvider.images.length >= 2 
                              ? Colors.green 
                              : Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            itemProvider.images.length >= 2 
                                ? Icons.check_circle 
                                : Icons.info_outline,
                            size: 16,
                            color: itemProvider.images.length >= 2 
                                ? Colors.green[700] 
                                : Colors.orange[700],
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${itemProvider.images.length}/10 images',
                            style: GoogleFonts.jost(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: itemProvider.images.length >= 2 
                                  ? Colors.green[700] 
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Minimum 2 required',
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Upload Area
                GestureDetector(
                  onTap: itemProvider.images.length < 10 && !_isProcessingImage 
                      ? () => _showImageSourceDialog(context)
                      : null,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: itemProvider.images.length < 10 
                            ? ColorsController.primaryColor.withOpacity(0.3)
                            : Colors.grey[300]!,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: itemProvider.images.length < 10 
                          ? ColorsController.primaryColor.withOpacity(0.05)
                          : Colors.grey[50],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: itemProvider.images.length < 10 
                                ? ColorsController.primaryColor.withOpacity(0.1)
                                : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isProcessingImage 
                                ? Icons.hourglass_empty
                                : itemProvider.images.length < 10 
                                    ? Icons.camera_alt_outlined
                                    : Icons.block,
                            size: 32,
                            color: _isProcessingImage 
                                ? Colors.orange
                                : itemProvider.images.length < 10 
                                    ? ColorsController.primaryColor
                                    : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isProcessingImage 
                              ? 'Processing images...'
                              : itemProvider.images.length < 10 
                                  ? 'Tap to add photos'
                                  : 'Maximum photos reached',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _isProcessingImage 
                                ? Colors.orange
                                : itemProvider.images.length < 10 
                                    ? Colors.black
                                    : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Single or multiple photos\nJPEG, PNG formats, up to 5MB\nWatermark added automatically',
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
                
                // Photo Grid
                if (itemProvider.images.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Your Photos',
                        style: GoogleFonts.jost(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Spacer(),
                      if (itemProvider.images.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _showClearAllDialog(context, itemProvider),
                          icon: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          label: Text(
                            'Clear All',
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
                                'No photos added yet',
                                style: GoogleFonts.jost(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add at least 2 photos to continue',
                                style: GoogleFonts.jost(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: itemProvider.images.length + (itemProvider.images.length < 10 ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < itemProvider.images.length) {
                              return _buildPhotoItem(context, itemProvider, index);
                            } else {
                              return _buildAddMoreButton(context);
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
                        onPressed: itemProvider.images.length >= 2 && !_isProcessingImage ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ReviewPublishPage()),
                          );
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: itemProvider.images.length >= 2 && !_isProcessingImage
                              ? ColorsController.primaryColor
                              : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _isProcessingImage 
                              ? 'Processing...'
                              : itemProvider.images.length >= 2 
                                  ? 'Next' 
                                  : 'Add ${2 - itemProvider.images.length} More',
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

  Widget _buildPhotoItem(BuildContext context, ItemProvider itemProvider, int index) {
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
                    'WM',
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
              onTap: () => _showRemovePhotoDialog(context, itemProvider, index),
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

  Widget _buildAddMoreButton(BuildContext context) {
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
              'Add More',
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

  void _showRemovePhotoDialog(BuildContext context, ItemProvider itemProvider, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Photo',
          style: GoogleFonts.jost(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove this photo?',
          style: GoogleFonts.jost(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.jost(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              itemProvider.removeImage(index);
              _showSuccessSnackBar(context, 'Photo removed');
            },
            child: Text(
              'Remove',
              style: GoogleFonts.jost(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, ItemProvider itemProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Photos',
          style: GoogleFonts.jost(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove all photos? This action cannot be undone.',
          style: GoogleFonts.jost(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
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
              _showSuccessSnackBar(context, 'All photos cleared');
            },
            child: Text(
              'Clear All',
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