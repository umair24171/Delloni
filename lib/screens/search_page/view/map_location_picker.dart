import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'dart:math' as math;

class EnhancedMapLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final double initialRadiusKm;
  
  const EnhancedMapLocationPicker({
    Key? key, 
    this.initialLocation, 
    this.initialRadiusKm = 10
  }) : super(key: key);

  @override
  State<EnhancedMapLocationPicker> createState() => _EnhancedMapLocationPickerState();
}

class _EnhancedMapLocationPickerState extends State<EnhancedMapLocationPicker> {
  late LatLng _selectedLocation;
  double _radiusKm = 10;
  GoogleMapController? _mapController;
  bool _isLoading = false;
  bool _isLoadingLocations = true;
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  
  // Database locations
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  Set<Marker> _locationMarkers = {};
  
  // Selected location info
  Map<String, dynamic>? _selectedCityData;
  Map<String, dynamic>? _selectedDistrictData;
  String _selectedAddress = '';

  @override
  void initState() {
    super.initState();
    _radiusKm = widget.initialRadiusKm;
    
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _getAddressFromLatLng(_selectedLocation);
    } else {
      _determinePosition();
    }
    
    _loadDatabaseLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load cities and districts from Firebase
  Future<void> _loadDatabaseLocations() async {
    print('🏙️ Loading cities and districts from database...');
    
    try {
      setState(() => _isLoadingLocations = true);
      
      // Load cities
      final citiesSnapshot = await FirebaseFirestore.instance
          .collection('cities')
          .where('isActive', isEqualTo: true)
          .get();
      
      _cities = citiesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Load districts
      final districtsSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .where('isActive', isEqualTo: true)
          .get();
      
      _districts = districtsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      print('🏙️ Loaded ${_cities.length} cities and ${_districts.length} districts');
      
      // Create markers for locations that have coordinates
      await _createLocationMarkers();
      
      setState(() => _isLoadingLocations = false);
      
    } catch (e) {
      print('❌ Error loading database locations: $e');
      setState(() => _isLoadingLocations = false);
    }
  }

  // Create markers for cities and districts with coordinates
  Future<void> _createLocationMarkers() async {
    final markers = <Marker>{};
    
    // Add city markers
    for (final city in _cities) {
      final lat = _getCoordinateValue(city['latitude']);
      final lng = _getCoordinateValue(city['longitude']);
      
      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        markers.add(
          Marker(
            markerId: MarkerId('city_${city['id']}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: city['name'] ?? 'Unknown City',
              snippet: 'City',
            ),
            onTap: () => _selectDatabaseLocation(city, null),
          ),
        );
      }
    }
    
    // Add district markers
    for (final district in _districts) {
      final lat = _getCoordinateValue(district['latitude']);
      final lng = _getCoordinateValue(district['longitude']);
      
      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        // Find parent city name
        final parentCity = _cities.firstWhere(
          (city) => city['id'] == district['cityId'],
          orElse: () => <String, dynamic>{},
        );
        
        markers.add(
          Marker(
            markerId: MarkerId('district_${district['id']}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: district['name'] ?? 'Unknown District',
              snippet: 'District in ${parentCity['name'] ?? 'Unknown City'}',
            ),
            onTap: () => _selectDatabaseLocation(parentCity, district),
          ),
        );
      }
    }
    
    setState(() {
      _locationMarkers = markers;
    });
    
    print('🗺️ Created ${markers.length} location markers');
  }

  // Helper to safely get coordinate values
  double? _getCoordinateValue(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Select a database location (city or district)
  void _selectDatabaseLocation(Map<String, dynamic>? cityData, Map<String, dynamic>? districtData) {
    print('🎯 Selected database location:');
    print('🎯 City: ${cityData?['name']} (${cityData?['id']})');
    print('🎯 District: ${districtData?['name']} (${districtData?['id']})');
    
    setState(() {
      _selectedCityData = cityData;
      _selectedDistrictData = districtData;
      
      // Set location to district if available, otherwise city
      final targetData = districtData ?? cityData;
      if (targetData != null) {
        final lat = _getCoordinateValue(targetData['latitude']);
        final lng = _getCoordinateValue(targetData['longitude']);
        
        if (lat != null && lng != null) {
          _selectedLocation = LatLng(lat, lng);
          _mapController?.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
        }
      }
      
      // Update address display
      if (districtData != null && cityData != null) {
        _selectedAddress = '${districtData['name']}, ${cityData['name']}';
      } else if (cityData != null) {
        _selectedAddress = cityData['name'] ?? 'Unknown';
      }
    });
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _selectedLocation = LatLng(pos.latitude, pos.longitude);
        _isLoading = false;
      });
      _getAddressFromLatLng(_selectedLocation);
      _findNearestDatabaseLocation(_selectedLocation);
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error getting current position: $e');
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _selectedAddress = [
            place.name,
            place.locality,
            place.administrativeArea,
            place.country
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Lat: ${latLng.latitude.toStringAsFixed(4)}, Lng: ${latLng.longitude.toStringAsFixed(4)}';
      });
    }
  }

  // Find nearest database location to selected coordinates
  void _findNearestDatabaseLocation(LatLng location) {
    double nearestDistance = double.infinity;
    Map<String, dynamic>? nearestCity;
    Map<String, dynamic>? nearestDistrict;
    
    // Check districts first (more specific)
    for (final district in _districts) {
      final lat = _getCoordinateValue(district['latitude']);
      final lng = _getCoordinateValue(district['longitude']);
      
      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        final distance = _calculateDistance(
          location.latitude, location.longitude,
          lat, lng,
        );
        
        if (distance < nearestDistance && distance <= 50) { // Within 50km
          nearestDistance = distance;
          nearestDistrict = district;
          // Find parent city
          nearestCity = _cities.firstWhere(
            (city) => city['id'] == district['cityId'],
            orElse: () => <String, dynamic>{},
          );
        }
      }
    }
    
    // If no nearby district found, check cities
    if (nearestDistrict == null) {
      nearestDistance = double.infinity;
      for (final city in _cities) {
        final lat = _getCoordinateValue(city['latitude']);
        final lng = _getCoordinateValue(city['longitude']);
        
        if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
          final distance = _calculateDistance(
            location.latitude, location.longitude,
            lat, lng,
          );
          
          if (distance < nearestDistance && distance <= 100) { // Within 100km
            nearestDistance = distance;
            nearestCity = city;
            nearestDistrict = null;
          }
        }
      }
    }
    
    if (nearestCity != null) {
      print('🎯 Found nearest location: ${nearestCity['name']}');
      if (nearestDistrict != null) {
        print('🎯 With district: ${nearestDistrict['name']}');
      }
      
      setState(() {
        _selectedCityData = nearestCity;
        _selectedDistrictData = nearestDistrict;
      });
    } else {
      setState(() {
        _selectedCityData = null;
        _selectedDistrictData = null;
      });
    }
  }

  // Calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
    _getAddressFromLatLng(latLng);
    _findNearestDatabaseLocation(latLng);
  }

  // NEW: Handle place selection from Google Places
  void _onPlaceSelected(Prediction prediction) {
    if (prediction.lat != null && prediction.lng != null) {
      final newLatLng = LatLng(
        double.parse(prediction.lat!), 
        double.parse(prediction.lng!)
      );
      
      setState(() {
        _selectedLocation = newLatLng;
        _selectedAddress = prediction.description ?? '';
      });
      
      // Animate camera to new location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLatLng, 15),
      );
      
      // Find nearest database location
      _findNearestDatabaseLocation(newLatLng);
      
      print('🎯 Selected place: ${prediction.description}');
      print('🎯 Coordinates: ${newLatLng.latitude}, ${newLatLng.longitude}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Choose Location on Map'.tr(),
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme:  IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _selectedLocation == null || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 10,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: _onMapTap,
                  markers: {
                    // Selected location marker
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation,
                      draggable: true,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: InfoWindow(
                        title: 'Selected Location',
                        snippet: _selectedAddress,
                      ),
                      onDragEnd: (latLng) {
                        setState(() {
                          _selectedLocation = latLng;
                          // _showSearchResults = false;
                        });
                        _getAddressFromLatLng(latLng);
                        _findNearestDatabaseLocation(latLng);
                      },
                    ),
                    // Database location markers
                    ..._locationMarkers,
                  },
                  circles: {
                    Circle(
                      circleId: const CircleId('radius'),
                      center: _selectedLocation,
                      radius: _radiusKm * 1000,
                      fillColor: Colors.blue.withOpacity(0.1),
                      strokeColor: Colors.blue,
                      strokeWidth: 2,
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),

                // Search bar at the top
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                          child: GooglePlaceAutoCompleteTextField(
                        textEditingController: _searchController,
                        googleAPIKey: "AIzaSyDB7brAL6dmHGmHj-G0FlHQcdEc4TDp1yY", // Replace with your API key
                        inputDecoration: InputDecoration(
                          hintText: 'Search for a place...'.tr(),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        debounceTime: 600,
                        countries: ["sy"], // Restrict to Syria, change as needed
                        isLatLngRequired: true,
                        getPlaceDetailWithLatLng: _onPlaceSelected,
                        itemClick: (Prediction prediction) {
                          _searchController.text = prediction.description ?? '';
                          FocusScope.of(context).unfocus();
                        },
                        seperatedBuilder: Divider(height: 1, color: Colors.grey[300]),
                        containerHorizontalPadding: 0,
                        itemBuilder: (context, index, Prediction prediction) {
                          return Container(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prediction.structuredFormatting?.mainText ?? prediction.description ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (prediction.structuredFormatting?.secondaryText != null)
                                        Text(
                                          prediction.structuredFormatting!.secondaryText!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                // Loading overlay for locations
                if (_isLoadingLocations)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading available locations...'.tr()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Map legend
                Positioned(
                  top: 80, // Fixed positioning since search is now self-contained
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Legend',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text('Selected', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: Colors.blue, size: 16),
                              SizedBox(width: 4),
                              Text('Cities', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: Colors.orange, size: 16),
                              SizedBox(width: 4),
                              Text('Districts', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Location info card
                Positioned(
                  top: 80,
                  left: 16,
                  right: 80, // Leave space for legend
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Selected Location',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            _selectedAddress,
                            style: GoogleFonts.poppins(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_selectedCityData != null || _selectedDistrictData != null) ...[
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Matched Database Location:',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  if (_selectedDistrictData != null)
                                    Text(
                                      '${_selectedDistrictData!['name']}, ${_selectedCityData!['name']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.green[700],
                                      ),
                                    )
                                  else if (_selectedCityData != null)
                                    Text(
                                      _selectedCityData!['name'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Radius control
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Search Radius: ${_radiusKm.round()} km',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Slider(
                            value: _radiusKm,
                            min: 1,
                            max: 100,
                            divisions: 99,
                            onChanged: (v) => setState(() => _radiusKm = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Confirm button
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      // Return the selected location data
                      Navigator.of(context).pop({
                        'latLng': _selectedLocation,
                        'radiusKm': _radiusKm,
                        'address': _selectedAddress,
                        'cityId': _selectedCityData?['id'],
                        'cityName': _selectedCityData?['name'],
                        'districtId': _selectedDistrictData?['id'],
                        'districtName': _selectedDistrictData?['name'],
                      });
                    },
                    child: Text(
                      'Confirm Location'.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}