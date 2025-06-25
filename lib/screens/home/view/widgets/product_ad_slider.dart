import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductAdSlider extends StatefulWidget {
  @override
  _ProductAdSliderState createState() => _ProductAdSliderState();
}

class _ProductAdSliderState extends State<ProductAdSlider> {
  PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<ProductAd> ads = [
    ProductAd(
      brand: 'Nike',
      product: 'Free Metcon',
      price: '\$120.99',
      gradientColors: [Colors.orange[400]!, Colors.yellow[400]!],
      imageAsset: 'assets/images/Yellow Shoe.png', // You can replace with actual assets
    ),
    ProductAd(
      brand: 'Adidas',
      product: 'Ultra Boost 22',
      price: '\$180.00',
      gradientColors: [Colors.blue[400]!, Colors.cyan[400]!],
      imageAsset: 'assets/images/Yellow Shoe.png',
    ),
    ProductAd(
      brand: 'Puma',
      product: 'RS-X Reinvention',
      price: '\$110.50',
      gradientColors: [Colors.purple[400]!, Colors.pink[400]!],
      imageAsset: 'assets/images/Yellow Shoe.png',
    ),
    ProductAd(
      brand: 'Reebok',
      product: 'Classic Leather',
      price: '\$85.99',
      gradientColors: [Colors.green[400]!, Colors.teal[400]!],
      imageAsset: 'assets/images/Yellow Shoe.png',
    ),
    ProductAd(
      brand: 'Converse',
      product: 'Chuck 70 Hi',
      price: '\$75.00',
      gradientColors: [Colors.red[400]!, Colors.orange[400]!],
      imageAsset: 'assets/images/Yellow Shoe.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: ad.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.circle,
                          size: 120,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Product Information
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Ad',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            ad.brand,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            ad.product,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            ad.price,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Shoe Image (placeholder with icon)
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Container(
                          width: 100,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.sports_soccer,
                            size: 40,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                    // Favorite Button
                    Positioned(
                      right: 16,
                      top: 16,
                      child: GestureDetector(
                        onTap: () {
                          print('Favorited ${ad.brand} ${ad.product}');
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.favorite_border,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16),
        // Page Indicators (Dots)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            ads.length,
            (index) => AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index 
                    ? Colors.black87 
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class ProductAd {
  final String brand;
  final String product;
  final String price;
  final List<Color> gradientColors;
  final String imageAsset;

  ProductAd({
    required this.brand,
    required this.product,
    required this.price,
    required this.gradientColors,
    required this.imageAsset,
  });
}

// Usage Example:
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Product Showcase'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Featured Products',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 16),
            ProductAdSlider(),
            SizedBox(height: 32),
            // Additional content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popular Categories',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Discover the latest trends in footwear from top brands around the world.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}