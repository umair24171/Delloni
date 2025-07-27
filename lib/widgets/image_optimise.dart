import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class UniversalImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final BorderRadius? borderRadius;
  final Duration cacheDuration;
  final bool highQuality; // NEW: Quality control flag

  const UniversalImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.errorWidget,
    this.loadingWidget,
    this.borderRadius,
    this.cacheDuration = const Duration(hours: 24),
    this.highQuality = true, // NEW: Default to high quality
  }) : super(key: key);

  @override
  _UniversalImageState createState() => _UniversalImageState();
}

class _UniversalImageState extends State<UniversalImage> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  // Static cache for base64 images
  static final Map<String, Uint8List> _base64Cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // State variables
  Uint8List? _cachedBytes;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  @override
  void didUpdateWidget(UniversalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl && widget.imageUrl.isNotEmpty) {
      _initializeImage();
    }
  }

  Future<void> _initializeImage() async {
    if (_isInitialized && _cachedBytes != null) return;
    
    if (widget.imageUrl.isEmpty || !widget.imageUrl.isValidImageUrl) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isInitialized = true;
      });
      return;
    }

    if (widget.imageUrl.isNetworkUrl) {
      setState(() {
        _isLoading = false;
        _hasError = false;
        _isInitialized = true;
      });
      return;
    }

    if (widget.imageUrl.isBase64DataUrl) {
      await _processBase64Image();
    }
  }

  Future<void> _processBase64Image() async {
    // Check cache first
    if (_base64Cache.containsKey(widget.imageUrl)) {
      final cacheTime = _cacheTimestamps[widget.imageUrl];
      if (cacheTime != null && 
          DateTime.now().difference(cacheTime) < widget.cacheDuration) {
        setState(() {
          _cachedBytes = _base64Cache[widget.imageUrl];
          _isLoading = false;
          _hasError = false;
          _isInitialized = true;
        });
        return;
      } else {
        _base64Cache.remove(widget.imageUrl);
        _cacheTimestamps.remove(widget.imageUrl);
      }
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final base64String = widget.imageUrl.split(',')[1];
      final bytes = base64Decode(base64String);
      
      // Cache the result
      _base64Cache[widget.imageUrl] = bytes;
      _cacheTimestamps[widget.imageUrl] = DateTime.now();

      if (mounted) {
        setState(() {
          _cachedBytes = bytes;
          _isLoading = false;
          _hasError = false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error processing base64 image: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_hasError || !widget.imageUrl.isValidImageUrl) {
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

  Widget _buildNetworkImage() {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit ?? BoxFit.cover,
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
        
        // FIXED: Only set cache dimensions for high quality mode and avoid memory issues
        memCacheWidth: widget.highQuality ? null : _getSafeMemoryCacheSize(widget.width),
        memCacheHeight: widget.highQuality ? null : _getSafeMemoryCacheSize(widget.height),
        
        // IMPROVED: Better cache configuration for quality
        cacheManager: widget.highQuality ? _getHighQualityCacheManager() : _getStandardCacheManager(),
        
        // IMPROVED: Better fade transitions
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 200),
        
        // IMPROVED: Filter quality for better rendering
        filterQuality: widget.highQuality ? FilterQuality.high : FilterQuality.medium,
      ),
    );
  }

  // IMPROVED: Better cache size calculation
  int? _getSafeMemoryCacheSize(double? value) {
    if (value == null || value.isInfinite || value.isNaN) {
      return null;
    }
    
    // Cap the cache size to prevent memory issues while maintaining quality
    final intValue = value.toInt();
    if (intValue > 1000) {
      return 1000; // Max cache size
    }
    if (intValue < 100) {
      return null; // Let system decide for small images
    }
    return intValue;
  }

  // IMPROVED: High quality cache manager
  CacheManager _getHighQualityCacheManager() {
    return CacheManager(
      Config(
        'high_quality_image_cache',
        stalePeriod: widget.cacheDuration,
        maxNrOfCacheObjects: 200, // More cache objects
        repo: JsonCacheInfoRepository(databaseName: 'high_quality_cache'),
        fileService: HttpFileService(), // Use HTTP file service for better quality
      ),
    );
  }

  // IMPROVED: Standard cache manager
  CacheManager _getStandardCacheManager() {
    return CacheManager(
      Config(
        'standard_image_cache',
        stalePeriod: widget.cacheDuration,
        maxNrOfCacheObjects: 100,
      ),
    );
  }

  Widget _buildMemoryImage(Uint8List bytes) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Image.memory(
        bytes,
        width: widget.width,
        height: widget.height,
        fit: widget.fit ?? BoxFit.fill,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        gaplessPlayback: true,
        
        // FIXED: Remove cache dimensions for memory images to preserve quality
        // cacheWidth: _getSafeIntValue(widget.width),
        // cacheHeight: _getSafeIntValue(widget.height),
        
        // IMPROVED: Better filter quality
        filterQuality: widget.highQuality ? FilterQuality.high : FilterQuality.medium,
        
        // IMPROVED: Better scale handling
        scale: 1.0, // Maintain original scale
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
            size: _getIconSize(),
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

  // IMPROVED: Better icon size calculation
  double _getIconSize() {
    if (widget.width != null && widget.height != null) {
      final avgSize = (widget.width! + widget.height!) / 2;
      return (avgSize * 0.3).clamp(24.0, 80.0);
    }
    return 40.0;
  }

  @override
  void dispose() {
    _cleanupCache();
    super.dispose();
  }

  static void _cleanupCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > const Duration(hours: 24)) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _base64Cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  static void clearCache() {
    _base64Cache.clear();
    _cacheTimestamps.clear();
  }
}

// Extension to check image URL type
extension ImageUrlExtension on String {
  bool get isBase64DataUrl => startsWith('data:image/');
  bool get isNetworkUrl => startsWith('http://') || startsWith('https://');
  bool get isValidImageUrl => isBase64DataUrl || isNetworkUrl;
}

// IMPROVED: High quality optimized image for product cards
class ProductCardImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;

  const ProductCardImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: UniversalImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.fill,
        borderRadius: borderRadius,
        highQuality: true, // Always use high quality for product images
        errorWidget: Container(
          color: Colors.grey[200],
          child: Icon(
            Icons.image,
            size: 50,
            color: Colors.grey[400],
          ),
        ),
        loadingWidget: Container(
          color: Colors.grey[100],
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// IMPROVED: Optimized version for lists with quality control
class OptimizedUniversalImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final BorderRadius? borderRadius;
  final bool highQuality;

  const OptimizedUniversalImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.errorWidget,
    this.loadingWidget,
    this.borderRadius,
    this.highQuality = false, // Default to standard quality for lists
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!imageUrl.isValidImageUrl) {
      return _buildErrorWidget();
    }

    if (imageUrl.isNetworkUrl) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
          placeholder: (context, url) => _buildLoadingWidget(),
          errorWidget: (context, url, error) => _buildErrorWidget(),
          
          // IMPROVED: Quality-based cache sizing
          memCacheWidth: highQuality ? null : _getSafeMemoryCacheSize(width),
          memCacheHeight: highQuality ? null : _getSafeMemoryCacheSize(height),
          
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 200),
          
          // IMPROVED: Filter quality based on highQuality flag
          filterQuality: highQuality ? FilterQuality.high : FilterQuality.medium,
        ),
      );
    }

    if (imageUrl.isBase64DataUrl) {
      return _buildBase64Image();
    }

    return _buildErrorWidget();
  }

  int? _getSafeMemoryCacheSize(double? value) {
    if (value == null || value.isInfinite || value.isNaN) {
      return null;
    }
    
    final intValue = value.toInt();
    if (intValue > 800) {
      return 800;
    }
    if (intValue < 50) {
      return null;
    }
    return intValue;
  }

  Widget _buildBase64Image() {
    try {
      final base64String = imageUrl.split(',')[1];
      final bytes = base64Decode(base64String);
      
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: highQuality ? FilterQuality.high : FilterQuality.medium,
          scale: 1.0,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        ),
      );
    } catch (e) {
      return _buildErrorWidget();
    }
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
            size: _getIconSize(),
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

  double _getIconSize() {
    if (width != null && height != null) {
      final avgSize = (width! + height!) / 2;
      return (avgSize * 0.3).clamp(24.0, 80.0);
    }
    return 40.0;
  }
}

class WatermarkPreservingImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool preserveWatermark;

  const WatermarkPreservingImage({
    Key? key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.preserveWatermark = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Container(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main image with cover fit
            UniversalImage(
              imageUrl: imageUrl,
              width: width,
              height: height,
              fit: fit,
              errorWidget: Container(
                color: Colors.grey[200],
                child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
              ),
            ),
            
            // Watermark overlay (only if preserveWatermark is true)
            if (preserveWatermark)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/logo_two.jpeg',
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Delloni',
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
          ],
        ),
      ),
    );
  }
}