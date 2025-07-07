import 'dart:io' show exit;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart'; // For Turkish date formatting
import 'package:notes_app/core/di/dependency_injection.dart';
import 'package:notes_app/presentation/controllers/theme_controller.dart';
import 'package:notes_app/presentation/pages/home_screen.dart';
import 'package:notes_app/services/database_service.dart';
import 'package:notes_app/services/media_service.dart';
import 'package:notes_app/services/notification_service.dart';

Future<void> main() async {
  // Disable Impeller renderer to fix blur effect crashes
  if (defaultTargetPlatform == TargetPlatform.android) {
    // Set up better error handling for renderer issues
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kReleaseMode && details.exception.toString().contains('Impeller')) {
        // Force exit the app if we're getting Impeller render errors in release mode
        // This prevents bad user experience with frozen UI
        exit(1);
      }
    };
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await DatabaseService.init();
  await MediaService.init();
  await NotificationService.init();

  // Initialize date formatting with error handling
  try {
    await initializeDateFormatting('tr_TR', null);
    // Also initialize English locale as fallback
    await initializeDateFormatting('en_US', null);
  } catch (e) {
    if (kDebugMode) {
      print('Date formatting initialization failed: $e');
    }
    // Continue without date formatting if it fails
  }

  // Initialize dependency injection
  await DependencyInjection.init();

  runApp(const MyApp());
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
    MediaService.dispose(); // Dispose MediaService when app is closing
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Consider disposing media service here if needed for background states
      // For now, we dispose it in the main dispose method.
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Get theme controller
    final themeController = Get.find<ThemeController>();

    return GetMaterialApp(
      title: 'Not Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeController.lightTheme,
      darkTheme: ThemeController.darkTheme,
      themeMode: themeController.themeMode,
      home: const HomeScreen(), // Using our Clean Architecture implementation
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
    );
  }
}
