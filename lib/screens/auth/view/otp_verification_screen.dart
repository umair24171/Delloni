// Updated OTPVerificationScreen.dart - Localized with existing keys only
import 'package:arabicmarketplace/screens/auth/controller/auth_provider.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:arabicmarketplace/screens/auth/view/location_screen.dart';
import 'package:easy_localization/easy_localization.dart'; // Add this import

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final bool isIndividual;
  final bool isForLogin; // New parameter to distinguish login vs registration
  final Map<String, dynamic>? registrationData; // For registration flow

  const OTPVerificationScreen({
    Key? key,
    required this.verificationId,
    required this.phoneNumber,
    required this.isIndividual,
    this.isForLogin = true, // Default to login
    this.registrationData,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLoading = false;

  Future<void> _verifyOTP() async {
    if (otpController.text.trim().isEmpty ||
        otpController.text.trim().length != 6) {
      _showErrorSnackBar(
        '${AppLocalizations.enterOtp.tr()} ${AppLocalizations.required.tr()}',
      ); // Using existing keys
      return;
    }

    setState(() => isLoading = true);

    try {
      Map<String, dynamic> result;

      if (widget.isForLogin) {
        // Use login verification
        result = await _authService.verifyPhoneOtpLogin(
          widget.verificationId,
          otpController.text.trim(),
          widget.isIndividual,
        );
      } else {
        // Use registration verification
        result = await _authService.completePhoneRegistration(
          verificationId: widget.verificationId,
          otp: otpController.text.trim(),
          registrationData: widget.registrationData ?? {},
        );
      }

      setState(() => isLoading = false);

      if (result['success']) {
        _showSuccessSnackBar(
          result['message'] ?? AppLocalizations.success.tr(),
        ); // Using existing key
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LocationScreen()),
        );
      } else {
        _showErrorSnackBar(
          result['message'] ?? AppLocalizations.error.tr(),
        ); // Using existing key
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar(AppLocalizations.error.tr()); // Using existing key
    }
  }

  Future<void> _resendOTP() async {
    setState(() => isLoading = true);

    try {
      Map<String, dynamic> result = await _authService.resendPhoneOtp(
        widget.phoneNumber,
      );

      setState(() => isLoading = false);

      if (result['success']) {
        _showSuccessSnackBar(
          AppLocalizations.success.tr(),
        ); // Using existing key
        // You might want to update the verificationId here if needed
      } else {
        _showErrorSnackBar(
          result['message'] ?? AppLocalizations.error.tr(),
        ); // Using existing key
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar(AppLocalizations.error.tr()); // Using existing key
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.verifyOtp.tr(), // Using existing key
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Text(
              AppLocalizations.enterOtp.tr(), // Using existing key
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${AppLocalizations.phone.tr()}: ${widget.phoneNumber}', // Using existing key
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            const SizedBox(height: 40),

            // OTP Input Field
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
                hintText: AppLocalizations.enterOtp.tr(), // Using existing key
                hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 8),
                counterText: '',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 20),
              ),
            ),

            const SizedBox(height: 30),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        AppLocalizations.verifyOtp.tr(), // Using existing key
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Resend OTP
            Center(
              child: TextButton(
                onPressed: isLoading ? null : _resendOTP,
                child: Text(
                  AppLocalizations.resendOtp.tr(), // Using existing key
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Help Text - Using existing keys where possible
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.helpSupport.tr(), // Using existing key
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• ${AppLocalizations.phone.tr()}\n• ${AppLocalizations.loading.tr()}\n• ${AppLocalizations.resendOtp.tr()}', // Using existing keys creatively
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
}
