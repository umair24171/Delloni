import 'package:arabicmarketplace/resources/colors_controller.dart';

import 'package:arabicmarketplace/screens/custom_bottom_bar.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController addressController = TextEditingController();

  Future<void> _handleFindMyLocation() async {
    setState(() => isLoading = true);

    try {
      // Check and request location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar(
          'Location services are disabled. Please enable them.',
        );
        setState(() => isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permission denied.');
          setState(() => isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar(
          'Location permission permanently denied. Please enable it in settings.',
        );
        setState(() => isLoading = false);
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      String address =
          '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';

      // Save to Firestore
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('location')
            .doc('current')
            .set({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'address': address,
              'timestamp': FieldValue.serverTimestamp(),
            });

        _showSuccessSnackBar(AppLocalizations.success.tr());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomBottomNavigationBar()),
        );
      } else {
        _showErrorSnackBar('User not authenticated. Please log in again.');
      }
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.error.tr()}: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleOtherLocation() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.location.tr(),
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        content: TextField(
          controller: addressController,
          style: GoogleFonts.jost(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.address.tr(),
            hintStyle: GoogleFonts.jost(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF9E9E9E),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.cancel.tr(),
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFF6B35),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (addressController.text.trim().isEmpty) {
                _showErrorSnackBar(
                  '${AppLocalizations.address.tr()} ${AppLocalizations.required.tr()}',
                );
                return;
              }

              setState(() => isLoading = true);
              try {
                User? user = _auth.currentUser;
                if (user != null) {
                  // Optional: Geocode manual address to get lat/lng
                  List<Location> locations = await locationFromAddress(
                    addressController.text.trim(),
                  );
                  double latitude = locations.isNotEmpty
                      ? locations[0].latitude
                      : 0.0;
                  double longitude = locations.isNotEmpty
                      ? locations[0].longitude
                      : 0.0;

                  await _firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('location')
                      .doc('current')
                      .set({
                        'latitude': latitude,
                        'longitude': longitude,
                        'address': addressController.text.trim(),
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                  _showSuccessSnackBar(AppLocalizations.success.tr());
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomBottomNavigationBar(),
                    ),
                  );
                } else {
                  _showErrorSnackBar(
                    'User not authenticated. Please log in again.',
                  );
                }
              } catch (e) {
                _showErrorSnackBar('${AppLocalizations.error.tr()}: $e');
              } finally {
                setState(() => isLoading = false);
              }
            },
            child: Text(
              AppLocalizations.save.tr(),
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ColorsController.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Location Icon with Concentric Circles
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF2D5A27).withOpacity(0.1),
                      Color(0xFF2D5A27).withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2D5A27).withOpacity(0.15),
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE3F2FD),
                        ),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            child: Image.asset(
                              'assets/icons/location.png',
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.location_on,
                                    size: 40,
                                    color: Color(0xFF2D5A27),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.2),

              // Title
              Text(
                AppLocalizations.whereIsYourLocation.tr(),
                style: GoogleFonts.jost(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C2C2C),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                AppLocalizations.enjoyPersonalizedExperience.tr(),
                style: GoogleFonts.jost(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9E9E9E),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // Find my Location Button
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleFindMyLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsController.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.my_location,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.findMyLocation.tr(),
                              style: GoogleFonts.jost(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Other Location Button
              TextButton(
                onPressed: isLoading ? null : _handleOtherLocation,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  AppLocalizations.otherLocation.tr(),
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C2C2C),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
