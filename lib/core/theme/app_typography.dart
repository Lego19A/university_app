// ============================================================
// APP TYPOGRAPHY - Central text styles for the entire app.
// All text styles used across the app are defined here.
// Uses Google Fonts so no manual font file installation needed.
// Change fontFamily / fontSize / fontWeight to match Figma.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // -- HEADER 1: Largest heading, used for screen titles in orange headers --
  // Example: "Hi Anas!", "Timetable", "Attendance"
  static TextStyle header1 = GoogleFonts.oswald(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.white, // White text on orange header background
  );

  // -- HEADER 2: Secondary headings inside page body --
  // Example: Section titles like "Quick Actions", "Subjects"
  static TextStyle header2 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // -- HEADER 3: Smaller headings for cards and list items --
  // Example: Subject names in attendance list, card titles
  static TextStyle header3 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // -- BODY: Standard body text --
  // Example: Descriptions, paragraphs, general content
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  // -- BODY SMALL: Smaller body text for metadata and timestamps --
  // Example: "Last updated 2 hours ago", "LEC / TUT"
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // -- BUTTON: Text style for buttons --
  // Example: "Login", "Save", "Download"
  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  // -- CAPTION: Very small text for labels and badges --
  // Example: Navigation bar labels, form field hints
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}
