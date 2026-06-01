// ============================================================
// APP THEME - The global ThemeData applied to MaterialApp.
// This ensures all native Flutter widgets (AppBar, Buttons,
// TextFields, etc.) automatically inherit the correct colors
// and styles without manual styling on each widget.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// -- appTheme: Pass this to MaterialApp's `theme:` parameter --
// All Material widgets will automatically pick up these styles
final ThemeData appTheme = ThemeData(
  // -- Sets the primary color swatch for the app --
  primaryColor: AppColors.primary,

  // -- Sets the default background color for all Scaffold widgets --
  scaffoldBackgroundColor: AppColors.background,

  // -- Sets the default font family for the entire app --
  fontFamily: GoogleFonts.averiaSerifLibre().fontFamily,

  // -- Color scheme: provides primary/secondary/error colors to widgets --
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.primary,
    surface: AppColors.surface,
    error: AppColors.error,
  ),

  // -- AppBar theme: Styles all AppBars globally --
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,  // Orange background
    foregroundColor: AppColors.white,    // White text/icons
    elevation: 0,                        // Flat, no shadow
    centerTitle: true,                   // Center-align the title
  ),

  // -- ElevatedButton theme: Styles all ElevatedButtons globally --
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,  // Orange background
      foregroundColor: AppColors.white,    // White text
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners matching Figma
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      elevation: 0, // Flat button, no shadow
    ),
  ),

  // -- OutlinedButton theme: Styles all OutlinedButtons globally --
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),

  // -- Card theme: Styles all Card widgets globally --
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16), // Rounded cards matching Figma
    ),
  ),

  // -- Input decoration theme: Styles all TextField/TextFormField globally --
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    hintStyle: TextStyle(color: AppColors.textSecondary),
  ),

  // -- Divider theme: Styles all Divider widgets globally --
  dividerTheme: const DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
  ),
);
