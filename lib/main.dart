
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
import 'package:arabicmarketplace/screens/chat/view/chat_screen.dart';
import 'package:arabicmarketplace/screens/home/controller/home_provider.dart';
import 'package:arabicmarketplace/screens/notifications/controller/saved_search_provider.dart';
import 'package:arabicmarketplace/screens/notifications/view/notification_saved_search_page.dart';
import 'package:arabicmarketplace/screens/notifications/view/notifications_page.dart';
import 'package:arabicmarketplace/screens/product_detail/controller/product_detail_provider.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:arabicmarketplace/screens/search_page/controller/search_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import 'package:shared_preferences/shared_preferences.dart'; // Import dart:ui and alias it as 'ui' to avoid conflicts
// Import your providers and other dependencies here
// import your firebase_options.dart file
// import your providers
// import your splash screen

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// Store initial message for later processing
RemoteMessage? initialMessage;

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
   PaintingBinding.instance.imageCache.maximumSize = 1000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 * 1024 * 1024; // 200MB
  
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
class MyApp extends StatefulWidget with WidgetsBindingObserver{
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Load saved language first
      await _loadSavedLanguage();
      
      // Initialize notification service
      await NotificationService().initialize();
      
      // Clear app badge
      await NotificationService().clearAppBadge();
      
      // Handle initial message after a delay to ensure navigation is ready
      await _handleInitialMessage();
      
    } catch (e) {
      print('Error initializing app: $e');
    }
  }
     // Handle initial message when app is opened from terminated state
  Future<void> _handleInitialMessage() async {
    try {
      final RemoteMessage? message = await FirebaseMessaging.instance.getInitialMessage();
      
      if (message != null) {
        print('App opened from terminated state: ${message.messageId}');
        
        // Store the message to handle it after the widget tree is fully built
        initialMessage = message;
        
        // Wait for the widget tree to be fully built before navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Add additional delay to ensure everything is ready
          Future.delayed(const Duration(milliseconds: 1000), () {
            _handleTerminatedStateNavigation(message);
          });
        });
      }
    } catch (e) {
      print('Error handling initial message: $e');
    }
  }

  // Handle navigation when app was opened from terminated state
  void _handleTerminatedStateNavigation(RemoteMessage message) {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        print('Navigation context not available, retrying...');
        // Retry after another delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleTerminatedStateNavigation(message);
        });
        return;
      }

      // Create payload string
      final payload = message.data.toString();
      
      // Navigate based on message data
      _navigateBasedOnPayload(context, message.data, isFromTerminatedState: true);
      
    } catch (e) {
      print('Error handling terminated state navigation: $e');
    }
  }

  // Enhanced navigation method
  void _navigateBasedOnPayload(BuildContext context, Map<String, dynamic> data, {bool isFromTerminatedState = false}) {
    try {
      // Extract navigation data
      final String? chatId = data['chatId'];
      final String? itemId = data['itemId'];
      final String? productId = data['productId'];
      final String? savedSearchName = data['savedSearchName'];
      final String type = data['type'] ?? 'general';

      Widget? targetScreen;
      
      // Determine target screen based on data
      if (chatId != null) {
        targetScreen = ChatPage();
      } else if (productId != null) {
        targetScreen = ProductDetailScreen(productId: productId);
      } else if (itemId != null) {
        targetScreen = ProductDetailScreen(productId: itemId);
      } else if (savedSearchName != null) {
        targetScreen = const SavedSearchesPage();
      } else {
        targetScreen = const NotificationsPage();
      }

      // Navigate to target screen
      if (targetScreen != null) {
        if (isFromTerminatedState) {
          // For terminated state, use pushAndRemoveUntil to replace the entire stack
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => targetScreen!),
            // (route) => false, // Remove all previous routes
          );
        } else {
          // For running state, use regular push
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => targetScreen!),
          );
        }
      }
      
    } catch (e) {
      print('Error navigating based on payload: $e');
      // Fallback navigation
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const NotificationsPage()),
      );
    }
  }
  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Clear badge when app comes to foreground
    if (state == AppLifecycleState.resumed) {
    NotificationService().clearAppBadge();
    }
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
    final testCollection = await FirebaseFirestore.instance.collection('contact_submissions').get();

   var datas = testCollection.docs.map((e) => e.data()).toList();
   for (var data in datas) {
    log( 'Product is ${data}');
   }
   // log(datas.first.toString());
  }
@override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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