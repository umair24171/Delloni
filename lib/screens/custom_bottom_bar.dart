import 'dart:io';

import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/account/view/account_screen.dart';
import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
import 'package:arabicmarketplace/screens/chat/view/chat_screen.dart';
import 'package:arabicmarketplace/screens/home/view/home_screen.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_page.dart';
import 'package:arabicmarketplace/screens/sell_items/view/item_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  @override
  _CustomBottomNavigationBarState createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int selectedIndex = 0;

  final List<Widget> _screens = [
    MarketplaceHomePage(),
    ChatPage(),
    ItemDetailsPage(isMain: true,),
    SearchPage(isMain: true,),
    AccountScreen(),
  ];

  @override
  void initState() {
   getUserData();
    super.initState();
  }
  getUserData(){
    SchedulerBinding.instance.scheduleFrameCallback((callback){
 Provider.of<UserProvider>(context,listen: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[selectedIndex],
      bottomNavigationBar: Container(
        height:Platform.isIOS? 120:84,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItemWithAsset(
              iconPath: "assets/icons/Home.png",
              label: 'HOME',
              index: 0,
              isSelected: selectedIndex == 0,
            ),
            _buildNavItemWithAsset(
              iconPath: "assets/icons/Chat.png",
              label: 'CHATS',
              index: 1,
              isSelected: selectedIndex == 1,
            ),
            _buildSellButton(),
            _buildNavItem(
              icon: Icons.search_outlined,
              selectedIcon: Icons.search,
              label: 'Search',
              index: 3,
              isSelected: selectedIndex == 3,
            ),
            _buildNavItemWithAsset(
              iconPath: "assets/icons/User.png",
              label: 'ACCOUNT',
              index: 4,
              isSelected: selectedIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithAsset({
    required String iconPath,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildSellButton() {
  bool isSelected = selectedIndex == 2;
  return GestureDetector(
    onTap: () {
      setState(() {
        selectedIndex = 2;
      });
    },
    child: Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Elevated circular button
          Transform.translate(
            offset: Offset(0, -15), // Move icon up to create slope effect
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white, // Keep white background
                // Create gradient border effect
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorsController.primaryColor, // Top half border
                    Colors.black,                  // Bottom half border
                  ],
                  stops: [0.5, 0.5],
                ),
              ),
              child: Container(
                width: 58, // 70 - (6*2) = inner size
                height: 58,
                margin: EdgeInsets.all(6), // Creates 6px border
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white, // White inner background
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.red,
                  size: 32,
                ),
              ),
            ),
          ),
          // Text at normal level
          Transform.translate(
            offset: Offset(0, -15), // Adjust text position to align with others
            child: Text(
              'SELL',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
 
  String _getPageName(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Chats';
      case 2:
        return 'Sell';
      case 3:
        return 'Search';
      case 4:
        return 'Account';
      default:
        return 'Unknown';
    }
  }
}