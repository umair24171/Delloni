import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/auth/controller/auth_provider.dart';
import 'package:arabicmarketplace/screens/auth/view/verification_screen.dart';
import 'package:arabicmarketplace/screens/custom_bottom_bar.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart'; // Add this import
import 'dart:io';

class CreateAccountScreen extends StatefulWidget {
  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool isIndividualSelected = false;
  bool isPasswordVisible = false;

  // Controllers for Individual
  final TextEditingController individualEmailController =
      TextEditingController();
  final TextEditingController individualPasswordController =
      TextEditingController();
  final TextEditingController individualPhoneController =
      TextEditingController();

  // Controllers for Company
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController companyEmailController = TextEditingController();
  final TextEditingController companyPasswordController =
      TextEditingController();
  final TextEditingController companyPhoneController = TextEditingController();
  final TextEditingController companyAddressController =
      TextEditingController();
  final TextEditingController companyRegisterIdController =
      TextEditingController();

  String selectedLanguage = 'Select your Language';
  String individualCountryCode = '+1';
  String companyCountryCode = '+1';
  final List<String> languages = ['Select your Language', 'English', 'Arabic'];

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final AuthService _authProvider = AuthService();

  @override
  void initState() {
    super.initState();
    companyPhoneController.text = '8976 88';
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleSignUp() async {
    if (selectedLanguage == 'Select your Language') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.selectLanguage.tr()),
        ), // Using existing key
      );
      return;
    }

    Map<String, dynamic> result;
    String email = isIndividualSelected
        ? individualEmailController.text.trim()
        : companyEmailController.text.trim();

    if (isIndividualSelected) {
      result = await _authProvider.registerIndividual(
        email: email,
        password: individualPasswordController.text.trim(),
        phone:
            '$individualCountryCode ${individualPhoneController.text.trim()}',
        language: selectedLanguage,
      );
    } else {
      result = await _authProvider.registerCompany(
        companyName: companyNameController.text.trim(),
        email: email,
        password: companyPasswordController.text.trim(),
        phone: '$companyCountryCode ${companyPhoneController.text.trim()}',
        address: companyAddressController.text.trim(),
        registerId: companyRegisterIdController.text.trim(),
        language: selectedLanguage,
        profileImage: _profileImage,
      );
    }

    if (result['success']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginVerificationScreen(email: email),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  Future<void> _handleGoogleSignIn() async {
    Map<String, dynamic> result = await _authProvider.signInWithGoogle(
      type: isIndividualSelected ? 'individual' : 'company',
      phone: isIndividualSelected
          ? '$individualCountryCode ${individualPhoneController.text.trim()}'
          : '$companyCountryCode ${companyPhoneController.text.trim()}',
      language: selectedLanguage,
      companyName: isIndividualSelected
          ? null
          : companyNameController.text.trim(),
      address: isIndividualSelected
          ? null
          : companyAddressController.text.trim(),
      registerId: isIndividualSelected
          ? null
          : companyRegisterIdController.text.trim(),
    );

    if (result['success']) {
      // Google Sign-In users are auto-verified, so skip OTP
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CustomBottomNavigationBar()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                AppLocalizations.createAccountAs.tr(), // Using existing key
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isIndividualSelected = true;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            AppLocalizations.individual
                                .tr(), // Using existing key
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isIndividualSelected
                                  ? Colors.black
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 2,
                            color: isIndividualSelected
                                ? Colors.black
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isIndividualSelected = false;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            AppLocalizations.company.tr(), // Using existing key
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: !isIndividualSelected
                                  ? Colors.black
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 2,
                            color: !isIndividualSelected
                                ? Colors.black
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              if (!isIndividualSelected) ...[
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        image: _profileImage != null
                            ? DecorationImage(
                                image: FileImage(_profileImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profileImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.uploadImage
                                      .tr(), // Using existing key
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
              if (isIndividualSelected) ...[
                _buildInputField(
                  controller: individualEmailController,
                  hintText: AppLocalizations.enterEmail
                      .tr(), // Using existing key
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: individualPasswordController,
                  hintText: AppLocalizations.enterPassword
                      .tr(), // Using existing key
                ),
                const SizedBox(height: 16),
                _buildPhoneField(
                  controller: individualPhoneController,
                  countryCode: individualCountryCode,
                  onCountryChanged: (code) {
                    setState(() {
                      individualCountryCode = code.dialCode ?? '+1';
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildLanguageDropdown(),
              ] else ...[
                _buildInputField(
                  controller: companyNameController,
                  hintText: AppLocalizations.enterCompanyName
                      .tr(), // Using existing key
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: companyEmailController,
                  hintText: AppLocalizations.enterEmail
                      .tr(), // Using existing key
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: companyPasswordController,
                  hintText: AppLocalizations.enterPassword
                      .tr(), // Using existing key
                ),
                const SizedBox(height: 16),
                _buildPhoneField(
                  controller: companyPhoneController,
                  countryCode: companyCountryCode,
                  onCountryChanged: (code) {
                    setState(() {
                      companyCountryCode = code.dialCode ?? '+1';
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildLanguageDropdown(),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: companyAddressController,
                  hintText: AppLocalizations.enterCompanyAddress
                      .tr(), // Using existing key
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: companyRegisterIdController,
                  hintText: AppLocalizations.enterCompanyRegisterId
                      .tr(), // Using existing key
                  icon: Icons.business_outlined,
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsController.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.signUp.tr(), // Using existing key
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Or log in with', // Could use existing 'login' key creatively
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsController.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      icon: Image.asset(
                        'assets/icons/google.png',
                        height: 19,
                        width: 18,
                      ),
                      label: Text(
                        AppLocalizations.google.tr(), // Using existing key
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.error.tr()),
                          ), // Using existing key
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsController.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      icon: Image.asset(
                        'assets/icons/facebook.png',
                        height: 19,
                        width: 18,
                      ),
                      label: Text(
                        AppLocalizations.facebook.tr(), // Using existing key
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
                    children: [
                      TextSpan(
                        text: AppLocalizations.bySigningUpAgree.tr(),
                      ), // Using existing key
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: AppLocalizations.termsOfServices
                            .tr(), // Using existing key
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: ' ${AppLocalizations.and.tr()} ',
                      ), // Using existing key
                      TextSpan(
                        text: AppLocalizations.privacyPolicy
                            .tr(), // Using existing key
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.jost(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: ColorsController.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: ColorsController.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: ColorsController.borderColor),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF635C5C),
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isPasswordVisible,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: ColorsController.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: ColorsController.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: ColorsController.borderColor),
          ),
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF635C5C),
          ),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
            child: Icon(
              isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    required String countryCode,
    required Function(CountryCode) onCountryChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ColorsController.borderColor),
      ),
      child: Row(
        children: [
          CountryCodePicker(
            onChanged: onCountryChanged,
            initialSelection: 'US',
            favorite: ['+1', 'US'],
            textStyle: GoogleFonts.jost(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            showFlag: true,
            showFlagDialog: true,
            dialogSize: Size(
              MediaQuery.of(context).size.width * 0.9,
              MediaQuery.of(context).size.height * 0.6,
            ),
            dialogBackgroundColor: Colors.white,
            dialogTextStyle: GoogleFonts.jost(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            searchStyle: GoogleFonts.jost(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            searchDecoration: InputDecoration(
              hintText: AppLocalizations.search.tr(), // Using existing key
              hintStyle: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF9CA3AF),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(color: ColorsController.borderColor),
              ),
            ),
          ),
          Container(width: 1, height: 24, color: const Color(0xFFE5E7EB)),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                hintText: AppLocalizations.phone.tr(), // Using existing key
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                controller.clear();
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF6B7280),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: ColorsController.borderColor),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedLanguage,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIcon: const Icon(
            Icons.language_outlined,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
        ),
        style: GoogleFonts.jost(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF9CA3AF),
        ),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
        items: [
          DropdownMenuItem<String>(
            value: 'Select your Language',
            child: Text(
              AppLocalizations.selectYourLanguage.tr(), // Using existing key
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF635C5C),
              ),
            ),
          ),
          DropdownMenuItem<String>(
            value: 'English',
            child: Text(
              AppLocalizations.english.tr(), // Using existing key
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          DropdownMenuItem<String>(
            value: 'Arabic',
            child: Text(
              AppLocalizations.arabic.tr(), // Using existing key
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
        onChanged: (String? newValue) {
          setState(() {
            selectedLanguage = newValue!;
          });
        },
      ),
    );
  }
}
