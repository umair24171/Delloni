
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rename/platform_file_editors/abs_platform_file_editor.dart';

class CityDistrictSelectionPage extends StatefulWidget {
  const CityDistrictSelectionPage({Key? key}) : super(key: key);

  @override
  State<CityDistrictSelectionPage> createState() => _CityDistrictSelectionPageState();
}

class _CityDistrictSelectionPageState extends State<CityDistrictSelectionPage> {
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  bool _isLoadingCities = true;
  bool _isLoadingDistricts = false;
  String? _selectedCityId;
  String? _selectedDistrictId;
  String? _selectedCityName;
  String? _selectedDistrictName;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      setState(() {
        _isLoadingCities = true;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('cities')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      _cities = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _isLoadingCities = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCities = false;
      });
      logger.e('Error loading cities: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading cities: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadDistricts(String cityId) async {
    try {
      setState(() {
        _isLoadingDistricts = true;
        _districts = [];
        _selectedDistrictId = null;
        _selectedDistrictName = null;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('districts')
          .where('cityId', isEqualTo: cityId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      _districts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _isLoadingDistricts = false;
      });
    } catch (e) {
      logger.e('Error loading districts: $e');
      setState(() {
        _isLoadingDistricts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading districts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        // backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Select Location'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            // color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStepIndicator(1, true, 'City'),
                Expanded(child: Container(height: 2, color: Colors.grey[300])),
                _buildStepIndicator(2, _selectedCityId != null, 'District (Optional)'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _selectedCityId == null
                ? _buildCitySelection()
                : _buildDistrictSelection(),
          ),

          // Bottom Action Button
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (_selectedCityId != null)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Selected Location:'.tr(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _selectedDistrictName != null
                              ? '$_selectedDistrictName, $_selectedCityName'
                              : _selectedCityName ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    if (_selectedCityId != null)
                      Expanded(
                        child: OutlinedButton(
                         onPressed: _selectedCityId != null ? () {
  final fullAddress = _selectedDistrictName != null
      ? '$_selectedDistrictName, $_selectedCityName'
      : _selectedCityName!;

  // DEBUG: Print what we're about to return
  print('🏙️ CITY SELECTION DEBUG:');
  print('  - Selected City ID: $_selectedCityId');
  print('  - Selected City Name: $_selectedCityName');
  print('  - Selected District ID: $_selectedDistrictId');
  print('  - Selected District Name: $_selectedDistrictName');
  print('  - Full Address: $fullAddress');
  
  final resultData = {
    'cityId': _selectedCityId,
    'districtId': _selectedDistrictId,
    'cityName': _selectedCityName,
    'districtName': _selectedDistrictName,
    'fullAddress': fullAddress,
    'latitude': 0.0,
    'longitude': 0.0,
  };
  
  print('  - Returning data: $resultData');

  Navigator.pop(context, resultData);
} : null,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Change City'.tr(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),

                    if (_selectedCityId != null) SizedBox(width: 12),

                    Expanded(
                      flex: _selectedCityId != null ? 2 : 1,
                      child: ElevatedButton(
                        onPressed: _selectedCityId != null ? () {
                          final fullAddress = _selectedDistrictName != null
                              ? '$_selectedDistrictName, $_selectedCityName'
                              : _selectedCityName!;
                          print('🏙️ CITY SELECTION DEBUG:');
                          print('  - Selected City ID: $_selectedCityId');
                          print('  - Selected City Name: $_selectedCityName');
                          print('  - Selected District ID: $_selectedDistrictId');
                          print('  - Selected District Name: $_selectedDistrictName');
                          print('  - Full Address: $fullAddress');

                          Navigator.pop(context, {
                            'cityId': _selectedCityId,
                            'districtId': _selectedDistrictId,
                            'cityName': _selectedCityName,
                            'districtName': _selectedDistrictName,
                            'fullAddress': fullAddress,
                            'latitude': 0.0, // You can store actual coordinates
                            'longitude': 0.0,
                          });
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedCityId != null 
                              ? ColorsController.primaryColor 
                              : Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Confirm Location'.tr(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            // color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive, String label) {
    return Container(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isActive ? ColorsController.primaryColor : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? null: Colors.grey[600],
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label.tr(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isActive ? ColorsController.primaryColor : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Your City'.tr(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  // color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Choose the city where your item is located'.tr(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoadingCities
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(ColorsController.primaryColor),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading cities...'.tr(),
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : _cities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_city, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No cities available'.tr(),
                            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _cities.length,
                      itemBuilder: (context, index) {
                        final city = _cities[index];
                        return _buildCityItem(city);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDistrictSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select District (Optional)'.tr(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Choose a specific district in $_selectedCityName or skip this step',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Skip District Button
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () {
              // Skip district selection - proceed with city only
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.skip_next, color: Colors.grey[600]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Skip - Use city only ($_selectedCityName)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 16),

        Expanded(
          child: _isLoadingDistricts
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(ColorsController.primaryColor),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading districts...',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : _districts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No districts available for $_selectedCityName',
                            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _districts.length,
                      itemBuilder: (context, index) {
                        final district = _districts[index];
                        return _buildDistrictItem(district);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCityItem(Map<String, dynamic> city) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCityId = city['id'];
            _selectedCityName = city['name'];
          });
          // Defer the call to after the build is complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadDistricts(city['id']);
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorsController.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_city,
                  color: ColorsController.primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city['name'] ?? 'Unknown City',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (city['description'] != null)
                      Text(
                        city['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictItem(Map<String, dynamic> district) {
    final isSelected = _selectedDistrictId == district['id'];

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDistrictId = district['id'];
            _selectedDistrictName = district['name'];
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? ColorsController.primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? ColorsController.primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: ColorsController.primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ] : [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? ColorsController.primaryColor.withOpacity(0.2)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: isSelected ? ColorsController.primaryColor : Colors.grey[600],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      district['name'] ?? 'Unknown District',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? ColorsController.primaryColor : Colors.black,
                      ),
                    ),
                    if (district['description'] != null)
                      Text(
                        district['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: ColorsController.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
                      

           