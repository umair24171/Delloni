import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arabicmarketplace/screens/account/controller/account_service.dart';

class ReAuthDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final Function(String) onError;

  const ReAuthDialog({
    Key? key,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  @override
  State<ReAuthDialog> createState() => _ReAuthDialogState();
}

class _ReAuthDialogState extends State<ReAuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AccountService _accountService = AccountService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security_rounded,
                  size: 40,
                  color: Colors.orange[700],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Security Verification',
                style: GoogleFonts.jost(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                'For security reasons, please verify your identity by entering your email and password.',
                style: GoogleFonts.jost(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.jost(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: GoogleFonts.jost(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value?.isEmpty == true) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: GoogleFonts.jost(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.jost(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.lock_outlined, color: Colors.grey[600]),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value?.isEmpty == true) return 'Password is required';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Security note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This verification is required for sensitive operations.',
                        style: GoogleFonts.jost(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.jost(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleReauth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Verify',
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
            ],
          ),
        ),
      ),
    );
  }

  void _handleReauth() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _accountService.reauthenticateUser(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (result['success']) {
        Navigator.of(context).pop();
        widget.onSuccess();
      } else {
        widget.onError(result['message'] ?? 'Re-authentication failed');
      }
    } catch (e) {
      widget.onError('An error occurred during verification');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Helper function to show re-auth dialog
Future<void> showReAuthDialog(
  BuildContext context, {
  required VoidCallback onSuccess,
  required Function(String) onError,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ReAuthDialog(
      onSuccess: onSuccess,
      onError: onError,
    ),
  );
}