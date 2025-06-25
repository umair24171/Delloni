// Create this as a separate file: widgets/universal_image.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class UniversalImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final BorderRadius? borderRadius;

  const UniversalImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.errorWidget,
    this.loadingWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if it's a base64 data URL
    if (imageUrl.startsWith('data:image/')) {
      return _buildBase64Image();
    } 
    // Check if it's a regular HTTP/HTTPS URL
    else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return _buildNetworkImage();
    }
    // Handle other cases or invalid URLs
    else {
      return _buildErrorWidget();
    }
  }

  Widget _buildBase64Image() {
    try {
      // Extract the base64 data from the data URL
      final base64String = imageUrl.split(',')[1];
      final bytes = base64Decode(base64String);
      
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        ),
      );
    } catch (e) {
      print('Error decoding base64 image: $e');
      return _buildErrorWidget();
    }
  }

  Widget _buildNetworkImage() {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return loadingWidget ?? _buildLoadingWidget();
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return _buildErrorWidget();
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      child: errorWidget ?? 
        Center(
          child: Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey[400],
          ),
        ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      child: loadingWidget ?? 
        Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
        ),
    );
  }
}

// Extension to check image URL type
extension ImageUrlExtension on String {
  bool get isBase64DataUrl => startsWith('data:image/');
  bool get isNetworkUrl => startsWith('http://') || startsWith('https://');
  bool get isValidImageUrl => isBase64DataUrl || isNetworkUrl;
}

// Enhanced version with caching and better performance
class CachedUniversalImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final BorderRadius? borderRadius;
  final Duration cacheDuration;

  const CachedUniversalImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.errorWidget,
    this.loadingWidget,
    this.borderRadius,
    this.cacheDuration = const Duration(hours: 1),
  }) : super(key: key);

  @override
  _CachedUniversalImageState createState() => _CachedUniversalImageState();
}

class _CachedUniversalImageState extends State<CachedUniversalImage> {
  static final Map<String, Uint8List> _imageCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  Uint8List? _cachedBytes;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedUniversalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    // Check cache first
    if (_imageCache.containsKey(widget.imageUrl)) {
      final cacheTime = _cacheTimestamps[widget.imageUrl];
      if (cacheTime != null && 
          DateTime.now().difference(cacheTime) < widget.cacheDuration) {
        setState(() {
          _cachedBytes = _imageCache[widget.imageUrl];
          _isLoading = false;
          _hasError = false;
        });
        return;
      } else {
        // Remove expired cache
        _imageCache.remove(widget.imageUrl);
        _cacheTimestamps.remove(widget.imageUrl);
      }
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      Uint8List? bytes;

      if (widget.imageUrl.isBase64DataUrl) {
        // Handle base64 data URL
        final base64String = widget.imageUrl.split(',')[1];
        bytes = base64Decode(base64String);
      } else if (widget.imageUrl.isNetworkUrl) {
        // For network images, we don't cache them here as Image.network handles its own caching
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        return;
      }

      if (bytes != null) {
        // Cache the decoded bytes
        _imageCache[widget.imageUrl] = bytes;
        _cacheTimestamps[widget.imageUrl] = DateTime.now();

        if (mounted) {
          setState(() {
            _cachedBytes = bytes;
            _isLoading = false;
            _hasError = false;
          });
        }
      }
    } catch (e) {
      print('Error loading image: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || (!widget.imageUrl.isValidImageUrl)) {
      return _buildErrorWidget();
    }

    if (widget.imageUrl.isNetworkUrl) {
      return _buildNetworkImage();
    }

    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_cachedBytes != null) {
      return _buildMemoryImage(_cachedBytes!);
    }

    return _buildLoadingWidget();
  }

  Widget _buildMemoryImage(Uint8List bytes) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Image.memory(
        bytes,
        width: widget.width,
        height: widget.height,
        fit: widget.fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      ),
    );
  }

  Widget _buildNetworkImage() {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit ?? BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget();
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
      ),
      child: widget.errorWidget ?? 
        Center(
          child: Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey[400],
          ),
        ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
      ),
      child: widget.loadingWidget ?? 
        Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
        ),
    );
  }

  @override
  void dispose() {
    // Clean up old cache entries periodically
    _cleanupCache();
    super.dispose();
  }

  static void _cleanupCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > const Duration(hours: 2)) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _imageCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
}