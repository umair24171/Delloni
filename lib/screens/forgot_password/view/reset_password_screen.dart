// reset_password_screen.dart - Final password reset screen
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer';

class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  final String? phoneNumber;
  final bool isPhoneReset;

  ResetPasswordScreen({
    this.email, 
    this.phoneNumber,
    this.isPhoneReset = false,
  });

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool hasMinLength = false;
  bool hasNumberOrSymbol = false;
  bool hasUpperAndLowerCase = false;

  @override
  void initState() {
    super.initState();
    newPasswordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    String password = newPasswordController.text;
    setState(() {
      hasMinLength = password.length >= 8;
      hasNumberOrSymbol = password.contains(RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]'));
      hasUpperAndLowerCase = password.contains(RegExp(r'[a-z]')) && password.contains(RegExp(r'[A-Z]'));
    });
  }

  Widget _buildRequirement(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          color: met ? ColorsController.primaryColor : Colors.grey[400],
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.jost(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: met ? Colors.black : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _resetPassword() async {
    String password = newPasswordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    if (password != confirmPassword) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    if (!hasMinLength || !hasNumberOrSymbol || !hasUpperAndLowerCase) {
      _showErrorDialog('Password does not meet requirements');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null && widget.isPhoneReset) {
        // For phone reset - user is already authenticated via OTP
        await currentUser.updatePassword(password);
        
        // Update user document in Firestore
        await _firestore.collection('users').doc(currentUser.uid).update({
          'passwordUpdatedAt': FieldValue.serverTimestamp(),
        });
        
        // Sign out the user so they can sign in with new password
        await _auth.signOut();
        
        setState(() {
          _isLoading = false;
        });
        
        _showSuccessDialog();
      } else {
        // For email reset - this shouldn't happen as email uses Firebase's built-in reset
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Invalid reset method');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      log('Reset password error: $e');
      _showErrorDialog('Failed to reset password. Please try again.');
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text('Your password has been reset successfully! Please login with your new password.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

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
              'Reset Password',
              style: GoogleFonts.jost(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            
            SizedBox(height: 40),
            
            // New Password
            Text(
              'New Password',
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: ColorsController.borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(Icons.lock_outline, color: Colors.grey[500], size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: newPasswordController,
                      obscureText: !isNewPasswordVisible,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: GoogleFonts.jost(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isNewPasswordVisible = !isNewPasswordVisible;
                        });
                      },
                      child: Icon(
                        isNewPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Password Requirements
            Column(
              children: [
                _buildRequirement('At least 8 characters', hasMinLength),
                _buildRequirement('At least one number (0-9) or symbol', hasNumberOrSymbol),
                _buildRequirement('Lowercase (a-z) and uppercase (A-Z)', hasUpperAndLowerCase),
              ],
            ),
            
            SizedBox(height: 32),
            
            // Confirm Password
            Text(
              'Confirm Password',
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: ColorsController.borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(Icons.lock_outline, color: Colors.grey[500], size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: confirmPasswordController,
                      obscureText: !isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: GoogleFonts.jost(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      },
                      child: Icon(
                        isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            // Reset Password Button
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
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
                      'Reset Password',
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}