import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' show placemarkFromCoordinates, Placemark;
import 'package:google_places_flutter/google_places_flutter.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final double initialRadiusKm;
  const MapLocationPicker({Key? key, this.initialLocation, this.initialRadiusKm = 10}) : super(key: key);

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late LatLng _selectedLocation;
  double _radiusKm = 10;
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _radiusKm = widget.initialRadiusKm;
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
    } else {
      _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);
    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _selectedLocation = LatLng(pos.latitude, pos.longitude);
      _isLoading = false;
    });
  }

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return [
          place.name,
          place.locality,
          place.administrativeArea,
          place.country
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
    } catch (_) {}
    return 'Lat: ${latLng.latitude.toStringAsFixed(4)}, Lng: ${latLng.longitude.toStringAsFixed(4)}';
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Location', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _selectedLocation == null || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 12,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: _onMapTap,
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation,
                      draggable: true,
                      onDragEnd: (latLng) => setState(() => _selectedLocation = latLng),
                    ),
                  },
                  circles: {
                    Circle(
                      circleId: const CircleId('radius'),
                      center: _selectedLocation,
                      radius: _radiusKm * 1000,
                      fillColor: Colors.green.withOpacity(0.2),
                      strokeColor: Colors.green,
                      strokeWidth: 2,
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(24),
                    child: GooglePlaceAutoCompleteTextField(
                      textEditingController: _searchController,
                      googleAPIKey: "AIzaSyDB7brAL6dmHGmHj-G0FlHQcdEc4TDp1yY",
                      inputDecoration: InputDecoration(
                        hintText: 'Search for a place',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      debounceTime: 400,
                      countries: ["de"], // restrict to Germany, adjust as needed
                      isLatLngRequired: true,
                      getPlaceDetailWithLatLng: (prediction) {
                        if (prediction.lat != null && prediction.lng != null) {
                          final newLatLng = LatLng(double.parse(prediction.lat!), double.parse(prediction.lng!));
                          setState(() {
                            _selectedLocation = newLatLng;
                          });
                          _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
                        }
                      },
                      itemClick: (prediction) {
                        _searchController.text = prediction.description!;
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.black,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Area', style: TextStyle(color: Colors.white)),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _radiusKm,
                                  min: 1,
                                  max: 100,
                                  divisions: 99,
                                  label: '${_radiusKm.round()} km',
                                  onChanged: (v) => setState(() => _radiusKm = v),
                                ),
                              ),
                              Text('About ${_radiusKm.round()} km', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent[400],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        final address = await _getAddressFromLatLng(_selectedLocation);
                        Navigator.of(context).pop({
                          'latLng': _selectedLocation,
                          'radiusKm': _radiusKm,
                          'address': address,
                        });
                      },
                      child: const Text('Show results', style: TextStyle(fontSize: 18, color: Colors.black)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
} 