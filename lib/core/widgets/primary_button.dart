// ============================================================
// PRIMARY BUTTON - Reusable full-width action button.
// This is the standard orange button seen throughout the
// Figma design for primary actions like "Login", "Save",
// "Download", "Update Attendance", etc.
//
// Usage:
//   PrimaryButton(label: 'Save', onPressed: () { ... })
//   PrimaryButton(label: 'Loading...', onPressed: null, isLoading: true)
//
// To change button styling, update AppTheme's elevatedButtonTheme.
// ============================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PrimaryButton extends StatelessWidget {
  // -- label: The text displayed on the button --
  final String label;

  // -- onPressed: Callback when button is tapped. Set to null to disable --
  final VoidCallback? onPressed;

  // -- isLoading: Shows a spinner instead of the label when true --
  final bool isLoading;

  // -- isOutlined: If true, renders as an outlined button instead of filled --
  final bool isOutlined;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    // -- Show outlined variant if isOutlined is true --
    if (isOutlined) {
      return SizedBox(
        width: double.infinity, // Full width button
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(isPrimary: false),
        ),
      );
    }

    // -- Default: filled/elevated button --
    return SizedBox(
      width: double.infinity, // Full width button
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed, // Disable when loading
        child: _buildChild(isPrimary: true),
      ),
    );
  }

  // -- Builds either a spinner or the text label --
  Widget _buildChild({required bool isPrimary}) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isPrimary ? AppColors.white : AppColors.primary,
          ),
        ),
      );
    }
    return Text(
      label,
      style: AppTypography.button.copyWith(
        color: isPrimary ? AppColors.white : AppColors.primary,
      ),
    );
  }
}
