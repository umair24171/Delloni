import 'dart:io';

import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/account/view/account_screen.dart';
import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
import 'package:arabicmarketplace/screens/chat/view/chat_screen.dart';
import 'package:arabicmarketplace/screens/home/view/home_screen.dart';
import 'package:arabicmarketplace/screens/search_page/view/search_page.dart';
import 'package:arabicmarketplace/screens/sell_items/view/item_details_screen.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
// Import your other pages (MarketplaceHomePage, ChatPage, etc.)

class CustomBottomNavigationBar extends StatefulWidget {
  @override
  _CustomBottomNavigationBarState createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int selectedIndex = 0;

  final List<Widget> _screens = [
    MarketplaceHomePage(),
    ChatPage(),
    ItemDetailsPage(isMain: true),
    SearchPage(isMain: true),
    AccountScreen(),
  ];

  @override
  void initState() {
    getUserData();
    super.initState();
  }

  getUserData() {
    SchedulerBinding.instance.scheduleFrameCallback((callback) {
      Provider.of<UserProvider>(context, listen: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[selectedIndex],
      bottomNavigationBar: Container(
        height: Platform.isIOS ? 120 : 84,
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
              label: AppLocalizations.home.tr(),
              index: 0,
              isSelected: selectedIndex == 0,
            ),
            _buildNavItemWithAsset(
              iconPath: "assets/icons/Chat.png",
              label: AppLocalizations.chats.tr(),
              index: 1,
              isSelected: selectedIndex == 1,
            ),
            _buildSellButton(),
            _buildNavItem(
              icon: Icons.search_outlined,
              selectedIcon: Icons.search,
              label: AppLocalizations.search.tr(),
              index: 3,
              isSelected: selectedIndex == 3,
            ),
            _buildNavItemWithAsset(
              iconPath: "assets/icons/User.png",
              label: AppLocalizations.account.tr(),
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
            Transform.translate(
              offset: Offset(0, -15),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ColorsController.primaryColor,
                      Colors.black,
                    ],
                    stops: [0.5, 0.5],
                  ),
                ),
                child: Container(
                  width: 58,
                  height: 58,
                  margin: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -15),
              child: Text(
                AppLocalizations.sell.tr(),
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
        return AppLocalizations.home.tr();
      case 1:
        return AppLocalizations.chats.tr();
      case 2:
        return AppLocalizations.sell.tr();
      case 3:
        return AppLocalizations.search.tr();
      case 4:
        return AppLocalizations.account.tr();
      default:
        return AppLocalizations.unknown.tr();
    }
  }
}