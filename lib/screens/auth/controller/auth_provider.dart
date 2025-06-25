// Updated AuthService.dart - Standard Phone Auth Flow
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:email_otp/email_otp.dart';
import 'dart:io';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // STANDARD PHONE AUTHENTICATION FLOW
  
  // Step 1: Initiate phone verification (for login)
  Future<Map<String, dynamic>> initiatePhoneLogin(String phoneNumber, bool isIndividual) async {
    try {
      Completer<Map<String, dynamic>> completer = Completer();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed - sign in immediately
          try {
            UserCredential userCredential = await _auth.signInWithCredential(credential);
            User? user = userCredential.user;
            
            if (user != null) {
              // Check if user document exists and validate type
              Map<String, dynamic> result = await _validateUserType(user.uid, isIndividual);
              completer.complete({
                'success': result['success'],
                'message': result['message'],
                'autoVerified': true,
                'user': user,
              });
            } else {
              completer.complete({
                'success': false,
                'message': 'Authentication failed',
              });
            }
          } catch (e) {
            completer.complete({
              'success': false,
              'message': 'Auto-verification failed: ${e.toString()}',
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          completer.complete({
            'success': false,
            'message': _getPhoneAuthErrorMessage(e),
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          completer.complete({
            'success': true,
            'verificationId': verificationId,
            'resendToken': resendToken,
            'message': 'OTP sent successfully',
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout handled automatically
        },
        timeout: const Duration(seconds: 60),
      );
      
      return await completer.future;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to initiate phone verification: ${e.toString()}',
      };
    }
  }
// Facebook Sign-In
  Future<Map<String, dynamic>> signInWithFacebook({
    required String type,
    String? phone,
    String? language,
    String? companyName,
    String? address,
    String? registerId,
  }) async {
    try {
      // Trigger the sign-in flow
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      // Check if login was successful
      if (loginResult.status != LoginStatus.success) {
        return {
          'success': false,
          'message': 'Facebook Sign-In cancelled or failed',
        };
      }

      // Get the access token
      final AccessToken accessToken = loginResult.accessToken!;

      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential = 
          FacebookAuthProvider.credential(accessToken.tokenString);

      // Sign in to Firebase with the Facebook credential
      UserCredential userCredential = 
          await _auth.signInWithCredential(facebookAuthCredential);
      User? user = userCredential.user;

      if (user != null) {
        // Check if user document exists
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!doc.exists) {
          // Create new user document
          if (type == 'individual') {
            await _firestore.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'type': 'individual',
              'email': user.email ?? '',
              'phone': phone ?? '',
              'language': language ?? 'English',
              'createdAt': FieldValue.serverTimestamp(),
              'isEmailVerified': true, // Facebook users are auto-verified
              'isPhoneVerified': false,
            });
          } else {
            await _firestore.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'type': 'company',
              'companyName': companyName ?? user.displayName ?? '',
              'email': user.email ?? '',
              'phone': phone ?? '',
              'address': address ?? '',
              'registerId': registerId ?? '',
              'language': language ?? 'English',
              'createdAt': FieldValue.serverTimestamp(),
              'isEmailVerified': true,
              'isPhoneVerified': false,
            });
          }
        } else {
          // Check if existing user type matches selected type
          String existingType = doc.get('type') ?? '';
          String expectedType = type == 'individual' ? 'individual' : 'company';
          
          if (existingType != expectedType) {
            await _auth.signOut();
            await FacebookAuth.instance.logOut();
            return {
              'success': false,
              'message': 'Account type mismatch. This Facebook account is registered as ${existingType == 'individual' ? 'Individual' : 'Company'}.',
            };
          }
        }

        return {
          'success': true,
          'user': user,
          'message': 'Facebook Sign-In successful',
        };
      }
      
      return {
        'success': false,
        'message': 'Facebook Sign-In failed',
      };
    } catch (e) {
      // Handle specific Facebook Auth errors
      if (e.toString().contains('account-exists-with-different-credential')) {
        return {
          'success': false,
          'message': 'An account already exists with this email using a different sign-in method.',
        };
      }
      return {
        'success': false,
        'message': 'Facebook Sign-In failed: ${e.toString()}',
      };
    }
  }
  // Step 2: Verify OTP and complete login
  Future<Map<String, dynamic>> verifyPhoneOtpLogin(
    String verificationId, 
    String otp, 
    bool isIndividual
  ) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Validate user type after successful authentication
        Map<String, dynamic> result = await _validateUserType(user.uid, isIndividual);
        return {
          'success': result['success'],
          'message': result['message'],
          'user': user,
        };
      }
      
      return {
        'success': false,
        'message': 'Authentication failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _getOtpVerificationErrorMessage(e),
      };
    }
  }

  // Helper method to validate user type after authentication
  Future<Map<String, dynamic>> _validateUserType(String uid, bool isIndividual) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        // User authenticated but no Firestore document exists
        await _auth.signOut();
        return {
          'success': false,
          'message': 'No account found. Please sign up first.',
        };
      }
      
      String userType = userDoc.get('type') ?? '';
      String expectedType = isIndividual ? 'individual' : 'company';
      
      if (userType != expectedType) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Account type mismatch. This phone number is registered as ${userType == 'individual' ? 'Individual' : 'Company'}.',
        };
      }
      
      return {
        'success': true,
        'message': 'Login successful',
      };
    } catch (e) {
      await _auth.signOut();
      return {
        'success': false,
        'message': 'Error validating user: ${e.toString()}',
      };
    }
  }

  // PHONE REGISTRATION (for new users)
  
  // Step 1: Register with phone number
  Future<Map<String, dynamic>> registerWithPhone({
    required String phoneNumber,
    required bool isIndividual,
    required String language,
    // Individual fields
    String? email,
    // Company fields
    String? companyName,
    String? address,
    String? registerId,
    File? profileImage,
  }) async {
    try {
      Completer<Map<String, dynamic>> completer = Completer();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification for registration
          try {
            UserCredential userCredential = await _auth.signInWithCredential(credential);
            User? user = userCredential.user;
            
            if (user != null) {
              // Create user document after successful authentication
              bool docCreated = await _createUserDocument(
                user: user,
                phoneNumber: phoneNumber,
                isIndividual: isIndividual,
                language: language,
                email: email,
                companyName: companyName,
                address: address,
                registerId: registerId,
                profileImage: profileImage,
              );
              
              if (docCreated) {
                completer.complete({
                  'success': true,
                  'message': 'Account created successfully',
                  'user': user,
                  'autoVerified': true,
                });
              } else {
                await _auth.signOut();
                completer.complete({
                  'success': false,
                  'message': 'Failed to create user profile',
                });
              }
            }
          } catch (e) {
            completer.complete({
              'success': false,
              'message': 'Registration failed: ${e.toString()}',
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          completer.complete({
            'success': false,
            'message': _getPhoneAuthErrorMessage(e),
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          completer.complete({
            'success': true,
            'verificationId': verificationId,
            'resendToken': resendToken,
            'message': 'OTP sent for registration',
            'pendingRegistration': {
              'phoneNumber': phoneNumber,
              'isIndividual': isIndividual,
              'language': language,
              'email': email,
              'companyName': companyName,
              'address': address,
              'registerId': registerId,
              'profileImage': profileImage,
            },
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
      
      return await completer.future;
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  // Step 2: Complete phone registration with OTP
  Future<Map<String, dynamic>> completePhoneRegistration({
    required String verificationId,
    required String otp,
    required Map<String, dynamic> registrationData,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Create user document after successful OTP verification
        bool docCreated = await _createUserDocument(
          user: user,
          phoneNumber: registrationData['phoneNumber'],
          isIndividual: registrationData['isIndividual'],
          language: registrationData['language'],
          email: registrationData['email'],
          companyName: registrationData['companyName'],
          address: registrationData['address'],
          registerId: registrationData['registerId'],
          profileImage: registrationData['profileImage'],
        );
        
        if (docCreated) {
          return {
            'success': true,
            'message': 'Account created successfully',
            'user': user,
          };
        } else {
          await _auth.signOut();
          return {
            'success': false,
            'message': 'Failed to create user profile',
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Authentication failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _getOtpVerificationErrorMessage(e),
      };
    }
  }

  // Helper method to create user document in Firestore
  Future<bool> _createUserDocument({
    required User user,
    required String phoneNumber,
    required bool isIndividual,
    required String language,
    String? email,
    String? companyName,
    String? address,
    String? registerId,
    File? profileImage,
  }) async {
    try {
      String? imageUrl;
      if (profileImage != null) {
        final storageRef = _storage.ref().child('profiles/${user.uid}/${profileImage.path.split('/').last}');
        await storageRef.putFile(profileImage);
        imageUrl = await storageRef.getDownloadURL();
      }

      Map<String, dynamic> userData = {
        'uid': user.uid,
        'type': isIndividual ? 'individual' : 'company',
        'phone': phoneNumber,
        'language': language,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
        'isPhoneVerified': true, // Phone is verified through Firebase Auth
      };

      if (isIndividual) {
        userData.addAll({
          'email': email ?? '',
        });
      } else {
        userData.addAll({
          'companyName': companyName ?? '',
          'email': email ?? '',
          'address': address ?? '',
          'registerId': registerId ?? '',
          'profileImage': imageUrl,
        });
      }

      await _firestore.collection('users').doc(user.uid).set(userData);
      return true;
    } catch (e) {
      print('Error creating user document: $e');
      return false;
    }
  }

  // EXISTING EMAIL/PASSWORD AND GOOGLE SIGN-IN METHODS (keep as they are)
  
  Future<bool> sendEmailOtp(String email) async {
    EmailOTP.config(
      appEmail: 'umairbilal207@gmail.com',
      appName: "Delloni",
      otpLength: 4,
      expiry: 120000,
      otpType: OTPType.numeric,
    );
    
    EmailOTP.setTemplate(template: _getOtpEmailTemplate());
    
    final result = await EmailOTP.sendOTP(email: email);
    return result;
  }

  String _getOtpEmailTemplate() {
    return '''
    <div style="background-color: #f9f9f9; padding: 20px; font-family: Arial, sans-serif; line-height: 1.6;">
      <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);">
        <div style="text-align: center;">
          <h1 style="color: #EC6A5A; margin-bottom: 20px;">{{appName}}</h1>
          <hr style="border: none; height: 1px; background-color: #eeeeee; margin: 20px 0;">
          <p style="font-size: 18px; color: #333333;">Hello,</p>
          <p style="font-size: 16px; color: #666666;">Your OTP code is:</p>
          <div style="font-size: 24px; font-weight: bold; color: #EC6A5A; margin: 20px 0;">
            {{otp}}
          </div>
          <p style="font-size: 14px; color: #999999;">This OTP is valid for 2 minutes.</p>
          <hr style="border: none; height: 1px; background-color: #eeeeee; margin: 20px 0;">
          <p style="font-size: 14px; color: #666666;">If you did not request this OTP, please ignore this email.</p>
          <p style="font-size: 14px; color: #666666;">Thank you for using our service.</p>
        </div>
      </div>
      <div style="text-align: center; margin-top: 20px;">
        <p style="font-size: 12px; color: #999999;">&copy; {{appName}}. All rights reserved.</p>
      </div>
    </div>
    ''';
  }

  Future<bool> sendOtp(String email) async {
    try {
      bool result = await sendEmailOtp(email);
      return result;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    try {
      bool result = EmailOTP.verifyOTP(otp: otp);
      if (result) {
        User? user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'isEmailVerified': true,
          });
        }
      }
      return result;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // RESEND OTP
  Future<Map<String, dynamic>> resendPhoneOtp(String phoneNumber) async {
    try {
      Completer<Map<String, dynamic>> completer = Completer();
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          completer.complete({
            'success': true,
            'credential': credential,
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          completer.complete({
            'success': false,
            'message': e.message ?? 'Verification failed',
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          completer.complete({
            'success': true,
            'verificationId': verificationId,
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
      return await completer.future;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ERROR MESSAGE HELPERS
  String _getPhoneAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'app-not-authorized':
        return 'App not authorized. Please contact support';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return e.message ?? 'Phone verification failed';
    }
  }

  String _getOtpVerificationErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-verification-code':
          return 'Invalid OTP code';
        case 'session-expired':
          return 'OTP expired. Please request a new one';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later';
        default:
          return e.message ?? 'OTP verification failed';
      }
    }
    return 'OTP verification failed';
  }

  // EXISTING METHODS (keep unchanged)
  Future<Map<String, dynamic>> registerIndividual({
    required String email,
    required String password,
    required String phone,
    required String language,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'type': 'individual',
          'email': email,
          'phone': phone,
          'language': language,
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': false,
        });

        bool otpSent = await sendOtp(email);
        if (!otpSent) {
          return {
            'success': false,
            'message': 'Failed to send OTP',
          };
        }

        return {
          'success': true,
          'user': user,
          'message': 'Individual account created, OTP sent',
        };
      }
      return {
        'success': false,
        'message': 'User creation failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> registerCompany({
    required String companyName,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String registerId,
    required String language,
    File? profileImage,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        String? imageUrl;
        if (profileImage != null) {
          final storageRef = _storage.ref().child('company_profiles/${user.uid}/${profileImage.path.split('/').last}');
          await storageRef.putFile(profileImage);
          imageUrl = await storageRef.getDownloadURL();
        }

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'type': 'company',
          'companyName': companyName,
          'email': email,
          'phone': phone,
          'address': address,
          'registerId': registerId,
          'language': language,
          'profileImage': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': false,
        });

        bool otpSent = await sendOtp(email);
        if (!otpSent) {
          return {
            'success': false,
            'message': 'Failed to send OTP',
          };
        }

        return {
          'success': true,
          'user': user,
          'message': 'Company account created, OTP sent',
        };
      }
      return {
        'success': false,
        'message': 'User creation failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle({
    required String type,
    String? phone,
    String? language,
    String? companyName,
    String? address,
    String? registerId,
  }) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google Sign-In cancelled',
        };
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          if (type == 'individual') {
            await _firestore.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'type': 'individual',
              'email': user.email,
              'phone': phone ?? '',
              'language': language ?? 'English',
              'createdAt': FieldValue.serverTimestamp(),
              'isEmailVerified': true,
            });
          } else {
            await _firestore.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'type': 'company',
              'companyName': companyName ?? '',
              'email': user.email,
              'phone': phone ?? '',
              'address': address ?? '',
              'registerId': registerId ?? '',
              'language': language ?? 'English',
              'createdAt': FieldValue.serverTimestamp(),
              'isEmailVerified': true,
            });
          }
        }

        return {
          'success': true,
          'user': user,
          'message': 'Google Sign-In successful',
        };
      }
      return {
        'success': false,
        'message': 'Google Sign-In failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}