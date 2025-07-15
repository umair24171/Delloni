// import 'dart:io';
// import 'dart:typed_data';
// import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:uuid/uuid.dart';
// import 'package:provider/provider.dart';
// import 'package:geolocator/geolocator.dart';
// import 'dart:developer' as developer;
// import 'package:http/http.dart' as http;

// class EnhancedItemProvider with ChangeNotifier {
//   // Form data - Enhanced with category-specific handling
//   String itemTitle = '';
//   String category = ''; // This will store the category ID
//   String? categoryName; // This will store the category display name
//   String condition = '';
//   String description = '';
//   String brand = '';
//   String dimensions = '';
//   String color = '';
//   double price = 0.0;
//   bool allowPriceNegotiation = true;
//   String shippingOption = 'Both';
//   List<XFile> images = [];
//   List<String> imageUrls = [];
//   double? latitude;
//   double? longitude;
//   String? locationAddress;
  
//   // Enhanced location fields with city/district support
//   String? selectedCityId;
//   String? selectedCityName;
//   String? selectedDistrictId;
//   String? selectedDistrictName;

//   // State management
//   bool _isUploading = false;
//   bool _isPublishing = false;
//   String? _error;
//   double _uploadProgress = 0.0;

//   // Form controllers for validation
//   final formKey = GlobalKey<FormState>();

//   // Firebase instances
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   // Enhanced photo limits based on category
//   static const int defaultMinImages = 2;
//   static const int defaultMaxImages = 10;
//   static const int propertyMaxImages = 50; // Unlimited for properties (high limit)
//   static const int maxImageSizeMB = 5;
//   static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

//   // Categories that support unlimited photos
//   final List<String> unlimitedPhotoCategoris = [
//     'Property for Sale',
//     'Property for Rent', 
//     'Real Estate',
//     'Houses',
//     'Apartments',
//     'Commercial Properties',
//   ];

//   // Getters
//   bool get isUploading => _isUploading;
//   bool get isPublishing => _isPublishing;
//   String? get error => _error;  
//   double get uploadProgress => _uploadProgress;
//   bool get canPublish => _validateFormData();
  
//   // Enhanced photo limit getters
//   int get minImages => defaultMinImages;
//   int get maxImages => _isUnlimitedPhotoCategory() ? propertyMaxImages : defaultMaxImages;
//   bool get isUnlimitedPhotoCategory => _isUnlimitedPhotoCategory();

//   void _setError(String? error) {
//     _error = error;
//     developer.log('Enhanced ItemProvider Error: $error');
//     notifyListeners();
//   }

//   void _setUploading(bool uploading) {
//     _isUploading = uploading;
//     notifyListeners();
//   }

//   void _setPublishing(bool publishing) {
//     _isPublishing = publishing;
//     notifyListeners();
//   }

//   void _setUploadProgress(double progress) {
//     _uploadProgress = progress;
//     notifyListeners();
//   }

//   // Check if current category supports unlimited photos
//   bool _isUnlimitedPhotoCategory() {
//     if (categoryName == null) return false;
//     return unlimitedPhotoCategoris.any((cat) => 
//         categoryName!.toLowerCase().contains(cat.toLowerCase()) ||
//         cat.toLowerCase().contains(categoryName!.toLowerCase())
//     );
//   }

//   // Reset form data
//   void resetForm() {
//     itemTitle = '';
//     category = '';
//     categoryName = null;
//     condition = '';
//     description = '';
//     brand = '';
//     dimensions = '';
//     color = '';
//     price = 0.0;
//     allowPriceNegotiation = true;
//     shippingOption = 'Both';
//     images.clear();
//     imageUrls.clear();
//     latitude = null;
//     longitude = null;
//     locationAddress = null;
//     selectedCityId = null;
//     selectedCityName = null;
//     selectedDistrictId = null;
//     selectedDistrictName = null;
//     _error = null;
//     _uploadProgress = 0.0;
//     notifyListeners();
//   }

//   // Enhanced validation with city requirements and category-specific rules
//   bool _validateFormData() {
//     List<String> errors = [];
    
//     if (itemTitle.trim().isEmpty) errors.add('Item title is required');
//     if (itemTitle.trim().length < 10) errors.add('Title must be at least 10 characters');
//     if (category.isEmpty) errors.add('Category is required');
    
//     // Only require condition for categories that need it
//     final noConditionCategories = ['Jobs', 'Services', 'Education'];
//     if (!noConditionCategories.contains(categoryName) && condition.isEmpty) {
//       errors.add('Condition is required');
//     }
    
//     if (description.trim().isEmpty) errors.add('Description is required');
    
//     // Check word count in description
//     // List<String> words = description.trim().split(RegExp(r'\\s+'));
//     // words = words.where((word) => word.isNotEmpty).toList();
//     // if (words.length < 10) errors.add('Description must contain at least 10 words');
    
//     if (price <= 0) errors.add('Price must be greater than 0');
    
//     // Enhanced image validation based on category
//     final currentMinImages = minImages;
//     final currentMaxImages = maxImages;
    
//     if (images.length < currentMinImages) {
//       errors.add('At least $currentMinImages images are required');
//     }
//     if (images.length > currentMaxImages) {
//       errors.add('Maximum $currentMaxImages images allowed');
//     }
    
//     // City selection is mandatory
//     if (selectedCityId == null || selectedCityId!.isEmpty) {
//       errors.add('City selection is required');
//     }
    
//     if (errors.isNotEmpty) {
//       _setError(errors.join(', '));
//       return false;
//     }
    
//     _setError(null);
//     return true;
//   }

//   // Enhanced method to handle category ID and name with photo limit updates
//   void updateItemDetails({
//     String? itemTitle,
//     String? category,
//     String? categoryName,
//     String? condition,
//     String? description,
//     String? brand,
//     String? dimensions,
//     String? color,
//   }) {
//     this.itemTitle = itemTitle ?? this.itemTitle;
//     this.category = category ?? this.category;
    
//     // Update category name and check if photo limits changed
//     if (categoryName != null && categoryName != this.categoryName) {
//       this.categoryName = categoryName;
//       // Notify about photo limit change if applicable
//       if (_isUnlimitedPhotoCategory()) {
//         developer.log('Category supports unlimited photos: $categoryName');
//       }
//     }
    
//     this.condition = condition ?? this.condition;
//     this.description = description ?? this.description;
//     this.brand = brand ?? this.brand;
//     this.dimensions = dimensions ?? this.dimensions;
//     this.color = color ?? this.color;
//     _setError(null);
//     notifyListeners();
//   }

//   // Update pricing and shipping
//   void updatePricingShipping({
//     double? price,
//     bool? allowPriceNegotiation,
//     String? shippingOption,
//   }) {
//     this.price = price ?? this.price;
//     this.allowPriceNegotiation = allowPriceNegotiation ?? this.allowPriceNegotiation;
//     this.shippingOption = shippingOption ?? this.shippingOption;
//     _setError(null);
//     notifyListeners();
//   }

//   // Enhanced location update with city/district support
//   void updateLocation({
//     double? latitude,
//     double? longitude,
//     String? locationAddress,
//     String? selectedCityId,
//     String? selectedCityName,
//     String? selectedDistrictId,
//     String? selectedDistrictName,
//   }) {
//     this.latitude = latitude;
//     this.longitude = longitude;
//     this.locationAddress = locationAddress;
//     this.selectedCityId = selectedCityId;
//     this.selectedCityName = selectedCityName;
//     this.selectedDistrictId = selectedDistrictId;
//     this.selectedDistrictName = selectedDistrictName;
//     notifyListeners();
//   }

//   // Enhanced city selection methods
//   Future<List<Map<String, dynamic>>> loadCities() async {
//     try {
//       final snapshot = await _firestore
//           .collection('cities')
//           .where('isActive', isEqualTo: true)
//           .orderBy('name')
//           .get();

//       return snapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
//     } catch (e) {
//       developer.log('Error loading cities: $e');
//       return [];
//     }
//   }

//   Future<List<Map<String, dynamic>>> loadDistricts(String cityId) async {
//     try {
//       final snapshot = await _firestore
//           .collection('districts')
//           .where('cityId', isEqualTo: cityId)
//           .where('isActive', isEqualTo: true)
//           .orderBy('name')
//           .get();

//       return snapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
//     } catch (e) {
//       developer.log('Error loading districts: $e');
//       return [];
//     }
//   }

//   // Get category name from ID (helper method)
//   Future<String?> getCategoryNameFromId(String categoryId) async {
//     try {
//       final doc = await _firestore.collection('categories').doc(categoryId).get();
//       if (doc.exists) {
//         return doc.data()?['name'];
//       }
//     } catch (e) {
//       developer.log('Error getting category name: $e');
//     }
//     return null;
//   }

//   // Enhanced image validation with category-specific limits
//   Future<bool> _validateImage(XFile image) async {
//     try {
//       final file = File(image.path);
      
//       // Check if file exists
//       if (!await file.exists()) {
//         _setError('Selected file does not exist');
//         return false;
//       }

//       // Check file size
//       final sizeInBytes = await file.length();
//       final sizeInMB = sizeInBytes / (1024 * 1024);
      
//       if (sizeInMB > maxImageSizeMB) {
//         _setError('Image size should be less than ${maxImageSizeMB}MB');
//         return false;
//       }

//       // Check file type
//       final extension = image.path.split('.').last.toLowerCase();
//       if (!allowedImageTypes.contains(extension)) {
//         _setError('Only ${allowedImageTypes.join(', ')} files are allowed');
//         return false;
//       }

//       return true;
//     } catch (e) {
//       _setError('Error validating image: $e');
//       return false;
//     }
//   }

//   // Enhanced add image with dynamic limits
//   Future<bool> addImage(XFile image) async {
//     final currentMaxImages = maxImages;
    
//     if (images.length >= currentMaxImages) {
//       if (_isUnlimitedPhotoCategory()) {
//         _setError('Maximum $currentMaxImages images allowed for this category');
//       } else {
//         _setError('Maximum $currentMaxImages images allowed');
//       }
//       return false;
//     }

//     if (await _validateImage(image)) {
//       images.add(image);
//       _setError(null);
//       notifyListeners();
      
//       // Show success message for property categories when they add many photos
//       if (_isUnlimitedPhotoCategory() && images.length > defaultMaxImages) {
//         developer.log('Added image ${images.length}/$currentMaxImages for property category');
//       }
      
//       return true;
//     }
//     return false;
//   }

//   // Enhanced add multiple images for drag & drop or bulk selection
//   Future<int> addMultipleImages(List<XFile> newImages) async {
//     int successCount = 0;
//     final currentMaxImages = maxImages;
    
//     for (final image in newImages) {
//       if (images.length >= currentMaxImages) {
//         _setError('Maximum $currentMaxImages images allowed. Added $successCount images.');
//         break;
//       }
      
//       if (await _validateImage(image)) {
//         images.add(image);
//         successCount++;
//       }
//     }
    
//     if (successCount > 0) {
//       _setError(null);
//       notifyListeners();
//       developer.log('Added $successCount images. Total: ${images.length}/$currentMaxImages');
//     }
    
//     return successCount;
//   }

//   // Remove image
//   void removeImage(int index) {
//     if (index >= 0 && index < images.length) {
//       images.removeAt(index);
//       _setError(null);
//       notifyListeners();
//     }
//   }

//   // Reorder images (useful for property listings)
//   void reorderImages(int oldIndex, int newIndex) {
//     if (oldIndex < images.length && newIndex < images.length) {
//       final item = images.removeAt(oldIndex);
//       images.insert(newIndex, item);
//       notifyListeners();
//     }
//   }

//   // Enhanced user location fetching with city detection
//   Future<bool> fetchUserLocation(BuildContext context) async {
//     try {
//       final userProvider = Provider.of<UserProvider>(context, listen: false);
//       final user = userProvider.currentUser;

//       // Use cached location if available
//       if (user?.latitude != null && user?.longitude != null) {
//         latitude = user!.latitude;
//         longitude = user.longitude;
//         locationAddress = user.locationAddress ?? 'User Location';
        
//         // Try to detect city from coordinates
//         await _detectCityFromCoordinates(latitude!, longitude!);
        
//         notifyListeners();
//         return true;
//       }

//       // Check location services
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         _setError('Location services are disabled. Please enable them in settings.');
//         return false;
//       }

//       // Check permissions
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           _setError('Location permission denied. Please grant permission to continue.');
//           return false;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         _setError('Location permissions are permanently denied. Please enable them in app settings.');
//         return false;
//       }

//       // Get current position
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 10),
//       );

//       latitude = position.latitude;
//       longitude = position.longitude;
//       locationAddress = 'Current Location';

//       // Try to detect city from coordinates
//       await _detectCityFromCoordinates(latitude!, longitude!);

//       // Update user's location in provider
//       await userProvider.updateUserLocation(
//         position.latitude,
//         position.longitude,
//         'Current Location',
//       );

//       notifyListeners();
//       return true;
//     } catch (e) {
//       _setError('Failed to get location: ${e.toString()}');
//       return false;
//     }
//   }

//   // Detect city from coordinates using reverse geocoding
//   Future<void> _detectCityFromCoordinates(double lat, double lng) async {
//     try {
//       // Load cities and find closest one
//       final cities = await loadCities();
      
//       double minDistance = double.infinity;
//       Map<String, dynamic>? closestCity;
      
//       for (final city in cities) {
//         if (city['latitude'] != null && city['longitude'] != null) {
//           final distance = Geolocator.distanceBetween(
//             lat, lng,
//             city['latitude'], city['longitude'],
//           );
          
//           if (distance < minDistance) {
//             minDistance = distance;
//             closestCity = city;
//           }
//         }
//       }
      
//       // If closest city is within 50km, auto-select it
//       if (closestCity != null && minDistance < 50000) {
//         selectedCityId = closestCity['id'];
//         selectedCityName = closestCity['name'];
//         developer.log('Auto-detected city: ${selectedCityName}');
//       }
//     } catch (e) {
//       developer.log('Error detecting city from coordinates: $e');
//     }
//   }

//   // Test network connectivity
//   Future<bool> _testNetworkConnectivity() async {
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.google.com'),
//         headers: {'Connection': 'close'},
//       ).timeout(const Duration(seconds: 5));
      
//       return response.statusCode == 200;
//     } catch (e) {
//       developer.log('Network connectivity test failed: $e');
//       return false;
//     }
//   }

//   // Alternative upload method using putData instead of putFile
//   Future<String?> _uploadImageAlternative(XFile image, String itemId, String fileName) async {
//     try {
//       developer.log('Using alternative upload method for: $fileName');
      
//       // Read file as bytes
//       final bytes = await image.readAsBytes();
//       developer.log('Read ${bytes.length} bytes from image');
      
//       // Create reference
//       final ref = _storage.ref().child('items/$itemId/$fileName');
      
//       // Upload using putData instead of putFile
//       final uploadTask = ref.putData(
//         bytes,
//         SettableMetadata(
//           contentType: 'image/jpeg',
//           customMetadata: {
//             'itemId': itemId,
//             'originalName': fileName,
//             'categoryName': categoryName ?? 'unknown',
//             'imageCount': images.length.toString(),
//           },
//         ),
//       );
      
//       // Wait for completion with timeout
//       final snapshot = await uploadTask.timeout(
//         const Duration(minutes: 3), // Increased timeout for property images
//         onTimeout: () => throw Exception('Upload timeout'),
//       );
      
//       if (snapshot.state == TaskState.success) {
//         final downloadUrl = await ref.getDownloadURL();
//         developer.log('Alternative upload successful: $fileName');
//         return downloadUrl;
//       } else {
//         throw Exception('Upload task failed with state: ${snapshot.state}');
//       }
      
//     } catch (e) {
//       developer.log('Alternative upload failed for $fileName: $e');
//       return null;
//     }
//   }

//   // Enhanced upload with multiple strategies and property-specific handling
//   Future<String?> _uploadSingleImageWithStrategies(XFile image, String itemId, String fileName, int attemptNumber) async {
//     try {
//       developer.log('Upload attempt $attemptNumber for: $fileName (Category: $categoryName)');
      
//       // Strategy 1: Traditional putFile (attempts 1-2)
//       if (attemptNumber <= 2) {
//         try {
//           developer.log('Using putFile strategy');
//           final file = File(image.path);
//           final ref = _storage.ref().child('items/$itemId/$fileName');
          
//           final uploadTask = ref.putFile(
//             file,
//             SettableMetadata(
//               contentType: 'image/jpeg',
//               cacheControl: 'public, max-age=3600',
//               customMetadata: {
//                 'categoryName': categoryName ?? 'unknown',
//                 'isPropertyCategory': _isUnlimitedPhotoCategory().toString(),
//               },
//             ),
//           );
          
//           final snapshot = await uploadTask.timeout(
//             Duration(seconds: _isUnlimitedPhotoCategory() ? 60 : 30), // Longer timeout for properties
//             onTimeout: () => throw Exception('Upload timeout'),
//           );
          
//           if (snapshot.state == TaskState.success) {
//             final downloadUrl = await ref.getDownloadURL();
//             return downloadUrl;
//           }
//         } catch (e) {
//           developer.log('putFile strategy failed: $e');
//           if (attemptNumber < 2) {
//             await Future.delayed(Duration(seconds: attemptNumber * 2));
//             return await _uploadSingleImageWithStrategies(image, itemId, fileName, attemptNumber + 1);
//           }
//         }
//       }
      
//       // Strategy 2: Alternative putData method (attempts 3-4)
//       if (attemptNumber <= 4) {
//         developer.log('Switching to putData strategy');
//         final result = await _uploadImageAlternative(image, itemId, fileName);
//         if (result != null) {
//           return result;
//         }
        
//         if (attemptNumber < 4) {
//           await Future.delayed(Duration(seconds: attemptNumber * 2));
//           return await _uploadSingleImageWithStrategies(image, itemId, fileName, attemptNumber + 1);
//         }
//       }
      
//       throw Exception('All upload strategies failed after $attemptNumber attempts');
      
//     } catch (e) {
//       developer.log('Upload attempt $attemptNumber failed: $e');
//       return null;
//     }
//   }

//   // Enhanced upload function with property-specific handling
//   Future<bool> uploadImages(String itemId) async {
//     try {
//       _setUploading(true);
//       _setUploadProgress(0.0);
//       imageUrls.clear();

//       developer.log('Starting upload process for ${images.length} images (Category: $categoryName)');

//       // Test network connectivity first
//       final hasNetwork = await _testNetworkConnectivity();
//       if (!hasNetwork) {
//         throw Exception('No internet connection. Please check your network and try again.');
//       }

//       // Enhanced progress tracking for large image sets
//       for (int i = 0; i < images.length; i++) {
//         final image = images[i];
        
//         // Generate safe filename with category info
//         final timestamp = DateTime.now().millisecondsSinceEpoch;
//         final extension = image.path.split('.').last.toLowerCase();
//         final categoryPrefix = _isUnlimitedPhotoCategory() ? 'property' : 'item';
//         final fileName = '${categoryPrefix}_${timestamp}_${i + 1}.$extension';
        
//         developer.log('Processing image ${i + 1}/${images.length}: $fileName');
        
//         try {
//           final downloadUrl = await _uploadSingleImageWithStrategies(image, itemId, fileName, 1);
          
//           if (downloadUrl != null) {
//             imageUrls.add(downloadUrl);
//             developer.log('Successfully uploaded image ${i + 1}');
            
//             // Update progress more frequently for property categories
//             final progress = (i + 1) / images.length;
//             _setUploadProgress(progress);
            
//             // Show intermediate progress for large uploads
//             if (_isUnlimitedPhotoCategory() && images.length > 10 && (i + 1) % 5 == 0) {
//               developer.log('Property upload progress: ${i + 1}/${images.length} images completed');
//             }
//           } else {
//             throw Exception('Failed to upload image ${i + 1} after all retry attempts');
//           }
          
//         } catch (e) {
//           developer.log('Failed to upload image ${i + 1}: $e');
//           throw Exception('Upload failed for image ${i + 1}: $e');
//         }
        
//         // Shorter delay for property uploads to speed up the process
//         if (i < images.length - 1) {
//           await Future.delayed(Duration(milliseconds: _isUnlimitedPhotoCategory() ? 200 : 500));
//         }
//       }

//       _setUploading(false);
//       _setUploadProgress(1.0);
//       developer.log('All ${images.length} images uploaded successfully for $categoryName category');
//       return true;

//     } catch (e) {
//       _setUploading(false);
//       _setError('Upload failed: $e');
//       developer.log('Upload process failed: $e');
//       return false;
//     }
//   }

//   // Enhanced publish item method with city/district and category-specific handling
//   Future<bool> publishItem(BuildContext context) async {
//     try {
//       _setPublishing(true);
//       _setError(null);

//       developer.log('Starting publish process for $categoryName...');

//       // Validate form data first
//       if (!_validateFormData()) {
//         _setPublishing(false);
//         return false;
//       }

//       final userProvider = Provider.of<UserProvider>(context, listen: false);
//       final user = userProvider.currentUser;

//       if (user == null) {
//         _setError('Please login to continue');
//         _setPublishing(false);
//         return false;
//       }

//       // Ensure location and city are available
//       if (latitude == null || longitude == null) {
//         developer.log('Fetching user location...');
//         final locationSuccess = await fetchUserLocation(context);
//         if (!locationSuccess) {
//           _setPublishing(false);
//           return false;
//         }
//       }

//       // Ensure city is selected
//       if (selectedCityId == null) {
//         _setError('Please select a city for your listing');
//         _setPublishing(false);
//         return false;
//       }

//       // Get category name if not already set
//       if (categoryName == null && category.isNotEmpty) {
//         categoryName = await getCategoryNameFromId(category);
//       }

//       // Generate item ID and upload images
//       final itemId = const Uuid().v4();
//       developer.log('Generated item ID: $itemId');
      
//       final uploadSuccess = await uploadImages(itemId);
      
//       if (!uploadSuccess) {
//         _setPublishing(false);
//         return false;
//       }

//       developer.log('Creating Firestore document with enhanced location data...');

//       // Create enhanced item document with city/district and category-specific fields
//       final itemData = {
//         'itemId': itemId,
//         'sellerId': user.uid,
//         'sellerName': user.type == 'company' ? user.companyName : 'Individual Seller',
//         'sellerType': user.type,
//         'itemTitle': itemTitle.trim(),
//         'category': category, // Store category ID
//         'categoryName': categoryName, // Store category name for display
//         'condition': condition,
//         'description': description.trim(),
//         'brand': brand.trim(),
//         'dimensions': dimensions.trim(),
//         'color': color.trim(),
//         'price': price,
//         'allowPriceNegotiation': allowPriceNegotiation,
//         'shippingOption': shippingOption,
//         'imageUrls': imageUrls,
//         'latitude': latitude,
//         'longitude': longitude,
//         'locationAddress': locationAddress,
        
//         // Enhanced location fields
//         'cityId': selectedCityId,
//         'cityName': selectedCityName,
//         'districtId': selectedDistrictId,
//         'districtName': selectedDistrictName,
        
//         // Category-specific metadata
//         'isPropertyListing': _isUnlimitedPhotoCategory(),
//         'imageCount': imageUrls.length,
//         'hasUnlimitedPhotos': _isUnlimitedPhotoCategory(),
        
//         // Standard fields
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//         'status': 'active',
//         'views': 0,
//         'likes': 0,
//         'viewCount': 0,
//         'favoriteCount': 0,
//         'isFeatured': false,
//         'isPromoted': false,
//       };

//       await _firestore.collection('items').doc(itemId).set(itemData);

//       developer.log('Item published successfully with ${imageUrls.length} images!');
//       _setPublishing(false);
//       resetForm();
//       return true;

//     } catch (e) {
//       _setPublishing(false);
//       _setError('Failed to publish item: $e');
//       developer.log('Publish failed: $e');
//       return false;
//     }
//   }

//   // Validate form using GlobalKey
//   bool validateForm() {
//     return formKey.currentState?.validate() ?? false;
//   }

//   // Get photo limit info for UI display
//   String getPhotoLimitInfo() {
//     if (_isUnlimitedPhotoCategory()) {
//       return 'Property listings support up to $propertyMaxImages photos';
//     } else {
//       return 'Standard listings support up to $defaultMaxImages photos';
//     }
//   }

//   // Check if more photos can be added
//   bool canAddMorePhotos() {
//     return images.length < maxImages;
//   }

//   // Get remaining photo slots
//   int getRemainingPhotoSlots() {
//     return maxImages - images.length;
//   }
// }