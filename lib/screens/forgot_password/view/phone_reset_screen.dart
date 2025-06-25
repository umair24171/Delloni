// phone_reset_screen.dart - Phone number input for password reset
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/auth/controller/auth_provider.dart';
import 'package:arabicmarketplace/screens/forgot_password/view/phone_reset_otp_screen.dart';
import 'package:arabicmarketplace/screens/forgot_password/view/reset_password_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer';

class PhoneResetScreen extends StatefulWidget {
  @override
  _PhoneResetScreenState createState() => _PhoneResetScreenState();
}

class _PhoneResetScreenState extends State<PhoneResetScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String countryCode = '+1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFFFF6B35), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              'Reset with Phone',
              style: GoogleFonts.jost(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Enter your phone number and we\'ll send you\na verification code to reset your password.',
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            SizedBox(height: 40),
            
            // Phone Input with Country Code Picker
            Text(
              'Phone Number',
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorsController.borderColor),
              ),
              child: Row(
                children: [
                  // Country Code Picker
                  CountryCodePicker(
                    onChanged: (code) {
                      setState(() {
                        countryCode = code.dialCode ?? '+1';
                      });
                    },
                    initialSelection: 'US',
                    favorite: ['+1', 'US'],
                    textStyle: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    showFlag: true,
                    showFlagDialog: true,
                  ),

                  // Vertical Divider
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFE5E7EB),
                  ),

                  // Phone Number Input
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        hintText: 'Enter phone number',
                        hintStyle: GoogleFonts.jost(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),

                  // X Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () {
                        _phoneController.clear();
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B7280),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Spacer(),
            
            // Send Code Button
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _initiatePhoneReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsController.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Send Code',
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _initiatePhoneReset() async {
    if (_phoneController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your phone number');
      return;
    }

    String phoneNumber = '$countryCode${_phoneController.text.trim()}';

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user exists with this phone number
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('No account found with this phone number');
        return;
      }

      // Use AuthService to initiate phone verification for password reset
      Map<String, dynamic> result = await _authService.initiatePhoneLogin(phoneNumber, true);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        if (result.containsKey('autoVerified') && result['autoVerified']) {
          // Auto-verification - go directly to reset password
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                phoneNumber: phoneNumber,
                isPhoneReset: true,
              ),
            ),
          );
        } else {
          // OTP sent - go to OTP verification
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhoneResetOtpScreen(
                verificationId: result['verificationId'],
                phoneNumber: phoneNumber,
              ),
            ),
          );
        }
      } else {
        _showErrorDialog(result['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      log('Phone reset error: $e');
      _showErrorDialog('An error occurred. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}