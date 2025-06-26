// email_reset_screen.dart - Fixed email password reset with localization
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart'; // Add this import
import 'dart:developer';

class EmailResetScreen extends StatefulWidget {
  @override
  _EmailResetScreenState createState() => _EmailResetScreenState();
}

class _EmailResetScreenState extends State<EmailResetScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
          child: Container(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              AppLocalizations.resetWithEmail.tr(), // Using existing key
              style: GoogleFonts.jost(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            Text(
              AppLocalizations.enterEmailSendReset.tr(), // Using existing key
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            SizedBox(height: 40),

            // Email Input
            Text(
              AppLocalizations.email.tr(), // Using existing key
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.jost(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.enterEmail
                      .tr(), // Using existing key
                  hintStyle: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            Spacer(),

            // Send Reset Link Button
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendPasswordResetEmail,
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
                        AppLocalizations.sendResetLink
                            .tr(), // Using existing key
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

  // Fixed Email Password Reset using Firebase built-in method
  void _sendPasswordResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog(
        AppLocalizations.emailRequired.tr(),
      ); // Using existing key
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showErrorDialog(
        AppLocalizations.emailInvalid.tr(),
      ); // Using existing key
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String email = _emailController.text.trim();

      // Check if user exists in Firestore
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
          AppLocalizations.emailInvalid.tr(),
        ); // Using existing key
        return;
      }

      // Send Firebase password reset email
      await _auth.sendPasswordResetEmail(email: email);

      setState(() {
        _isLoading = false;
      });

      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      log('Password reset error: $e');

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            _showErrorDialog(
              AppLocalizations.emailInvalid.tr(),
            ); // Using existing key
            break;
          case 'invalid-email':
            _showErrorDialog(
              AppLocalizations.emailInvalid.tr(),
            ); // Using existing key
            break;
          case 'too-many-requests':
            _showErrorDialog(AppLocalizations.error.tr()); // Using existing key
            break;
          default:
            _showErrorDialog(AppLocalizations.error.tr()); // Using existing key
        }
      } else {
        _showErrorDialog(AppLocalizations.error.tr()); // Using existing key
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.error.tr(), // Using existing key
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.jost(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.ok.tr(), // Using existing key
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorsController.primaryColor,
              ),
            ),
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
        title: Text(
          AppLocalizations.success.tr(), // Using existing key
          style: GoogleFonts.jost(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          AppLocalizations.success.tr(), // Using existing key for content
          style: GoogleFonts.jost(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              AppLocalizations.ok.tr(), // Using existing key
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorsController.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
