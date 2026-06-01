// ============================================================
// MENU SCREEN - "More" options grid.
// This is the screen shown when the "Menu" tab in the bottom
// navigation bar is tapped. It provides quick access to
// secondary features like News, Help, and Settings.
//
// To add more menu items, add another _MenuItem to the list below.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/orange_header.dart';
import '../../core/utils/auth_utils.dart';

class MenuScreen extends ConsumerWidget {
  // -- onNavigate: Callback to navigate to sub-screens --
  final void Function(String route) onNavigate;

  const MenuScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // ---- Orange header ----
        const OrangeHeader(title: 'More'),

        // ---- Menu items grid ----
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: GridView.count(
              crossAxisCount: 3, // 3 columns
              crossAxisSpacing: AppConstants.spacingMD,
              mainAxisSpacing: AppConstants.spacingMD,
              children: [
                // -- Menu item: News --
               
                // -- Menu item: Help & FAQ --
                _buildMenuItem(
                  icon: Icons.help_outline,
                  label: 'Help',
                  onTap: () => onNavigate('/help'),
                ),
                // -- Menu item: Settings --
                
                // -- Menu item: Logout --
                _buildMenuItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  iconColor: AppColors.error,
                  onTap: () {
                    _showLogoutDialog(context, ref);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // _buildMenuItem - Creates a single menu item tile.
  // Contains an icon in a circle and a label below it.
  // ============================================================
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // -- Circular icon container --
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
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
          // -- Label below the icon --
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  // ============================================================
  // _showLogoutDialog - Confirmation dialog before logout.
  // Prevents accidental logouts with a two-step confirmation.
  // Uses AuthUtils.performLogout for secure state wiping.
  // ============================================================
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Logout', style: AppTypography.header2),
          content: Text(
            'Are you sure you want to logout?',
            style: AppTypography.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(), // Cancel
              child: Text('Cancel', style: AppTypography.body),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                // -- Secure logout: wipe all state + sign out --
                await AuthUtils.performLogout(context, ref);
              },
              child: Text(
                'Logout',
                style: AppTypography.body.copyWith(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}
