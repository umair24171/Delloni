import 'dart:io';
import 'dart:typed_data';
import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
// Updated ItemProvider class - Add these changes to your existing ItemProvider

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

  // State management
  bool _isUploading = false;
  bool _isPublishing = false;
  String? _error;
  double _uploadProgress = 0.0;

  // Form controllers for validation
  final formKey = GlobalKey<FormState>();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters
  bool get isUploading => _isUploading;
  bool get isPublishing => _isPublishing;
  String? get error => _error;  
  double get uploadProgress => _uploadProgress;
  bool get canPublish => _validateFormData();

  // Constants
  static const int minImages = 2;
  static const int maxImages = 10;
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

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
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();
  }

  // Validate form data
  bool _validateFormData() {
    List<String> errors = [];
    
    if (itemTitle.trim().isEmpty) errors.add('Item title is required');
    if (itemTitle.trim().length < 10) errors.add('Title must be at least 10 characters');
    if (category.isEmpty) errors.add('Category is required');
    if (condition.isEmpty) errors.add('Condition is required');
    if (description.trim().isEmpty) errors.add('Description is required');
    
    // Check word count in description
    List<String> words = description.trim().split(RegExp(r'\s+'));
    words = words.where((word) => word.isNotEmpty).toList();
    if (words.length < 10) errors.add('Description must contain at least 10 words');
    
    if (price <= 0) errors.add('Price must be greater than 0');
    if (images.length < minImages) errors.add('At least $minImages images are required');
    if (latitude == null || longitude == null) errors.add('Location is required');
    
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
  }) {
    this.latitude = latitude;
    this.longitude = longitude;
    this.locationAddress = locationAddress;
    notifyListeners();
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

  // Validate image before adding
  Future<bool> _validateImage(XFile image) async {
    try {
      final file = File(image.path);
      
      // Check if file exists
      if (!await file.exists()) {
        _setError('Selected file does not exist');
        return false;
      }

      // Check file size
      final sizeInBytes = await file.length();
      final sizeInMB = sizeInBytes / (1024 * 1024);
      
      if (sizeInMB > maxImageSizeMB) {
        _setError('Image size should be less than ${maxImageSizeMB}MB');
        return false;
      }

      // Check file type
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

  // Add image with validation
  Future<bool> addImage(XFile image) async {
    if (images.length >= maxImages) {
      _setError('Maximum $maxImages images allowed');
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
        locationAddress = user.locationAddress ?? 'User Location';
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
      locationAddress = 'Current Location';

      // Update user's location in provider
      await userProvider.updateUserLocation(
        position.latitude,
        position.longitude,
        'Current Location',
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

  // Alternative upload method using putData instead of putFile
  Future<String?> _uploadImageAlternative(XFile image, String itemId, String fileName) async {
    try {
      developer.log('Using alternative upload method for: $fileName');
      
      // Read file as bytes
      final bytes = await image.readAsBytes();
      developer.log('Read ${bytes.length} bytes from image');
      
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
          },
        ),
      );
      
      // Wait for completion with timeout
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw Exception('Upload timeout'),
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

  // Enhanced upload with multiple strategies
  Future<String?> _uploadSingleImageWithStrategies(XFile image, String itemId, String fileName, int attemptNumber) async {
    try {
      developer.log('Upload attempt $attemptNumber for: $fileName');
      
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
            ),
          );
          
          final snapshot = await uploadTask.timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Upload timeout'),
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

  // Main upload function with enhanced error handling
  Future<bool> uploadImages(String itemId) async {
    try {
      _setUploading(true);
      _setUploadProgress(0.0);
      imageUrls.clear();

      developer.log('Starting upload process for ${images.length} images');

      // Test network connectivity first
      final hasNetwork = await _testNetworkConnectivity();
      if (!hasNetwork) {
        throw Exception('No internet connection. Please check your network and try again.');
      }

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        
        // Generate safe filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = image.path.split('.').last.toLowerCase();
        final fileName = 'image_${timestamp}_${i + 1}.$extension';
        
        developer.log('Processing image ${i + 1}/${images.length}: $fileName');
        
        try {
          final downloadUrl = await _uploadSingleImageWithStrategies(image, itemId, fileName, 1);
          
          if (downloadUrl != null) {
            imageUrls.add(downloadUrl);
            developer.log('Successfully uploaded image ${i + 1}');
            
            // Update progress
            final progress = (i + 1) / images.length;
            _setUploadProgress(progress);
          } else {
            throw Exception('Failed to upload image ${i + 1} after all retry attempts');
          }
          
        } catch (e) {
          developer.log('Failed to upload image ${i + 1}: $e');
          throw Exception('Upload failed for image ${i + 1}: $e');
        }
        
        // Small delay between uploads
        if (i < images.length - 1) {
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

  // Enhanced publish item method with category name resolution
  Future<bool> publishItem(BuildContext context) async {
    try {
      _setPublishing(true);
      _setError(null);

      developer.log('Starting publish process...');

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

      // Create item document with both category ID and name
      await _firestore.collection('items').doc(itemId).set({
        'itemId': itemId,
        'sellerId': user.uid,
        'sellerName': user.type == 'company' ? user.companyName : 'Individual Seller',
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
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'views': 0,
        'likes': 0,
        'viewCount': 0,
        'favoriteCount': 0,
        'isFeatured': false,
        'isPromoted': false,
      });

      developer.log('Item published successfully!');
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

  // Validate form using GlobalKey
  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }
}