// phone_reset_otp_screen.dart - OTP verification for phone password reset
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/auth/controller/auth_provider.dart';
import 'package:arabicmarketplace/screens/forgot_password/view/reset_password_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer';

class PhoneResetOtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  PhoneResetOtpScreen({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  _PhoneResetOtpScreenState createState() => _PhoneResetOtpScreenState();
}

class _PhoneResetOtpScreenState extends State<PhoneResetOtpScreen> {
  final TextEditingController otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

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
              'Verify Phone',
              style: GoogleFonts.jost(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Enter the 6-digit code we sent to\n${widget.phoneNumber}',
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            SizedBox(height: 40),
            
            // OTP Input
            TextFormField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  letterSpacing: 8,
                ),
                counterText: '',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorsController.primaryColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Resend Code
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _resendOtp,
                child: Text(
                  'Resend Code',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    color: ColorsController.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            Spacer(),
            
            // Verify Button
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtpAndProceed,
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
                      'Verify Code',
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

  void _verifyOtpAndProceed() async {
    if (otpController.text.trim().isEmpty || otpController.text.trim().length != 6) {
      _showErrorDialog('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify OTP for password reset (don't validate user type for reset)
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text.trim(),
      );
      
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      setState(() {
        _isLoading = false;
      });

      if (userCredential.user != null) {
        // Navigate to reset password screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              phoneNumber: widget.phoneNumber,
              isPhoneReset: true,
            ),
          ),
        );
      } else {
        _showErrorDialog('Verification failed. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      log('OTP verification error: $e');
      _showErrorDialog('Invalid code. Please try again.');
    }
  }

  void _resendOtp() async {
    try {
      Map<String, dynamic> result = await _authService.resendPhoneOtp(widget.phoneNumber);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorDialog(result['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      _showErrorDialog('Failed to resend OTP. Please try again.');
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