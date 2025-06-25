// forgot_password_screen.dart
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/forgot_password/view/email_reset_screen.dart';
import 'package:arabicmarketplace/screens/forgot_password/view/phone_reset_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class ForgotPasswordScreen extends StatelessWidget {
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
              'Forgot password?',
              style: GoogleFonts.jost(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Please choose a method to request a\npassword reset.',
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            SizedBox(height: 40),
            
            // Email Option
            Container(
              width: double.infinity,
              height: 72,
              decoration: BoxDecoration(
                color: ColorsController.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EmailResetScreen()),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.email_outlined,
                            color: Color(0xFF2D5A27),
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Your email',
                                style: GoogleFonts.jost(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Enter your email',
                                style: GoogleFonts.jost(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Phone Number Option
            Container(
              width: double.infinity,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PhoneResetScreen()),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Phone number',
                                style: GoogleFonts.jost(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Enter your phone number',
                                style: GoogleFonts.jost(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFFF6B35),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            Spacer(),
            
            // Bottom text
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to sign up
                    },
                    child: Text(
                      'Sign up',
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}