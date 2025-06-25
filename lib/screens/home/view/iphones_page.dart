import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IphonesPage extends StatelessWidget {
  const IphonesPage({Key? key}) : super(key: key);

  final List<String> iPhoneModels = const [
    'See all in Iphones',
    'Iphones 16 pro max',
    'Iphone 16 pro',
    'Iphone 15',
    'Iphone 14 pro max',
    'Iphone 11',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20,
          ),
        ),
        title: Text(
          'Iphones',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by Categories',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // iPhone Models List
            Expanded(
              child: ListView.builder(
                itemCount: iPhoneModels.length,
                itemBuilder: (context, index) {
                  final model = iPhoneModels[index];
                  final isFirst = index == 0;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                model,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isFirst ? const Color(0xFF0D5E2A) : Colors.black,
                                  fontWeight: isFirst ? FontWeight.w500 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}