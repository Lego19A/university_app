// ============================================================
// APP COLORS - Central color palette for the entire app.
// All colors used across the app are defined here.
// To change a color, update the hex value here and it
// will automatically propagate everywhere.
// Replace hex values with your exact Figma color tokens.
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  // -- PRIMARY: Main brand color used for headers, buttons, and accents --
  // Change this to match your Figma primary color
  static const Color primary = Color(0xFF1B262C);

  // -- PRIMARY DARK: Darker shade of primary for status bar / pressed states --
  static const Color primaryDark = Color(0xFF0F4C75);

  // -- BACKGROUND: Main scaffold/page background color --
  // This warm off-white gives the app an academic feel
  static const Color background = Color(0xFFEEEEEE);

  // -- SURFACE: Card and container backgrounds --
  static const Color surface = Colors.white;

  // -- TEXT PRIMARY: Main body text and headings --
  static const Color textPrimary = Color(0xFF28396C);

  // -- TEXT SECONDARY: Subtitles, hints, and less prominent text --
  static const Color textSecondary = Color(0xFF7F8C8D);

  // -- WHITE: Used for text on colored backgrounds --
  static const Color white = Colors.white;

  // -- ERROR: Validation errors and destructive actions --
  static const Color error = Color(0xFFE74C3C);

  // -- SUCCESS: Positive feedback and confirmations --
  static const Color success = Color(0xFF27AE60);

  // -- TIMETABLE ACCENT COLORS: Used for subject blocks in timetable grid --
  // Each subject gets a unique color for visual distinction
  static const Color timetableBlue = Color(0xFF3498DB);
  static const Color timetableRed = Color(0xFFE74C3C);
  static const Color timetableYellow = Color(0xFFF39C12);
  static const Color timetableGreen = Color(0xFF2ECC71);
  static const Color timetablePurple = Color(0xFF9B59B6);

  // -- DIVIDER: Subtle line separators between list items --
  static const Color divider = Color(0xFFECECEC);

  // -- SHADOW: Drop shadow color for elevated cards --
  static const Color shadow = Color(0x1A000000);
}
