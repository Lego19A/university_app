// ============================================================
// ACTION CARD - Reusable card widget for the Dashboard grid.
// This is the card component used in the 2x2 grid on the
// Dashboard screen. Each card has an icon, a label, and
// navigates to a feature screen when tapped.
//
// Usage:
//   ActionCard(
//     icon: Icons.schedule,
//     label: 'Timetable',
//     onTap: () => context.go('/timetable'),
//   )
//
// To change card appearance, modify the Container decoration below.
// ============================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_constants.dart';

class ActionCard extends StatelessWidget {
  // -- icon: The icon displayed at the top of the card --
  final IconData icon;

  // -- label: The text displayed below the icon --
  final String label;

  // -- onTap: Callback when the card is pressed --
  final VoidCallback onTap;

  // -- iconColor: Override the default icon color --
  // Defaults to the primary orange color
  final Color? iconColor;

  const ActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // -- Card container with shadow and rounded corners --
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,            // White card background
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          // -- Box shadow: gives the card a subtle floating effect --
          // Remove this if you want flat cards
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2), // Shadow falls downward
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // -- Icon: Large icon representing the feature --
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // -- Light orange circle behind the icon --
                // This gives the icon a soft highlighted background
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppConstants.iconSizeLG,
                color: iconColor ?? AppColors.primary,
              ),
            ),

            const SizedBox(height: AppConstants.spacingSM),

            // -- Label: Feature name below the icon --
            Text(
              label,
              style: AppTypography.header3,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
