import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arabicmarketplace/resources/colors_controller.dart';

class CityDistrictSelector extends StatefulWidget {
  final String? selectedCityId;
  final String? selectedDistrictId;
  final Function(String cityId, String cityName) onCitySelected;
  final Function(String? districtId, String? districtName)? onDistrictSelected;
  final bool requireDistrict;

  const CityDistrictSelector({
    Key? key,
    this.selectedCityId,
    this.selectedDistrictId,
    required this.onCitySelected,
    this.onDistrictSelected,
    this.requireDistrict = false,
  }) : super(key: key);

  @override
  State<CityDistrictSelector> createState() => _CityDistrictSelectorState();
}

class _CityDistrictSelectorState extends State<CityDistrictSelector> {
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  bool _isLoadingCities = true;
  bool _isLoadingDistricts = false;
  String? _selectedCityId;
  String? _selectedDistrictId;

  @override
  void initState() {
    super.initState();
    _selectedCityId = widget.selectedCityId;
    _selectedDistrictId = widget.selectedDistrictId;
    _loadCities();
    
    if (_selectedCityId != null) {
      _loadDistricts(_selectedCityId!);
    }
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

      final cities = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    } catch (e) {
      print('Error loading cities: $e');
      setState(() {
        _isLoadingCities = false;
        _cities = [];
      });
    }
  }

  Future<void> _loadDistricts(String cityId) async {
    try {
      setState(() {
        _isLoadingDistricts = true;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('districts')
          .where('cityId', isEqualTo: cityId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final districts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      print('Error loading districts: $e');
      setState(() {
        _isLoadingDistricts = false;
        _districts = [];
      });
    }
  }

  void _onCitySelected(String cityId) {
    final city = _cities.firstWhere((c) => c['id'] == cityId);
    
    setState(() {
      _selectedCityId = cityId;
      _selectedDistrictId = null; // Reset district when city changes
      _districts = []; // Clear districts
    });

    widget.onCitySelected(cityId, city['name']);
    
    if (widget.onDistrictSelected != null) {
      widget.onDistrictSelected!(null, null);
    }

    // Load districts for the selected city
    _loadDistricts(cityId);
  }

  void _onDistrictSelected(String? districtId) {
    setState(() {
      _selectedDistrictId = districtId;
    });

    if (widget.onDistrictSelected != null) {
      if (districtId != null) {
        final district = _districts.firstWhere((d) => d['id'] == districtId);
        widget.onDistrictSelected!(districtId, district['name']);
      } else {
        widget.onDistrictSelected!(null, null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // City Selection
        _buildSectionTitle('Select City *', Icons.location_city),
        const SizedBox(height: 12),
        _buildCityDropdown(),
        const SizedBox(height: 16),

        // District Selection (if city is selected)
        if (_selectedCityId != null) ...[
          _buildSectionTitle(
            widget.requireDistrict ? 'Select District *' : 'Select District (Optional)',
            Icons.location_on,
          ),
          const SizedBox(height: 12),
          _buildDistrictDropdown(),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorsController.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: ColorsController.primaryColor,
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.jost(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    if (_isLoadingCities) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading cities...',
              style: GoogleFonts.jost(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_cities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No cities available. Please contact support.',
                style: GoogleFonts.jost(
                  fontSize: 14,
                  color: Colors.red[600],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCityId,
        decoration: InputDecoration(
          hintText: 'Choose your city',
          hintStyle: GoogleFonts.jost(
            fontSize: 16,
            color: Colors.grey[500],
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        items: _cities.map((city) {
          return DropdownMenuItem<String>(
            value: city['id'],
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ColorsController.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    city['name'] ?? 'Unknown City',
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (city['isCapital'] == true) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Capital',
                      style: GoogleFonts.jost(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          if (value != null) {
            _onCitySelected(value);
          }
        },
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: ColorsController.primaryColor,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a city';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    if (_isLoadingDistricts) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading districts...',
              style: GoogleFonts.jost(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_districts.isEmpty && !_isLoadingDistricts) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No districts available for this city.',
                style: GoogleFonts.jost(
                  fontSize: 14,
                  color: Colors.blue[600],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedDistrictId,
        decoration: InputDecoration(
          hintText: widget.requireDistrict 
              ? 'Choose your district' 
              : 'Choose your district (optional)',
          hintStyle: GoogleFonts.jost(
            fontSize: 16,
            color: Colors.grey[500],
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        items: [
          if (!widget.requireDistrict)
            DropdownMenuItem<String>(
              value: null,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'No specific district',
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ..._districts.map((district) {
            return DropdownMenuItem<String>(
              value: district['id'],
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ColorsController.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      district['name'] ?? 'Unknown District',
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
        onChanged: (String? value) {
          _onDistrictSelected(value);
        },
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: ColorsController.primaryColor,
        ),
        validator: widget.requireDistrict 
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a district';
                }
                return null;
              }
            : null,
      ),
    );
  }
}

// Enhanced City Selection Page with Search and Filtering
class CitySelectionPage extends StatefulWidget {
  final String? selectedCityId;
  final String? selectedDistrictId;

  const CitySelectionPage({
    Key? key,
    this.selectedCityId,
    this.selectedDistrictId,
  }) : super(key: key);

  @override
  State<CitySelectionPage> createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends State<CitySelectionPage> {
  List<Map<String, dynamic>> _allCities = [];
  List<Map<String, dynamic>> _filteredCities = [];
  List<Map<String, dynamic>> _districts = [];
  TextEditingController _searchController = TextEditingController();
  String? _selectedCityId;
  String? _selectedDistrictId;
  bool _isLoadingCities = true;
  bool _isLoadingDistricts = false;

  @override
  void initState() {
    super.initState();
    _selectedCityId = widget.selectedCityId;
    _selectedDistrictId = widget.selectedDistrictId;
    _loadCities();
    
    if (_selectedCityId != null) {
      _loadDistricts(_selectedCityId!);
    }

    _searchController.addListener(_filterCities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

      final cities = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _allCities = cities;
        _filteredCities = cities;
        _isLoadingCities = false;
      });
    } catch (e) {
      print('Error loading cities: $e');
      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  Future<void> _loadDistricts(String cityId) async {
    try {
      setState(() {
        _isLoadingDistricts = true;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('districts')
          .where('cityId', isEqualTo: cityId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final districts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      print('Error loading districts: $e');
      setState(() {
        _isLoadingDistricts = false;
      });
    }
  }

  void _filterCities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCities = _allCities.where((city) {
        final cityName = (city['name'] ?? '').toLowerCase();
        return cityName.contains(query);
      }).toList();
    });
  }

  void _selectCity(Map<String, dynamic> city) {
    setState(() {
      _selectedCityId = city['id'];
      _selectedDistrictId = null;
      _districts = [];
    });
    _loadDistricts(city['id']);
  }

  void _selectDistrict(Map<String, dynamic>? district) {
    setState(() {
      _selectedDistrictId = district?['id'];
    });
  }

  void _confirmSelection() {
    if (_selectedCityId != null) {
      final selectedCity = _allCities.firstWhere((c) => c['id'] == _selectedCityId);
      final selectedDistrict = _selectedDistrictId != null 
          ? _districts.firstWhere((d) => d['id'] == _selectedDistrictId)
          : null;

      Navigator.pop(context, {
        'cityId': _selectedCityId,
        'cityName': selectedCity['name'],
        'districtId': _selectedDistrictId,
        'districtName': selectedDistrict?['name'],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Select Location',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedCityId != null)
            TextButton(
              onPressed: _confirmSelection,
              child: Text(
                'Done',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorsController.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cities...',
                hintStyle: GoogleFonts.jost(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _selectedCityId == null ? _buildCityList() : _buildDistrictList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCityList() {
    if (_isLoadingCities) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading cities...',
              style: GoogleFonts.jost(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_filteredCities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No cities found',
              style: GoogleFonts.jost(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: GoogleFonts.jost(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredCities.length,
      itemBuilder: (context, index) {
        final city = _filteredCities[index];
        return _buildCityTile(city);
      },
    );
  }

  Widget _buildDistrictList() {
    final selectedCity = _allCities.firstWhere((c) => c['id'] == _selectedCityId);

    return Column(
      children: [
        // Selected City Header
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorsController.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorsController.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.location_city, color: ColorsController.primaryColor),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected City',
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        color: ColorsController.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      selectedCity['name'],
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorsController.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCityId = null;
                    _selectedDistrictId = null;
                    _districts = [];
                  });
                },
                child: Text(
                  'Change',
                  style: GoogleFonts.jost(
                    color: ColorsController.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Districts Title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Select District (Optional)',
                style: GoogleFonts.jost(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Districts List
        Expanded(
          child: _isLoadingDistricts
              ? Center(child: CircularProgressIndicator())
              : _districts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No districts available',
                            style: GoogleFonts.jost(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _districts.length + 1, // +1 for "No specific district" option
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildDistrictTile(null, 'No specific district');
                        }
                        final district = _districts[index - 1];
                        return _buildDistrictTile(district, district['name']);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCityTile(Map<String, dynamic> city) {
    final isSelected = _selectedCityId == city['id'];

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectCity(city),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? ColorsController.primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? ColorsController.primaryColor : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorsController.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_city,
                  color: ColorsController.primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city['name'] ?? 'Unknown',
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? ColorsController.primaryColor : Colors.black,
                      ),
                    ),
                    if (city['province'] != null) ...[
                      SizedBox(height: 2),
                      Text(
                        city['province'],
                        style: GoogleFonts.jost(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (city['isCapital'] == true)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Capital',
                    style: GoogleFonts.jost(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              SizedBox(width: 8),
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

  Widget _buildDistrictTile(Map<String, dynamic>? district, String name) {
    final isSelected = _selectedDistrictId == district?['id'];
    final isNoDistrict = district == null;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectDistrict(district),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? ColorsController.primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? ColorsController.primaryColor : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isNoDistrict 
                      ? Colors.grey[100]
                      : ColorsController.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isNoDistrict ? Icons.location_off : Icons.location_on,
                  color: isNoDistrict ? Colors.grey[600] : ColorsController.primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? ColorsController.primaryColor : Colors.black,
                    fontStyle: isNoDistrict ? FontStyle.italic : FontStyle.normal,
                  ),
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