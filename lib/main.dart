
import 'package:arabicmarketplace/controller/notification_provider.dart';
import 'package:arabicmarketplace/controller/review_provider.dart';
import 'package:arabicmarketplace/firebase_options.dart';
import 'package:arabicmarketplace/screens/account/controller/favorite_provider.dart';
import 'package:arabicmarketplace/screens/account/controller/my_ads_provider.dart';
import 'package:arabicmarketplace/screens/account/controller/profile_provider.dart';
import 'package:arabicmarketplace/screens/account/view/account_profile_page.dart';
import 'package:arabicmarketplace/screens/auth/controller/user_provider.dart';
import 'package:arabicmarketplace/screens/chat/controller/chat_provider.dart';
import 'package:arabicmarketplace/screens/home/controller/home_provider.dart';
import 'package:arabicmarketplace/screens/product_detail/controller/product_detail_provider.dart';
import 'package:arabicmarketplace/screens/search_page/controller/search_provider.dart';
import 'package:arabicmarketplace/screens/sell_items/controller/item_provider.dart';
import 'package:arabicmarketplace/splash_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

GlobalKey<NavigatorState> navigatorKey=GlobalKey<NavigatorState>();

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context)=>UserProvider()),
      ChangeNotifierProvider(create: (context)=>ItemProvider()),
       ChangeNotifierProvider(create: (context)=>HomeProvider()),
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
                ChangeNotifierProvider(create: (_) => ProductDetailProvider()),

  ],child:  EasyLocalization(
      supportedLocales: [
        Locale('en', 'US'), // English
        Locale('ar', 'SA'), // Arabic
      ],
      path: 'assets/translations',
      fallbackLocale: Locale('en', 'US'),child: const MyApp())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); 

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Delloni',
       localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      theme: ThemeData(
     scaffoldBackgroundColor: Colors.white,
    //  textButtonTheme: TextButtonThemeData(style: ),
    
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SplashScreen(),
    );
  }
}
