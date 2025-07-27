
import 'dart:developer';

import 'package:arabicmarketplace/controller/notification_provider.dart';
import 'package:arabicmarketplace/controller/notification_service.dart';
import 'package:arabicmarketplace/controller/review_provider.dart';
import 'package:arabicmarketplace/firebase_options.dart';
import 'package:arabicmarketplace/resources/colors_controller.dart';
import 'package:arabicmarketplace/screens/account/controller/favorite_provider.dart';
import 'package:arabicmarketplace/screens/account/controller/my_ads_provider.dart';
import 'package:arabicmarketplace/screens/account/controller/profile_provider.dart';
import 'package:arabicmarketplace/screens/account/view/account_profile_page.dart';
import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
import 'package:arabicmarketplace/screens/chat/controller/chat_provider.dart';
import 'package:arabicmarketplace/screens/home/controller/home_provider.dart';
import 'package:arabicmarketplace/screens/notifications/controller/notification_handler.dart';
import 'package:arabicmarketplace/screens/notifications/controller/saved_search_provider.dart';
import 'package:arabicmarketplace/screens/product_detail/controller/product_detail_provider.dart';
import 'package:arabicmarketplace/screens/search_page/controller/search_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/view/success_page.dart';
import 'package:arabicmarketplace/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import 'package:shared_preferences/shared_preferences.dart'; // Import dart:ui and alias it as 'ui' to avoid conflicts
// Import your providers and other dependencies here
// import your firebase_options.dart file
// import your providers
// import your splash screen

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize EasyLocalization BEFORE runApp
  await EasyLocalization.ensureInitialized();
  
  runApp(
  EasyLocalization(
    supportedLocales: const [
      Locale('en'),
      Locale('ar'),
    ],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true, // Add this to match file names
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => UserProvider()),
          ChangeNotifierProvider(create: (context) => ItemProvider()),
          ChangeNotifierProvider(create: (context) => HomeProvider()),
          ChangeNotifierProvider(create: (_) => ProductDetailProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => ProfileProvider()),
          ChangeNotifierProvider(create: (_) => MyAdsProvider()),
          ChangeNotifierProvider(create: (_) => FavoritesProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => ReviewProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => AccountProfileProvider()),
          ChangeNotifierProvider(create: (_) => IndividualChatProvider()),
          ChangeNotifierProvider(create: (_) => SavedSearchProvider()),
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

// Update your main.dart to load saved language preference
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // fixAllProductsLocation();
 fetchTestCollection() ;
    _loadSavedLanguage();
    NotificationService().initialize();
  }

  

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('selected_language') ?? 'en';
      
      // Set the locale based on saved preference
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.setLocale(Locale(savedLanguage));
      });
    } catch (e) {
      print('Error loading saved language: $e');
    }
  }
  // Fix all products to have proper location data
Future<void> fixAllProductsLocation() async {
  try {
    print('🔧 FIXING ALL PRODUCTS LOCATION DATA...');
    
    // Get all products with null location data
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('status', isEqualTo: 'active')
        .get();
    
    print('Found ${productsSnapshot.docs.length} active products to fix');
    
    // Use Damascus as default city (most common)
    final defaultCityId = 'YklpLjwO0CIpXxxZHsKZ'; // Damascus from your list
    final defaultCityName = 'Damascus';
    
    // Get a district in Damascus
    final districtSnapshot = await FirebaseFirestore.instance
        .collection('districts')
        .where('cityId', isEqualTo: defaultCityId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    
    String? defaultDistrictId;
    String? defaultDistrictName;
    
    if (districtSnapshot.docs.isNotEmpty) {
      defaultDistrictId = districtSnapshot.docs.first.id;
      defaultDistrictName = districtSnapshot.docs.first.data()['name'];
      print('Using default district: $defaultDistrictName ($defaultDistrictId)');
    }
    
    // Update each product
    int updatedCount = 0;
    for (var doc in productsSnapshot.docs) {
      final data = doc.data();
      final productTitle = data['itemTitle'] ?? 'Unknown';
      
      // Check if product needs location update
      if (data['cityId'] == null || data['cityId'] == 'null') {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(doc.id)
            .update({
              'cityId': defaultCityId,
              'cityName': defaultCityName,
              'districtId': defaultDistrictId,
              'districtName': defaultDistrictName,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        
        updatedCount++;
        print('✅ Updated: $productTitle');
      }
    }
    
    print('🎉 Successfully updated $updatedCount products with location data');
    print('All products now have:');
    print('  - City: $defaultCityName ($defaultCityId)');
    print('  - District: $defaultDistrictName ($defaultDistrictId)');
    
  } catch (e) {
    print('❌ Error fixing products: $e');
  }
}

// Call once: await fixAllProductsLocation();

  fetchTestCollection() async {
    final testCollection = await FirebaseFirestore.instance.collection('chat_reports').get();

   var datas = testCollection.docs.map((e) => e.data()).toList();
   for (var data in datas) {
    log( 'Product is ${data}');
   }
   // log(datas.first.toString());
  }

  @override
Widget build(BuildContext context) {
  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, _) {
      return MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Delloni',
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: ColorsController.primaryColor),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black),
          ),
          // Force white backgrounds for all modal components
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            modalBackgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          dialogTheme:  DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          popupMenuTheme: const PopupMenuThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shadowColor: Colors.black26,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          dropdownMenuTheme: const DropdownMenuThemeData(
            menuStyle: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.white),
              surfaceTintColor: WidgetStatePropertyAll(Colors.white),
              shadowColor: WidgetStatePropertyAll(Colors.black26),
              elevation: WidgetStatePropertyAll(8),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
          menuTheme: const MenuThemeData(
            style: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.white),
              surfaceTintColor: WidgetStatePropertyAll(Colors.white),
              shadowColor: WidgetStatePropertyAll(Colors.black26),
              elevation: WidgetStatePropertyAll(8),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shadowColor: Colors.black26,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          datePickerTheme: const DatePickerThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shadowColor: Colors.black26,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: Colors.white,
            dialBackgroundColor: Colors.white,
            entryModeIconColor: Colors.black,
            helpTextStyle: TextStyle(color: Colors.black),
            hourMinuteTextStyle: TextStyle(color: Colors.black),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: ColorsController.darkBackground,
          colorScheme: ColorScheme.dark(
            primary: ColorsController.darkPrimaryColor,
            background: ColorsController.darkBackground,
            surface: ColorsController.darkSurface,
            onPrimary: ColorsController.darkText,
            onBackground: ColorsController.darkText,
            onSurface: ColorsController.darkText,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: ColorsController.darkSurface,
            foregroundColor: ColorsController.darkText,
            elevation: 0,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: ColorsController.darkText),
            bodyMedium: TextStyle(color: ColorsController.darkText),
          ),
          // FORCE WHITE BACKGROUNDS EVEN IN DARK MODE
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white, // Always white
            surfaceTintColor: Colors.white,
       
            modalBackgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white, // Always white
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          popupMenuTheme: const PopupMenuThemeData(
            color: Colors.white, // Always white
            surfaceTintColor: Colors.white,
            shadowColor: Colors.black26,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          dropdownMenuTheme: const DropdownMenuThemeData(
            menuStyle: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.white), // Always white
              surfaceTintColor: WidgetStatePropertyAll(Colors.white),
              shadowColor: WidgetStatePropertyAll(Colors.black26),
              elevation: WidgetStatePropertyAll(8),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
          menuTheme: const MenuThemeData(
            style: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.white), // Always white
              surfaceTintColor: WidgetStatePropertyAll(Colors.white),
              shadowColor: WidgetStatePropertyAll(Colors.black26),
              elevation: WidgetStatePropertyAll(8),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
          cardTheme: const CardThemeData(
            color: Colors.white, // Always white
            surfaceTintColor: Colors.white,
            shadowColor: Colors.black26,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          datePickerTheme: const DatePickerThemeData(
            backgroundColor: Colors.white, // Always white
            surfaceTintColor: Colors.white,
            shadowColor: Colors.black26,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: Colors.white, // Always white
            dialBackgroundColor: Colors.white,
            entryModeIconColor: Colors.black,
            helpTextStyle: TextStyle(color: Colors.black),
            hourMinuteTextStyle: TextStyle(color: Colors.black),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        themeMode: themeProvider.themeMode,
        builder: (context, child) {
          return Directionality(
            textDirection: context.locale.languageCode == 'ar'
                ? ui.TextDirection.rtl
                : ui.TextDirection.ltr,
            child: child!,
          );
        },
        home:
        //  SuccessPage()
        SplashScreen(),
      );
    },
  );
}}