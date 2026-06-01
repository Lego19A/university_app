// ============================================================
// STATUS ALERT CARD - Prominent alert banner on the Dashboard.
// This is the large orange/colored card at the top of the
// Dashboard that displays critical information to the student
// (e.g., "Attendance below 80%").
//
// Usage:
//   StatusAlertCard(
//     message: 'Your attendance is below 80%',
//     icon: Icons.warning_amber_rounded,
//   )
//
// To hide this card, wrap it in a Visibility widget or
// conditionally render it based on your state.
// ============================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_constants.dart';

class StatusAlertCard extends StatelessWidget {
  // -- message: The alert text to display --
  final String message;

  // -- icon: Icon displayed to the left of the message --
  final IconData icon;

  // -- backgroundColor: Override the default alert color --
  // Defaults to primary orange to match Figma
  final Color? backgroundColor;

  // -- onTap: Optional callback when the alert is tapped --
  final VoidCallback? onTap;

  const StatusAlertCard({
    super.key,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.spacingMD),
        decoration: BoxDecoration(
          // -- Background: solid orange by default --
          color: backgroundColor ?? AppColors.primary,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          // -- Subtle shadow for depth --
          boxShadow: [
            BoxShadow(
              color: (backgroundColor ?? AppColors.primary).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // -- Alert icon on the left --
            Icon(
              icon,
              color: AppColors.white,
              size: 32,
            ),
            const SizedBox(width: AppConstants.spacingSM),

            // -- Alert message text --
            Expanded(
              child: Text(
                message,
                style: AppTypography.body.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // -- Chevron arrow indicating tappable --
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.white,
              ),
          ],
        ),
      ),
    );
  }
}
