import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
import 'dart:developer' as developer;

class LocationsPage extends StatefulWidget {
  const LocationsPage({Key? key}) : super(key: key);

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _lastSearches = [];
  List<String> _searchResults = [];
  bool _isLoadingCurrentLocation = false;
  bool _isSearching = false;
  String? _error;

  // Predefined regions for Pakistan
  final List<Map<String, dynamic>> _regions = [
    {'name': 'Karachi, Sindh', 'lat': 24.8607, 'lng': 67.0011},
    {'name': 'Lahore, Punjab', 'lat': 31.5204, 'lng': 74.3587},
    {'name': 'Islamabad, Capital', 'lat': 33.6844, 'lng': 73.0479},
    {'name': 'Rawalpindi, Punjab', 'lat': 33.5651, 'lng': 73.0169},
    {'name': 'Faisalabad, Punjab', 'lat': 31.4504, 'lng': 73.1350},
    {'name': 'Multan, Punjab', 'lat': 30.1575, 'lng': 71.5249},
    {'name': 'Hyderabad, Sindh', 'lat': 25.3960, 'lng': 68.3578},
    {'name': 'Peshawar, KPK', 'lat': 34.0151, 'lng': 71.5249},
    {'name': 'Quetta, Balochistan', 'lat': 30.1798, 'lng': 66.9750},
    {'name': 'Sialkot, Punjab', 'lat': 32.4945, 'lng': 74.5229},
  ];

  @override
  void initState() {
    super.initState();
    _loadLastSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadLastSearches() {
    // In a real app, load from SharedPreferences
    _lastSearches = ['Saddar, Karachi', 'Model Town Lahore'];
  }

  void _saveLastSearch(String search) {
    if (!_lastSearches.contains(search)) {
      setState(() {
        _lastSearches.insert(0, search);
        if (_lastSearches.length > 5) {
          _lastSearches.removeLast();
        }
      });
      // In a real app, save to SharedPreferences
    }
  }

  void _clearLastSearches() {
    setState(() {
      _lastSearches.clear();
    });
  }

  void _removeLastSearch(String search) {
    setState(() {
      _lastSearches.remove(search);
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
      _error = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them in settings.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in app settings.');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = 'Current Location';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address = '${place.locality}, ${place.administrativeArea}';
      }

      // Update user location
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      bool success = await userProvider.updateUserLocation(
        position.latitude,
        position.longitude,
        address,
      );

      if (success) {
        _saveLastSearch(address);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location updated to: $address'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Failed to update location in database');
      }

    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      developer.log('Location error: $e');
    } finally {
      setState(() {
        _isLoadingCurrentLocation = false;
      });
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      // Search in predefined regions
      List<String> results = _regions
          .where((region) => region['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .map((region) => region['name'].toString())
          .toList();

      // Try geocoding for more results
      try {
        List<Location> locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            locations.first.latitude,
            locations.first.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            String geocodedAddress = '${place.locality}, ${place.administrativeArea}';
            if (!results.contains(geocodedAddress)) {
              results.insert(0, geocodedAddress);
            }
          }
        }
      } catch (e) {
        developer.log('Geocoding failed: $e');
      }

      setState(() {
        _searchResults = results;
      });

    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _selectLocation(String locationName) async {
    try {
      // Find coordinates for the location
      Map<String, dynamic>? regionData = _regions.firstWhere(
        (region) => region['name'] == locationName,
        orElse: () => {},
      );

      double latitude, longitude;

      if (regionData.isNotEmpty) {
        latitude = regionData['lat'];
        longitude = regionData['lng'];
      } else {
        // Try geocoding
        List<Location> locations = await locationFromAddress(locationName);
        if (locations.isEmpty) {
          throw Exception('Location not found');
        }
        latitude = locations.first.latitude;
        longitude = locations.first.longitude;
      }

      // Update user location
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      bool success = await userProvider.updateUserLocation(
        latitude,
        longitude,
        locationName,
      );

      if (success) {
        _saveLastSearch(locationName);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location updated to: $locationName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Failed to update location');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close,
            color: Colors.black,
            size: 24,
          ),
        ),
        title: Text(
          'Locations',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(fontSize: 14),
                onChanged: (value) {
                  _searchLocations(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search area, city or country',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults.clear();
                                });
                              },
                              icon: const Icon(Icons.clear, size: 20),
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Use current location button
            Container(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoadingCurrentLocation ? null : _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5E2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoadingCurrentLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.my_location, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Use current location',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Search Results
            if (_searchResults.isNotEmpty) ...[
              Text(
                'Search Results',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              ...(_searchResults.map((result) => _buildSearchResultItem(result))),
              const SizedBox(height: 24),
            ],

            // Last search section
            if (_lastSearches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last search',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearLastSearches,
                    child: Text(
                      'Clear all',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...(_lastSearches.map((search) => _buildLastSearchItem(search))),
              const SizedBox(height: 24),
            ],

            // Choose region section
            Text(
              'Choose region',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            // Region items
            Expanded(
              child: ListView.builder(
                itemCount: _regions.length,
                itemBuilder: (context, index) {
                  return _buildRegionItem(_regions[index]['name']);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectLocation(text),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastSearchItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectLocation(text),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _removeLastSearch(text),
              icon: const Icon(
                Icons.close,
                size: 18,
                color: Colors.grey,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectLocation(text),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}