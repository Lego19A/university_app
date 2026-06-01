// ============================================================
// MAIN.DART - App entry point.
// This file initializes Firebase, wraps the app in Riverpod's
// ProviderScope for state management, and applies the global
// AppTheme so all widgets inherit the correct design system.
//
// Changes from original:
//   - Added ProviderScope wrapper for Riverpod state management
//   - Added appTheme to MaterialApp for global styling
//   - Home is still LoginPage (your existing flow is preserved)
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod for state management
import 'package:university_app/login_page.dart';
import 'package:university_app/core/theme/app_theme.dart'; // Global theme
import 'package:university_app/firebase_options.dart'; // Web configuration

void main() async {
  // -- Ensure Flutter bindings are initialized before async calls --
  WidgetsFlutterBinding.ensureInitialized();

  // -- Initialize Firebase (required for FirebaseAuth login) --
  // On the web, this REQUIRES the options parameter.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // -- Run the app wrapped in ProviderScope --
  // ProviderScope is required by Riverpod to manage state.
  // It must be at the root of the widget tree.
  // If you don't want Riverpod, remove this wrapper and
  // use MyApp() directly in runApp().
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // -- Hide the debug banner in the top-right corner --
      debugShowCheckedModeBanner: false,

      // -- App title shown in the OS task switcher --
      title: 'University App',

      theme: appTheme,

      // -- Entry screen: Your existing Login page --
      // After login + MFA success, it navigates to MainNavigationScreen.
      home: LoginPage(),
    );
  }
}