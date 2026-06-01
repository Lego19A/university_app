// ============================================================
// ORANGE HEADER - Reusable curved orange header widget.
// This is the distinctive orange header bar seen at the top
// of most screens in the Figma design. It displays a title
// and an optional trailing icon (e.g., notification bell).
//
// Usage:
//   OrangeHeader(title: 'Dashboard')
//   OrangeHeader(title: 'Hi Anas!', trailingIcon: Icons.notifications)
//
// To change the header shape, modify the CustomClipper below.
// To change the header color, update AppColors.primary.
// ============================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class OrangeHeader extends StatelessWidget {
  // -- title: The text displayed in the header --
  final String title;

  // -- trailingIcon: Optional icon button on the right (e.g., bell icon) --
  final IconData? trailingIcon;

  // -- onTrailingPressed: Callback when the trailing icon is tapped --
  final VoidCallback? onTrailingPressed;

  // -- height: Total height of the header widget --
  // Increase this if you need more space inside the header
  final double height;

  const OrangeHeader({
    super.key,
    required this.title,
    this.trailingIcon,
    this.onTrailingPressed,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // -- Full width of the screen --
      width: double.infinity,
      height: height,

      // -- Gradient background: gives the orange header a subtle depth --
      // Remove the gradient and use a flat color if you prefer
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,      // Top-left: base orange
            AppColors.primaryDark,  // Bottom-right: darker orange
          ],
        ),
        // -- Rounded bottom corners: creates the curved header shape --
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),

      // -- SafeArea: prevents content from going under the status bar --
      child: SafeArea(
        bottom: false, // Only apply safe area at the top
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // -- Center-aligned title text --
              // Using Stack ensures the title stays perfectly centered
              // regardless of whether leading/trailing icons exist.
              Center(
                child: Text(
                  title,
                  style: AppTypography.header1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),

              // -- Leading: Dynamic back button --
              // Only visible when there is a previous page in the
              // navigation stack (Navigator.canPop).
              // On root pages like Dashboard, canPop returns false
              // so this button is automatically hidden.
              Positioned(
                left: 0,
                child: Builder(
                  builder: (context) {
                    if (Navigator.of(context).canPop()) {
                      return IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.white,
                          size: 22,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      );
                    }
                    // -- Return empty box if no previous page --
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // -- Trailing: Optional icon button on the right side --
              // Only shows if trailingIcon is provided
              if (trailingIcon != null)
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: Icon(trailingIcon, color: AppColors.white, size: 28),
                    onPressed: onTrailingPressed,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
