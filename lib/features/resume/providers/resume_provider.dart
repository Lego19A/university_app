// ============================================================
// RESUME PROVIDER - Riverpod state management for the resume
// color theme selection.
//
// Manages:
//   - The currently active primary color for the resume
//   - A list of predefined color themes for the picker
//
// The PdfColor type from the pdf package is used directly so
// we can pass it straight into the PDF generator without
// conversion.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';

// ============================================================
// RESUME THEME - Pairs a Flutter Color (for the UI chip) with
// a PdfColor (for the PDF generator).
// ============================================================
class ResumeTheme {
  final String name;
  final Color uiColor;       // For the color chip on screen
  final PdfColor pdfColor;   // For the PDF document renderer

  const ResumeTheme({
    required this.name,
    required this.uiColor,
    required this.pdfColor,
  });
}

// ============================================================
// PREDEFINED THEMES - Available color options for the user.
// ============================================================
final List<ResumeTheme> predefinedThemes = [
  ResumeTheme(
    name: 'Navy',
    uiColor: const Color(0xFF0F2854),
    pdfColor: const PdfColor.fromInt(0xFF0F2854),
  ),
  ResumeTheme(
    name: 'Teal',
    uiColor: const Color(0xFF008080),
    pdfColor: const PdfColor.fromInt(0xFF008080),
  ),
  ResumeTheme(
    name: 'Crimson',
    uiColor: const Color(0xFFC0392B),
    pdfColor: const PdfColor.fromInt(0xFFC0392B),
  ),
  ResumeTheme(
    name: 'Forest',
    uiColor: const Color(0xFF27AE60),
    pdfColor: const PdfColor.fromInt(0xFF27AE60),
  ),
  ResumeTheme(
    name: 'Purple',
    uiColor: const Color(0xFF8E44AD),
    pdfColor: const PdfColor.fromInt(0xFF8E44AD),
  ),
  ResumeTheme(
    name: 'Charcoal',
    uiColor: const Color(0xFF2C3E50),
    pdfColor: const PdfColor.fromInt(0xFF2C3E50),
  ),
];

// ============================================================
// PROVIDERS
// ============================================================

// -- Currently selected theme index --
final resumeThemeIndexProvider = StateProvider<int>((ref) => 0);

// -- Derived: the active ResumeTheme --
final activeResumeThemeProvider = Provider<ResumeTheme>((ref) {
  final index = ref.watch(resumeThemeIndexProvider);
  return predefinedThemes[index];
});
