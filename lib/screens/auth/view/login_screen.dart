import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/auth/controller/auth_provider.dart';
import 'package:arabicmarketplace/screens/auth/view/location_screen.dart';
import 'package:arabicmarketplace/screens/auth/view/otp_verification_screen.dart';
import 'package:arabicmarketplace/screens/auth/view/register_screen.dart';
import 'package:arabicmarketplace/screens/forgot_password/view/forgot_password_screen.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:country_code_picker/country_code_picker.dart';
// Import your auth service and other screens
// import 'auth_service.dart';
// import 'location_screen.dart';
// import 'otp_verification_screen.dart';
// import 'create_account_screen.dart';
// import 'forgot_password_screen.dart';
// import 'colors_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isIndividualSelected = true;
  bool isPhoneSelected = true;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;
  String countryCode = '+1';

  // Firebase instances and AuthService
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AuthService _authService = AuthService(); // Add this line

  @override
  void initState() {
    super.initState();
    phoneController.text = '897688';
  }

  // Email and Password Login
  Future<void> _loginWithEmailPassword() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          String userType = userDoc.data()!['type'] ?? '';
          String expectedType = isIndividualSelected ? 'individual' : 'company';

          if (userType == expectedType) {
            _showSuccessSnackBar('Login successful!');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LocationScreen()),
            );
          } else {
            await _auth.signOut();
            _showErrorSnackBar('Account type mismatch. Please select the correct account type.');
          }
        } else {
          _showErrorSnackBar('User data not found. Please contact support.');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Phone Number Login using AuthService
  Future<void> _loginWithPhoneNumber() async {
    if (phoneController.text.trim().isEmpty || phoneController.text.trim().length < 7) {
      _showErrorSnackBar('Please enter a valid phone number');
      return;
    }

    setState(() => isLoading = true);

    try {
      String phoneNumber = '$countryCode${phoneController.text.trim()}';
      
      Map<String, dynamic> result = await _authService.initiatePhoneLogin(
        phoneNumber, 
        isIndividualSelected
      );

      if (result['success']) {
        if (result['autoVerified'] == true) {
          // Auto-verification successful
          _showSuccessSnackBar('Login successful!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LocationScreen()),
          );
        } else {
          // OTP sent, navigate to verification screen
          _navigateToOTPScreen(result['verificationId'], phoneNumber);
        }
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to send OTP. Please try again.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _navigateToOTPScreen(String verificationId, String phoneNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPVerificationScreen(
          verificationId: verificationId,
          phoneNumber: phoneNumber,
          isIndividual: isIndividualSelected,
        ),
      ),
    );
  }

  // Google Sign-In using AuthService
  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);

    try {
      Map<String, dynamic> result = await _authService.signInWithGoogle(
        type: isIndividualSelected ? 'individual' : 'company',
      );

      if (result['success']) {
        _showSuccessSnackBar('Google Sign-In successful!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LocationScreen()),
        );
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Google Sign-In failed. Please try again.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Facebook Sign-In using AuthService
  Future<void> _signInWithFacebook() async {
    setState(() => isLoading = true);

    try {
      Map<String, dynamic> result = await _authService.signInWithFacebook(
        type: isIndividualSelected ? 'individual' : 'company',
      );

      if (result['success']) {
        _showSuccessSnackBar('Facebook Sign-In successful!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LocationScreen()),
        );
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Facebook Sign-In failed. Please try again.');
    } finally {
      setState(() => isLoading = false);
    }
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

  void _handleLogin() {
    if (isPhoneSelected) {
      _loginWithPhoneNumber();
    } else {
      _loginWithEmailPassword();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Log In Title
              Text(
                'Log In',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Individual/Company Toggle
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
                            'Individual',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isIndividualSelected ? Colors.black : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 2,
                            color: isIndividualSelected ? Colors.black : Colors.transparent,
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
                            'Company',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: !isIndividualSelected ? Colors.black : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 2,
                            color: !isIndividualSelected ? Colors.black : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Login Type Toggle Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isPhoneSelected = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isPhoneSelected ? ColorsController.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Login with email',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: !isPhoneSelected ? Colors.white : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isPhoneSelected = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isPhoneSelected ? ColorsController.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Login with phone number',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isPhoneSelected ? Colors.white : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Input Fields (Phone or Email/Password)
              if (isPhoneSelected) ...[
                // Phone Number Input Field with Country Code Picker
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
                          controller: phoneController,
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
                            phoneController.clear();
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
           
              ] else ...[
                // Email and Password Fields
                // Email Field
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[500],
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.email),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: ColorsController.borderColor,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: ColorsController.borderColor,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.0,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: ColorsController.borderColor,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: ColorsController.borderColor,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.0,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                    hintText: 'Enter your password',
                    hintStyle: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9CA3AF),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          size: 20,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsController.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Login',
                          style: GoogleFonts.jost(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Social Login Buttons
              Row(
                children: [
                  // Google Sign In Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
                      label: Text(
                        'Google',
                        style: GoogleFonts.jost(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        side: BorderSide(color: ColorsController.borderColor),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Facebook Sign In Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _signInWithFacebook,
                      icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 20),
                      label: Text(
                        'Facebook',
                        style: GoogleFonts.jost(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        side: BorderSide(color: ColorsController.borderColor),
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Bottom Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => CreateAccountScreen())
                      );
                    },
                    child: Text(
                      'Sign up',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => ForgotPasswordScreen())
                      );
                    },
                    child: Text(
                      'Forget Password',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Terms and Privacy
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  children: [
                    const TextSpan(text: 'By signing up you agree to our '),
                    TextSpan(
                      text: 'Terms of Services',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}