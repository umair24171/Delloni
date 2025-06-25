import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Language',
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // // Header
              // Text(
              //   'Language',
              //   style: GoogleFonts.jost(
              //     fontSize: 24,
              //     fontWeight: FontWeight.w600,
              //     color: Colors.black,
              //   ),
              // ),
              const SizedBox(height: 40),
              // Select language text
              Center(
                child: Text(
                  'Select your Language',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 260),
              // Language buttons
              Center(child: Container(width: 250,child: _buildLanguageButton('English'))),
              const SizedBox(height: 20),
              Center(child: Container(width: 250,child: _buildLanguageButton('Arabic'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String language) {
    bool isSelected = selectedLanguage == language;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedLanguage = language;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:  ColorsController.primaryColor ,
          fixedSize: Size(150, 50),
          
          
          padding: const EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),  
          elevation: 0,
        ),
        child: Text(
          language,
          style: GoogleFonts.khula(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}