import 'dart:io';
import 'dart:typed_data';
import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
import 'package:arabicmarketplace/screens/home/model/category_model.dart';
import 'package:arabicmarketplace/screens/notifications/controller/saved_search_provider.dart';
import 'package:arabicmarketplace/screens/search_page/city_district_selection_page.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_page_filter.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
// Updated ItemProvider class - Add these changes to your existing ItemProvider
// Enhanced ItemProvider with dynamic photo limits based on category
class ItemProvider with ChangeNotifier {
  // Form data - Updated to include category ID and name
  String itemTitle = '';
  String category = ''; // This will store the category ID
  String? categoryName; // This will store the category display name
  String condition = '';
  String description = '';
  String brand = '';
  String dimensions = '';
  String color = '';
  double price = 0.0;
  bool allowPriceNegotiation = true;
  String shippingOption = 'Both';
  List<XFile> images = [];
  List<String> imageUrls = [];
  double? latitude;
  double? longitude;
  String? locationAddress;

   String? selectedCityId;
  String? selectedCityName;
  String? selectedDistrictId;
  String? selectedDistrictName;

  // State management
  bool _isUploading = false;
  bool _isPublishing = false;
  String? _error;
  double _uploadProgress = 0.0;
  // NEW: Check if we're in edit mode
bool get isEditMode => itemTitle.isNotEmpty && category.isNotEmpty;
// NEW: Get the item ID for editing (you'll need to store this when loading)
String? _editingItemId;
String? get editingItemId => _editingItemId;
void setEditingItemId(String? itemId) {
  _editingItemId = itemId;
  notifyListeners();
}
// ENHANCED: Update existing item instead of creating new one
Future<bool> updateExistingItem(BuildContext context) async {
  try {
    _setPublishing(true);
    _setError(null);

    developer.log('Starting update process for item: $_editingItemId');

    // Validate form data first
    if (!_validateFormData()) {
      _setPublishing(false);
      return false;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    if (user == null) {
      _setError('Please login to continue');
      _setPublishing(false);
      return false;
    }

    if (_editingItemId == null) {
      _setError('Item ID not found');
      _setPublishing(false);
      return false;
    }

    // If new images were added, upload them
    if (images.isNotEmpty) {
      developer.log('Uploading ${images.length} new images...');
      final uploadSuccess = await uploadImages(_editingItemId!);
      
      if (!uploadSuccess) {
        _setPublishing(false);
        return false;
      }
    }

    developer.log('Updating Firestore document...');

    // ENHANCED: Update item document with category-specific fields
    Map<String, dynamic> updateData = {
      'itemTitle': itemTitle.trim(),
      'category': category,
      'categoryName': categoryName,
      'condition': condition,
      'description': description.trim(),
      'brand': brand.trim(),
      'dimensions': dimensions.trim(),
      'color': color.trim(),
      'price': price,
      'allowPriceNegotiation': allowPriceNegotiation,
      'shippingOption': shippingOption,
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'cityId': selectedCityId,
      'cityName': selectedCityName,
      'districtId': selectedDistrictId,
      'districtName': selectedDistrictName,
      'updatedAt': FieldValue.serverTimestamp(),
      
      // Update category-specific fields
      'categorySpecificFields': _categorySpecificFields,
      'categoryFieldTemplate': _categoryFieldTemplate,
      'categoryTemplateName': _categoryTemplateName,
      'hasCustomFields': _categorySpecificFields.isNotEmpty,
    };

    // Only update imageUrls if new images were uploaded
    if (images.isNotEmpty) {
      updateData['imageUrls'] = imageUrls;
      updateData['photoCount'] = imageUrls.length;
    }

    await _firestore.collection('items').doc(_editingItemId!).update(updateData);

    developer.log('Item updated successfully!');
    _setPublishing(false);
    
    // Don't reset form here for edit mode - let the calling page handle navigation
    return true;

  } catch (e) {
    _setPublishing(false);
    _setError('Failed to update item: $e');
    developer.log('Update failed: $e');
    return false;
  }
}
// ENHANCED: Publish method that handles both create and update
Future<bool> publishOrUpdateItem(BuildContext context) async {
  if (isEditMode && _editingItemId != null) {
    return await updateExistingItem(context);
  } else {
    return await publishItem(context);
  }
}



  // Form controllers for validation
  final formKey = GlobalKey<FormState>();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ENHANCED: Dynamic photo limits based on category
  static const int minImagesDefault = 2;
  static const int maxImagesDefault = 10;
  static const int minImagesRealEstate = 5;
  static const int maxImagesRealEstate = 50;

   Map<String, dynamic> _categorySpecificFields = {};
  List<Map<String, dynamic>> _categoryFieldTemplate = [];
  String? _categoryTemplateName;

  // Getter for category-specific fields
  Map<String, dynamic> get categorySpecificFields => _categorySpecificFields;
  List<Map<String, dynamic>> get categoryFieldTemplate => _categoryFieldTemplate;
  String? get categoryTemplateName => _categoryTemplateName;

  // NEW: Update category-specific fields
  void updateCategorySpecificFields(Map<String, dynamic> fields) {
    _categorySpecificFields = fields;
    notifyListeners();
  }

  // NEW: Set category template
  void setCategoryTemplate(List<Map<String, dynamic>> template, String? templateName) {
    _categoryFieldTemplate = template;
    _categoryTemplateName = templateName;
    notifyListeners();
  }

  // NEW: Update single category field
  void updateCategoryField(String fieldName, dynamic value) {
    _categorySpecificFields[fieldName] = value;
    notifyListeners();
  }

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
    'construction',
    'plot',
    'farm',
    'hotel',
    'restaurant',
  };

  // Getters
  bool get isUploading => _isUploading;
  bool get isPublishing => _isPublishing;
  String? get error => _error;  
  double get uploadProgress => _uploadProgress;
  bool get canPublish => _validateFormData();

  // ENHANCED: Dynamic photo limits
  int get minImages {
    if (categoryName != null) {
      final categoryLower = categoryName!.toLowerCase();
      if (_unlimitedCategories.any((cat) => categoryLower.contains(cat))) {
        return minImagesRealEstate;
      }
    }
    return minImagesDefault;
  }

  int get maxImages {
    if (categoryName != null) {
      final categoryLower = categoryName!.toLowerCase();
      if (_unlimitedCategories.any((cat) => categoryLower.contains(cat))) {
        return maxImagesRealEstate;
      }
    }
    return maxImagesDefault;
  }

  bool get isRealEstateCategory {
    if (categoryName != null) {
      final categoryLower = categoryName!.toLowerCase();
      return _unlimitedCategories.any((cat) => categoryLower.contains(cat));
    }
    return false;
  }

  // ENHANCED: Category-specific image type validation
  List<String> get allowedImageTypes {
    if (isRealEstateCategory) {
      return ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif']; // More formats for real estate
    }
    return ['jpg', 'jpeg', 'png', 'webp'];
  }

  // ENHANCED: Category-specific max file size
  int get maxImageSizeMB {
    if (isRealEstateCategory) {
      return 10; // 10MB for real estate photos
    }
    return 5; // 5MB for regular items
  }

  void _setError(String? error) {
    _error = error;
    developer.log('ItemProvider Error: $error');
    notifyListeners();
  }

  void _setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  void _setPublishing(bool publishing) {
    _isPublishing = publishing;
    notifyListeners();
  }

  void _setUploadProgress(double progress) {
    _uploadProgress = progress;
    notifyListeners();
  }

  // Reset form data
 void resetForm() {
    itemTitle = '';
    category = '';
    categoryName = null;
    condition = '';
    description = '';
    brand = '';
    dimensions = '';
    color = '';
    price = 0.0;
    allowPriceNegotiation = true;
    shippingOption = 'Both';
    images.clear();
    imageUrls.clear();
    latitude = null;
    longitude = null;
    locationAddress = null;
    selectedCityId = null;
    selectedCityName = null;
    selectedDistrictId = null;
    selectedDistrictName = null;
    
    // NEW: Reset category-specific fields
    _categorySpecificFields.clear();
    _categoryFieldTemplate.clear();
    _categoryTemplateName = null;
    
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();
  }

  // ENHANCED: Validate form data with dynamic requirements
  bool _validateFormData() {
    List<String> errors = [];
    
    // Basic validations
    if (itemTitle.trim().isEmpty) errors.add(AppLocalizations.itemTitleRequired.tr());
    if (itemTitle.trim().length < 10) errors.add(AppLocalizations.titleTooShort.tr());
    if (category.isEmpty) errors.add(AppLocalizations.categoryRequired.tr());
    if (condition.isEmpty) errors.add(AppLocalizations.conditionRequired.tr());
    if (description.trim().isEmpty) errors.add(AppLocalizations.descriptionRequired.tr());
    
 
    
    if (price <= 0) errors.add(AppLocalizations.priceInvalid.tr());
    
    // Dynamic image validation
    if (images.length < minImages) {
      errors.add(AppLocalizations.imagesRequired.tr(args: ['$minImages']));
    }
    
    if (latitude == null || longitude == null) errors.add(AppLocalizations.locationRequired.tr());
    
    if (errors.isNotEmpty) {
      _setError(errors.join(', '));
      return false;
    }
    
    _setError(null);
    return true;
  }

  // Updated method to handle category ID and name
  void updateItemDetails({
    String? itemTitle,
    String? category,
    String? categoryName,
    String? condition,
    String? description,
    String? brand,
    String? dimensions,
    String? color,
  }) {
    this.itemTitle = itemTitle ?? this.itemTitle;
    this.category = category ?? this.category;
    this.categoryName = categoryName ?? this.categoryName;
    this.condition = condition ?? this.condition;
    this.description = description ?? this.description;
    this.brand = brand ?? this.brand;
    this.dimensions = dimensions ?? this.dimensions;
    this.color = color ?? this.color;
    _setError(null);
    notifyListeners();
  }

  // Update pricing and shipping
  void updatePricingShipping({
    double? price,
    bool? allowPriceNegotiation,
    String? shippingOption,
  }) {
    this.price = price ?? this.price;
    this.allowPriceNegotiation = allowPriceNegotiation ?? this.allowPriceNegotiation;
    this.shippingOption = shippingOption ?? this.shippingOption;
    _setError(null);
    notifyListeners();
  }

  // Update location
  void updateLocation({
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? cityId,        // ADD
    String? cityName,      // ADD
    String? districtId,    // ADD
    String? districtName,  // ADD
  }) {
    this.latitude = latitude;
    this.longitude = longitude;
    this.locationAddress = locationAddress;
    this.selectedCityId = cityId;           // ADD
    this.selectedCityName = cityName;       // ADD
    this.selectedDistrictId = districtId;   // ADD
    this.selectedDistrictName = districtName; // ADD
    notifyListeners();
  }
  Future<void> selectCityDistrict(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CityDistrictSelectionPage(),
      ),
    );

    if (result != null) {
      updateLocation(
        cityId: result['cityId'],
        cityName: result['cityName'],
        districtId: result['districtId'],
        districtName: result['districtName'],
        locationAddress: result['fullAddress'],
        latitude: latitude, // Keep existing coordinates
        longitude: longitude,
      );
    }
  }

  // Get category name from ID (helper method)
  Future<String?> getCategoryNameFromId(String categoryId) async {
    try {
      final doc = await _firestore.collection('categories').doc(categoryId).get();
      if (doc.exists) {
        return doc.data()?['name'];
      }
    } catch (e) {
      developer.log('Error getting category name: $e');
    }
    return null;
  }

  // ENHANCED: Validate image before adding with dynamic limits
  Future<bool> _validateImage(XFile image) async {
    try {
      final file = File(image.path);
      
      // Check if file exists
      if (!await file.exists()) {
        _setError(AppLocalizations.selectedFileNotExist.tr());
        return false;
      }

      // Check file size with dynamic limit
      final sizeInBytes = await file.length();
      final sizeInMB = sizeInBytes / (1024 * 1024);
      
      if (sizeInMB > maxImageSizeMB) {
        _setError('Image size should be less than ${maxImageSizeMB}MB for this category');
        return false;
      }

      // Check file type with dynamic allowed types
      final extension = image.path.split('.').last.toLowerCase();
      if (!allowedImageTypes.contains(extension)) {
        _setError('Only ${allowedImageTypes.join(', ')} files are allowed');
        return false;
      }

      return true;
    } catch (e) {
      _setError('Error validating image: $e');
      return false;
    }
  }

  // ENHANCED: Add image with dynamic validation
  Future<bool> addImage(XFile image) async {
    if (images.length >= maxImages) {
      _setError('Maximum $maxImages images allowed for this category');
      return false;
    }

    if (await _validateImage(image)) {
      images.add(image);
      _setError(null);
      notifyListeners();
      return true;
    }
    return false;
  }

  // Remove image
  void removeImage(int index) {
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
      _setError(null);
      notifyListeners();
    }
  }

  // Get user's current location
  Future<bool> fetchUserLocation(BuildContext context) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      // Use cached location if available
      if (user?.latitude != null && user?.longitude != null) {
        latitude = user!.latitude;
        longitude = user.longitude;
        locationAddress = user.locationAddress ?? AppLocalizations.userLocation.tr();
        notifyListeners();
        return true;
      }

      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled. Please enable them in settings.');
        return false;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permission denied. Please grant permission to continue.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Location permissions are permanently denied. Please enable them in app settings.');
        return false;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      latitude = position.latitude;
      longitude = position.longitude;
              locationAddress = AppLocalizations.currentLocation.tr();

      // Update user's location in provider
      await userProvider.updateUserLocation(
        position.latitude,
        position.longitude,
        AppLocalizations.currentLocation.tr(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to get location: ${e.toString()}');
      return false;
    }
  }

  // Test network connectivity
  Future<bool> _testNetworkConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Network connectivity test failed: $e');
      return false;
    }
  }

  // ENHANCED: Alternative upload method with better compression for real estate
  Future<String?> _uploadImageAlternative(XFile image, String itemId, String fileName) async {
    try {
      developer.log('Using alternative upload method for: $fileName');
      
      // Read and potentially compress image
      final bytes = await _processImageForUpload(image);
      developer.log('Processed ${bytes.length} bytes from image');
      
      // Create reference
      final ref = _storage.ref().child('items/$itemId/$fileName');
      
      // Upload using putData instead of putFile
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'itemId': itemId,
            'originalName': fileName,
            'category': categoryName ?? 'unknown',
          },
        ),
      );
      
      // Wait for completion with timeout
      final snapshot = await uploadTask.timeout(
        Duration(minutes: isRealEstateCategory ? 5 : 2), // Longer timeout for real estate
        onTimeout: () => throw Exception(AppLocalizations.uploadTimeout.tr()),
      );
      
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        developer.log('Alternative upload successful: $fileName');
        return downloadUrl;
      } else {
        throw Exception('Upload task failed with state: ${snapshot.state}');
      }
      
    } catch (e) {
      developer.log('Alternative upload failed for $fileName: $e');
      return null;
    }
  }

  // ENHANCED: Process image for upload with smart compression
  Future<Uint8List> _processImageForUpload(XFile image) async {
    final bytes = await image.readAsBytes();
    
    // For real estate, use higher quality compression
    if (isRealEstateCategory) {
      return await _compressImage(bytes, quality: 90);
    }
    
    // For regular items, use standard compression
    return await _compressImage(bytes, quality: 85);
  }

  // ENHANCED: Smart image compression
  Future<Uint8List> _compressImage(Uint8List bytes, {int quality = 85}) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      // Calculate target size
      int targetWidth = image.width;
      int targetHeight = image.height;
      
      // Resize if too large
      const maxDimension = 1920;
      if (image.width > maxDimension || image.height > maxDimension) {
        final aspectRatio = image.width / image.height;
        if (image.width > image.height) {
          targetWidth = maxDimension;
          targetHeight = (maxDimension / aspectRatio).round();
        } else {
          targetHeight = maxDimension;
          targetWidth = (maxDimension * aspectRatio).round();
        }
      }
      
      // Create recorder for drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw resized image
      final paint = Paint()..filterQuality = FilterQuality.high;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        paint,
      );
      
      // Convert to image
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(targetWidth, targetHeight);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData!.buffer.asUint8List();
    } catch (e) {
      developer.log('Image compression failed: $e');
      return bytes; // Return original if compression fails
    }
  }

  // ENHANCED: Enhanced upload with multiple strategies and better progress tracking
  Future<String?> _uploadSingleImageWithStrategies(XFile image, String itemId, String fileName, int attemptNumber) async {
    try {
      developer.log('Upload attempt $attemptNumber for: $fileName (Category: $categoryName)');
      
      // Strategy 1: Traditional putFile (attempts 1-2)
      if (attemptNumber <= 2) {
        try {
          developer.log('Using putFile strategy');
          final file = File(image.path);
          final ref = _storage.ref().child('items/$itemId/$fileName');
          
          final uploadTask = ref.putFile(
            file,
            SettableMetadata(
              contentType: 'image/jpeg',
              cacheControl: 'public, max-age=3600',
              customMetadata: {
                'category': categoryName ?? 'unknown',
                'isRealEstate': isRealEstateCategory.toString(),
              },
            ),
          );
          
          final snapshot = await uploadTask.timeout(
            Duration(seconds: isRealEstateCategory ? 60 : 30), // Longer timeout for real estate
            onTimeout: () => throw Exception(AppLocalizations.uploadTimeout.tr()),
          );
          
          if (snapshot.state == TaskState.success) {
            final downloadUrl = await ref.getDownloadURL();
            return downloadUrl;
          }
        } catch (e) {
          developer.log('putFile strategy failed: $e');
          if (attemptNumber < 2) {
            await Future.delayed(Duration(seconds: attemptNumber * 2));
            return await _uploadSingleImageWithStrategies(image, itemId, fileName, attemptNumber + 1);
          }
        }
      }
      
      // Strategy 2: Alternative putData method (attempts 3-4)
      if (attemptNumber <= 4) {
        developer.log('Switching to putData strategy');
        final result = await _uploadImageAlternative(image, itemId, fileName);
        if (result != null) {
          return result;
        }
        
        if (attemptNumber < 4) {
          await Future.delayed(Duration(seconds: attemptNumber * 2));
          return await _uploadSingleImageWithStrategies(image, itemId, fileName, attemptNumber + 1);
        }
      }
      
      throw Exception('All upload strategies failed after $attemptNumber attempts');
      
    } catch (e) {
      developer.log('Upload attempt $attemptNumber failed: $e');
      return null;
    }
  }

  // ENHANCED: Main upload function with batch processing for real estate
  Future<bool> uploadImages(String itemId) async {
    try {
      _setUploading(true);
      _setUploadProgress(0.0);
      imageUrls.clear();

      developer.log('Starting upload process for ${images.length} images (Category: $categoryName)');

      // Test network connectivity first
      final hasNetwork = await _testNetworkConnectivity();
      if (!hasNetwork) {
        throw Exception('No internet connection. Please check your network and try again.');
      }

      // Process images in batches for real estate to avoid memory issues
      const batchSize = 5;
      int currentBatch = 0;
      
      for (int i = 0; i < images.length; i += batchSize) {
        final batchEnd = (i + batchSize).clamp(0, images.length);
        final batch = images.sublist(i, batchEnd);
        currentBatch++;
        
        developer.log('Processing batch $currentBatch/${((images.length / batchSize).ceil())}');
        
        // Process batch concurrently but with controlled parallelism
        final futures = batch.asMap().entries.map((entry) async {
          final index = i + entry.key;
          final image = entry.value;
          
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final extension = image.path.split('.').last.toLowerCase();
          final fileName = 'image_${timestamp}_${index + 1}.$extension';
          
          developer.log('Processing image ${index + 1}/${images.length}: $fileName');
          
          try {
            final downloadUrl = await _uploadSingleImageWithStrategies(image, itemId, fileName, 1);
            
            if (downloadUrl != null) {
              developer.log('Successfully uploaded image ${index + 1}');
              return downloadUrl;
            } else {
              throw Exception('Failed to upload image ${index + 1} after all retry attempts');
            }
          } catch (e) {
            developer.log('Failed to upload image ${index + 1}: $e');
            throw Exception('Upload failed for image ${index + 1}: $e');
          }
        });
        
        // Wait for batch completion
        final batchResults = await Future.wait(futures);
        imageUrls.addAll(batchResults);
        
        // Update progress
        final progress = (i + batch.length) / images.length;
        _setUploadProgress(progress);
        
        // Small delay between batches for real estate
        if (isRealEstateCategory && batchEnd < images.length) {
          await Future.delayed(const Duration(milliseconds: 1000));
        } else if (batchEnd < images.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      _setUploading(false);
      _setUploadProgress(1.0);
      developer.log('All images uploaded successfully');
      return true;

    } catch (e) {
      _setUploading(false);
      _setError('Upload failed: $e');
      developer.log('Upload process failed: $e');
      return false;
    }
  }

  // ENHANCED: Enhanced publish item method with category-specific metadata
  Future<bool> publishItem(BuildContext context) async {
    try {
      _setPublishing(true);
      _setError(null);

      developer.log('Starting publish process for category: $categoryName...');

      // Validate form data first
      if (!_validateFormData()) {
        _setPublishing(false);
        return false;
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        _setError('Please login to continue');
        _setPublishing(false);
        return false;
      }

      // Ensure location is available
      if (latitude == null || longitude == null) {
        developer.log('Fetching user location...');
        final locationSuccess = await fetchUserLocation(context);
        if (!locationSuccess) {
          _setPublishing(false);
          return false;
        }
      }

      // Get category name if not already set
      if (categoryName == null && category.isNotEmpty) {
        categoryName = await getCategoryNameFromId(category);
      }

      // Generate item ID and upload images
      final itemId = const Uuid().v4();
      developer.log('Generated item ID: $itemId');
      
      final uploadSuccess = await uploadImages(itemId);
      
      if (!uploadSuccess) {
        _setPublishing(false);
        return false;
      }

      developer.log('Creating Firestore document...');

      // ENHANCED: Create item document with category-specific fields
      Map<String, dynamic> itemData = {
        'itemId': itemId,
        'sellerId': user.uid,
        'sellerName': user.type == 'company' ? user.companyName : AppLocalizations.individualSeller.tr(),
        'sellerType': user.type,
        'itemTitle': itemTitle.trim(),
        'category': category, // Store category ID
        'categoryName': categoryName, // Store category name for display
        'condition': condition,
        'description': description.trim(),
        'brand': brand.trim(),
        'dimensions': dimensions.trim(),
        'color': color.trim(),
        'price': price,
        'allowPriceNegotiation': allowPriceNegotiation,
        'shippingOption': shippingOption,
        'imageUrls': imageUrls,
        'latitude': latitude,
        'longitude': longitude,
        'locationAddress': locationAddress,
        'cityId': selectedCityId,
        'cityName': selectedCityName,
        'districtId': selectedDistrictId,
        'districtName': selectedDistrictName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'views': 0,
        'likes': 0,
        'viewCount': 0,
        'favoriteCount': 0,
        'isFeatured': false,
        'isPromoted': false,
        'isRealEstate': isRealEstateCategory,
        'photoCount': imageUrls.length,
        
        // NEW: Add category-specific fields
        'categorySpecificFields': _categorySpecificFields,
        'categoryFieldTemplate': _categoryFieldTemplate,
        'categoryTemplateName': _categoryTemplateName,
        'hasCustomFields': _categorySpecificFields.isNotEmpty,
      };

      // Add real estate specific fields
      if (isRealEstateCategory) {
        itemData.addAll({
          'propertyType': _extractPropertyType(),
          'hasMultiplePhotos': imageUrls.length >= 10,
          'isPremiumListing': imageUrls.length >= 15,
        });
      }

      await _firestore.collection('items').doc(itemId).set(itemData);
      await SavedSearchService.checkSavedSearchesForNewItem({
        'id': itemId,
        ...itemData,
      });

      developer.log('Item published successfully with ${_categorySpecificFields.length} category-specific fields!');
      _setPublishing(false);
      resetForm();
      return true;

    } catch (e) {
      _setPublishing(false);
      _setError('Failed to publish item: $e');
      developer.log('Publish failed: $e');
      return false;
    }
  }


  // ENHANCED: Extract property type from category name
  String _extractPropertyType() {
    if (categoryName == null) return 'property';
    
    final categoryLower = categoryName!.toLowerCase();
    
    if (categoryLower.contains('house')) return 'house';
    if (categoryLower.contains('apartment')) return 'apartment';
    if (categoryLower.contains('villa')) return 'villa';
    if (categoryLower.contains('land')) return 'land';
    if (categoryLower.contains('commercial')) return 'commercial';
    if (categoryLower.contains('office')) return 'office';
    if (categoryLower.contains('shop')) return 'shop';
    if (categoryLower.contains('warehouse')) return 'warehouse';
    
    return 'property';
  }

  // Validate form using GlobalKey
  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }
  // NEW: Load existing item data for editing
Future<void> loadExistingItem(ProductModel product) async {
  try {
    // Reset form first
    resetForm();
    
    // Load basic item details
    itemTitle = product.title;
    category = product.category ?? '';
    categoryName = product.categoryName;
    condition = product.condition;
    description = product.description;
    brand = product.brand ?? '';
    dimensions = product.dimensions ?? '';
    color = product.color ?? '';
    price = product.price;
    allowPriceNegotiation = product.allowPriceNegotiation;
    shippingOption = product.shippingOption ?? 'Both';
    
    // Load location data
    latitude = product.latitude;
    longitude = product.longitude;
    locationAddress = product.locationAddress;
    selectedCityId = product.cityId;
    selectedCityName = product.cityName;
    selectedDistrictId = product.districtId;
    selectedDistrictName = product.districtName;
    
    // Load existing image URLs (for display)
    imageUrls = List<String>.from(product.imageUrls);
    
    // Load category-specific fields if available
    if (product.categorySpecificFields != null) {
      _categorySpecificFields = Map<String, dynamic>.from(product.categorySpecificFields!);
    }
    
    // Load category template if available
    if (product.categoryFieldTemplate != null) {
      _categoryFieldTemplate = List<Map<String, dynamic>>.from(product.categoryFieldTemplate!);
      _categoryTemplateName = product.categoryTemplateName;
    }
    
    developer.log('Loaded existing item data for editing: ${product.title}');
    notifyListeners();
  } catch (e) {
    developer.log('Error loading existing item data: $e');
    _setError('Failed to load item data: $e');
  }
}

}