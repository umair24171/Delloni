import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'dart:async';

// Extension to check image URL type
extension ImageUrlExtension on String {
  bool get isBase64DataUrl => startsWith('data:image/');
  bool get isNetworkUrl => startsWith('http://') || startsWith('https://');
  bool get isValidImageUrl => isBase64DataUrl || isNetworkUrl;
}

class UniversalImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final BorderRadius? borderRadius;
  final Duration cacheDuration;
  final bool highQuality;

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
    this.highQuality = true,
  }) : super(key: key);

  @override
  _UniversalImageState createState() => _UniversalImageState();
}

class _UniversalImageState extends State<UniversalImage> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  // IMPROVED: Limited cache with cleanup
  static final Map<String, Uint8List> _base64Cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const int _maxCacheSize = 30; // Reduced cache size
  
  Uint8List? _cachedBytes;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isInitialized = false;
  int _retryCount = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  @override
  void didUpdateWidget(UniversalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl && widget.imageUrl.isNotEmpty) {
      _resetState();
      _initializeImage();
    }
  }

  void _resetState() {
    _retryTimer?.cancel();
    _retryCount = 0;
    _cachedBytes = null;
    _isLoading = false;
    _hasError = false;
    _isInitialized = false;
  }

  Future<void> _initializeImage() async {
    if (_isInitialized && _cachedBytes != null) return;
    
    // IMPROVED: Better validation
    if (widget.imageUrl.isEmpty || !_isValidUrl(widget.imageUrl)) {
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

  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    
    if (url.isNetworkUrl) {
      try {
        final uri = Uri.parse(url);
        return uri.hasScheme && uri.hasAuthority;
      } catch (e) {
        return false;
      }
    }
    
    if (url.isBase64DataUrl) {
      return url.contains(',') && url.split(',').length == 2;
    }
    
    return false;
  }

  Future<void> _processBase64Image() async {
    // Clean cache if needed
    if (_base64Cache.length >= _maxCacheSize) {
      _cleanupOldCache();
    }
    
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
      }
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final parts = widget.imageUrl.split(',');
      if (parts.length != 2) {
        throw Exception('Invalid base64 format');
      }
      
      final base64String = parts[1];
      if (base64String.isEmpty || base64String.length < 50) {
        throw Exception('Invalid base64 data');
      }
      
      final bytes = base64Decode(base64String);
      if (bytes.isEmpty) {
        throw Exception('Failed to decode base64');
      }
      
      // Cache the result
      _base64Cache[widget.imageUrl] = bytes;
      _cacheTimestamps[widget.imageUrl] = DateTime.now();

      if (mounted) {
        setState(() {
          _cachedBytes = bytes;
          _isLoading = false;
          _hasError = false;
          _isInitialized = true;
          _retryCount = 0;
        });
      }
    } catch (e) {
      print('❌ Base64 decode error: $e');
      
      // Retry logic
      if (_retryCount < 2) {
        _retryCount++;
        print('🔄 Retrying base64 decode (attempt $_retryCount/2)');
        
        _retryTimer = Timer(Duration(seconds: 1), () {
          if (mounted) {
            _processBase64Image();
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _isInitialized = true;
          });
        }
      }
    }
  }

  void _cleanupOldCache() {
    if (_base64Cache.length < _maxCacheSize) return;
    
    // Remove oldest entries
    final entries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final toRemove = entries.take(_base64Cache.length - _maxCacheSize + 5);
    for (final entry in toRemove) {
      _base64Cache.remove(entry.key);
      _cacheTimestamps.remove(entry.key);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_hasError || !_isValidUrl(widget.imageUrl)) {
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
        errorWidget: (context, url, error) {
          print('❌ Network image error: $error for URL: $url');
          return _buildErrorWidget();
        },
        
        // IMPROVED: Better cache settings
        memCacheWidth: widget.highQuality ? null : _getSafeCacheSize(widget.width),
        memCacheHeight: widget.highQuality ? null : _getSafeCacheSize(widget.height),
        
        // Use default cache manager to avoid conflicts
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 200),
        filterQuality: widget.highQuality ? FilterQuality.high : FilterQuality.medium,
        
        // IMPROVED: Add timeout
        httpHeaders: {
          'Cache-Control': 'max-age=3600',
        },
      ),
    );
  }

  int? _getSafeCacheSize(double? value) {
    if (value == null || value.isInfinite || value.isNaN) {
      return null;
    }
    
    final intValue = value.toInt();
    return intValue > 800 ? 800 : (intValue < 100 ? null : intValue);
  }

  Widget _buildMemoryImage(Uint8List bytes) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Image.memory(
        bytes,
        width: widget.width,
        height: widget.height,
        fit: widget.fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Memory image error: $error');
          return _buildErrorWidget();
        },
        gaplessPlayback: true,
        filterQuality: widget.highQuality ? FilterQuality.high : FilterQuality.medium,
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
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: _getIconSize(),
              color: Colors.grey[400],
            ),
            if (_retryCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Retry $_retryCount/2',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey[500],
                  ),
                ),
              ),
          ],
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

  double _getIconSize() {
    if (widget.width != null && widget.height != null) {
      final avgSize = (widget.width! + widget.height!) / 2;
      return (avgSize * 0.3).clamp(24.0, 60.0);
    }
    return 40.0;
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  static void clearCache() {
    _base64Cache.clear();
    _cacheTimestamps.clear();
    DefaultCacheManager().emptyCache();
  }
}

// IMPROVED: Watermark preserving image with better error handling
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
            // Main image with better error handling
            UniversalImage(
              imageUrl: imageUrl,
              width: width,
              height: height,
              fit: fit,
              errorWidget: Container(
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                    SizedBox(height: 4),
                    Text(
                      'Image unavailable',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
            
            // Watermark overlay
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
                        errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.store, size: 16, color: Colors.white),
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