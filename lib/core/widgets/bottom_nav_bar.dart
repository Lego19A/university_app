// ============================================================
// BOTTOM NAV BAR - Persistent bottom navigation bar.
// This is the navigation bar at the bottom of the app seen
// in the Figma design with tabs for Home, QR Scan, Profile,
// and Menu (More). It persists across all main screens.
//
// Usage: Used internally by MainNavigationScreen.
// You generally don't need to use this widget directly.
//
// To add/remove tabs, modify the _navItems list below.
// ============================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class AppBottomNavBar extends StatelessWidget {
  // -- currentIndex: Index of the currently selected tab (0-based) --
  final int currentIndex;

  // -- onTap: Callback when a tab is tapped, receives the tab index --
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // -- Decorative container for the nav bar --
      decoration: BoxDecoration(
        color: AppColors.surface,
        // -- Top border line separating nav bar from content --
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
        // -- Shadow above the nav bar for depth --
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2), // Shadow goes upward
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Only apply safe area at the bottom (for home indicator)
        child: BottomNavigationBar(
          // -- Currently active tab --
          currentIndex: currentIndex,
          onTap: onTap,

          // -- Visual configuration --
          type: BottomNavigationBarType.fixed,    // Show all labels always
          backgroundColor: AppColors.surface,      // White background
          selectedItemColor: AppColors.primary,    // Orange when selected
          unselectedItemColor: AppColors.textSecondary, // Grey when not selected
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0, // We handle elevation via the Container above

          // -- Tab items: Each represents a main section of the app --
          // Modify this list to add/remove navigation tabs
          items: const [
            // Tab 0: Home / Dashboard
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            // Tab 1: QR Scanner for attendance
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
            // Tab 2: Student profile
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            // Tab 3: More options / Menu
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              activeIcon: Icon(Icons.menu),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
