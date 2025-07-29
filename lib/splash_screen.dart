import 'package:arabicmarketplace/screens/auth/view/login_screen.dart';
import 'package:arabicmarketplace/screens/custom_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Timer for 3 seconds
    Timer(const Duration(seconds: 3), () {
      // Navigate to next screen after 3 seconds
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FirebaseAuth.instance.currentUser==null? const LoginScreen(): CustomBottomNavigationBar(), // Replace with your next screen
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/icons/new_delloni.png'), // Replace with your image path
            fit: BoxFit.contain, // Covers the whole screen
          ),
        ),
        // Optional: Add overlay content like logo or loading indicator
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // You can add logo or app name here if needed
              // CircularProgressIndicator(
              //   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}