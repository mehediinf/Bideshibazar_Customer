// lib/main.dart

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/config/theme/app_theme.dart';
import 'presentation/splash/splash_view.dart';
import 'presentation/splash/splash_viewmodel.dart';
import 'presentation/auth/welcome_page.dart';
import 'presentation/main_screen.dart';
import 'presentation/checkout/checkout_view.dart';
import 'presentation/order_history/order_history_view.dart';
import 'presentation/update_testing_screen.dart';

import 'core/utils/cart_manager.dart';
import 'core/utils/seller_manager.dart';
import 'core/utils/wishlist_manager.dart';
import 'core/providers/user_provider.dart';
import 'core/utils/shared_prefs_helper.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/update_manager.dart';
import 'core/network/api_constants.dart';
import 'core/utils/app_error_helper.dart';

import 'presentation/home/home_viewmodel.dart';
import 'data/models/update_models.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Background FCM Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppErrorHelper.showGlobalSnackBar(
      scaffoldMessengerKey,
      details.exception,
      fallback: 'An unexpected app error occurred. Please try again.',
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppErrorHelper.showGlobalSnackBar(
      scaffoldMessengerKey,
      error,
      fallback: 'An unexpected app error occurred. Please try again.',
    );
    return true;
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);


  /// Save Base URL
  await SharedPrefsHelper.saveBaseUrl(ApiConstants.baseUrlWithoutApi);

  FirebaseMessagingService? fcmService;

  /// Firebase Init
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized');
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  /// Firebase Messaging
  if (Firebase.apps.isNotEmpty) {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      fcmService = FirebaseMessagingService();
      await fcmService.initialize();
      debugPrint('FCM Service initialized');
    } catch (e) {
      debugPrint('FCM init failed: $e');
      fcmService = null;
    }
  }

  /// Cart & Seller Init
  try {
    await CartManager().loadCart();
    await SellerManager().loadSellerIds();
    debugPrint('Cart & Seller loaded');
  } catch (e) {
    debugPrint('Manager init failed: $e');
  }

  /// Sync Cart if Logged In
  final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
  if (isLoggedIn) {
    try {
      await CartManager().syncWithServer();
      debugPrint('Cart synced');
    } catch (e) {
      debugPrint('Cart sync failed: $e');
    }
  }


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUserData()),
        ChangeNotifierProvider(create: (_) => CartManager()),
        ChangeNotifierProvider(create: (_) => WishlistManager()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        if (fcmService != null)
          Provider<FirebaseMessagingService>.value(value: fcmService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Resume Android In-App Update
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final updateManager = UpdateManager(
          context: context,
          apiUrl:
          '${UpdateConfig.baseUrl}${UpdateConfig.versionEndpoint}',
        );
        updateManager.resumeImmediateUpdateIfNeeded();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BideshiBazar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      builder: (context, child) {
        ErrorWidget.builder = (details) {
          return AppErrorView(
            message: AppErrorHelper.toUserMessage(
              details.exception,
              fallback: 'This screen could not be shown properly.',
            ),
          );
        };

        return child ?? const SizedBox.shrink();
      },
      home: const SplashView(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashView());
          case '/welcome':
            return MaterialPageRoute(builder: (_) => const WelcomePage());
          case '/home':
            return MaterialPageRoute(builder: (_) => const MainScreen());
          case '/checkout':
            return MaterialPageRoute(builder: (_) => const CheckoutView());
          case '/orders':
          case '/order-history':
            return MaterialPageRoute(
              builder: (_) => const OrderHistoryView(),
            );
          case '/notifications':
            return MaterialPageRoute(
              builder: (_) => const OrderHistoryView(),
              settings: settings,
            );
          case '/update-test':
            if (UpdateConfig.enableTestingScreen) {
              return MaterialPageRoute(
                builder: (_) => const UpdateTestingScreen(),
              );
            }
            return MaterialPageRoute(
              builder: (_) => const MainScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const MainScreen(),
            );
        }
      },
    );
  }
}
