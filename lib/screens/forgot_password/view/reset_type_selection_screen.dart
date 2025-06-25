// Screen 2: Phone Number Entry
import 'package:arabicmarketplace/screens/forgot_password/view/email_reset_screen.dart';
import 'package:arabicmarketplace/screens/forgot_password/view/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetTypeSelectionScreen extends StatefulWidget {
  @override
  _ResetTypeSelectionScreenState createState() => _ResetTypeSelectionScreenState();
}

class _ResetTypeSelectionScreenState extends State<ResetTypeSelectionScreen> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  bool isPhoneSelected = true;

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
            
            // Tab Selection
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isPhoneSelected = false;
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          'Email',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isPhoneSelected ? Colors.grey[400] : Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 2,
                          color: isPhoneSelected ? Colors.transparent : Color(0xFF2D5A27),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isPhoneSelected = true;
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          'Phone Number',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isPhoneSelected ? Colors.black : Colors.grey[400],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 2,
                          color: isPhoneSelected ? Color(0xFF2D5A27) : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 40),
            
            Text(
              isPhoneSelected ? 'Enter your phone number' : 'Enter your email',
              style: GoogleFonts.jost(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            Text(
              isPhoneSelected 
                ? 'Please enter a phone number to\nrequest a password reset.'
                : 'Please enter your email address to\nrequest a password reset.',
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            
            SizedBox(height: 40),
            
            // Input Field (Phone or Email)
            isPhoneSelected ? _buildPhoneInput() : _buildEmailInput(),
            
            SizedBox(height: 24),
            
            // Send Button
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EmailResetScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2D5A27),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Send',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

  Widget _buildPhoneInput() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '🇺🇸',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '+1',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey[300],
          ),
          Expanded(
            child: TextField(
              controller: phoneController,
              decoration: InputDecoration(
                hintText: '8976 88',
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
              keyboardType: TextInputType.phone,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                phoneController.clear();
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInput() {
    return Container(
      height: 56,
      // color: Colors.white,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.email_outlined,
              color: Colors.grey[500],
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Enter Email',
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
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                emailController.clear();
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}