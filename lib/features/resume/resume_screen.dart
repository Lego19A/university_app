// ============================================================
// RESUME SCREEN - Resume preview with color customization
// and PDF download/share.
//
// This screen maintains the original Figma layout:
//   1. OrangeHeader at the top
//   2. Resume preview area (now a live PDF via PdfPreview)
//   3. Color theme picker (horizontal scroll)
//   4. Download Resume button
//
// The preview IS the actual PDF document, so what the user
// sees is exactly what they download. Color changes instantly
// regenerate the PDF via Riverpod state.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/orange_header.dart';
import '../../core/widgets/primary_button.dart';
import 'models/resume_data_model.dart';
import 'providers/resume_provider.dart';
import 'providers/resume_data_provider.dart';
import 'services/resume_pdf_generator.dart';

class ResumeScreen extends ConsumerWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = ref.watch(activeResumeThemeProvider);
    final resumeData = ref.watch(resumeDataProvider);

    if (resumeData == null) {
      return const Scaffold(
        body: Center(child: Text('No resume data provided')),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // ---- Orange header ----
          const OrangeHeader(title: 'Resume'),

          // ---- Body content ----
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                children: [
                  // ---- Resume preview card ----
                  // PdfPreview renders the actual PDF in real-time.
                  // The card styling matches the original placeholder.
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                        child: PdfPreview(
                          // -- Generate PDF with current theme color --
                          build: (format) => generateResumePdf(
                            resumeData,
                            activeTheme.pdfColor,
                          ),
                          // -- Disable default action buttons --
                          // We provide our own Download button below
                          canChangePageFormat: false,
                          canChangeOrientation: false,
                          canDebug: false,
                          allowSharing: false,
                          allowPrinting: false,
                          // -- PDF page display settings --
                          pdfPreviewPageDecoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingSM),

                  // ---- Color Theme Picker ----
                  // Horizontal scrollable row of color chips.
                  // Tapping a chip updates the Riverpod state,
                  // which triggers PdfPreview to rebuild instantly.
                  _buildColorPicker(ref),

                  const SizedBox(height: AppConstants.spacingSM),

                  // ---- Download button ----
                  PrimaryButton(
                    label: 'Download Resume',
                    onPressed: () => _downloadResume(context, activeTheme, resumeData),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _buildColorPicker - Row of selectable color theme chips.
  // Active chip shows a white checkmark and a border highlight.
  // ============================================================
  Widget _buildColorPicker(WidgetRef ref) {
    final activeIndex = ref.watch(resumeThemeIndexProvider);

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: predefinedThemes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final theme = predefinedThemes[index];
          final isActive = index == activeIndex;

          return GestureDetector(
            onTap: () {
              // -- Update the active theme via Riverpod --
              ref.read(resumeThemeIndexProvider.notifier).state = index;
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -- Color circle --
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.uiColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? AppColors.textPrimary : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: theme.uiColor.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isActive
                      ? const Icon(Icons.check, color: AppColors.white, size: 16)
                      : null,
                ),
                const SizedBox(height: 3),
                // -- Theme label --
                Text(
                  theme.name,
                  style: AppTypography.caption.copyWith(
                    fontSize: 9,
                    color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // _downloadResume - Triggers the native share/save sheet
  // with the exact same PDF that's displayed in the preview.
  // Uses Printing.sharePdf for cross-platform support.
  // ============================================================
  void _downloadResume(BuildContext context, ResumeTheme activeTheme, ResumeData resumeData) async {
    // -- Generate the exact same PDF as the preview --
    final pdfBytes = await generateResumePdf(
      resumeData,
      activeTheme.pdfColor,
    );

    // -- Trigger native share/save --
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'resume_${resumeData.name.replaceAll(' ', '_').toLowerCase()}.pdf',
    );
  }
}
