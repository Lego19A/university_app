// ============================================================
// LECTURER BOTTOM NAV BAR - Dedicated bottom navigation bar
// for the Lecturer Interface.
//
// This is a direct mirror of the student's AppBottomNavBar in
// core/widgets/bottom_nav_bar.dart. The ONLY differences are:
//   1. Tab icons and labels are lecturer-specific
//   2. Five tabs: QR Generate, Attendance, Announce, Profile, Settings
//
// ALL visual properties are identical:
//   - Same Container decoration (shadow, border, background)
//   - Same BottomNavigationBar config (colors, sizes, type)
//   - Same SafeArea handling
//
// This is kept as a separate widget (not a shared parameterized
// widget) to maintain the strict role-based isolation specified
// in the architecture: student and lecturer UI trees have zero
// shared navigation components.
// ============================================================

import 'package:flutter/material.dart'; // Flutter UI framework
import '../../../core/theme/app_colors.dart'; // Centralized color tokens

class LecturerBottomNavBar extends StatelessWidget {
  // -- currentIndex: Index of the currently selected tab (0-based) --
  // 0 = QR Generate, 1 = Attendance, 2 = Profile, 3 = Settings
  final int currentIndex;

  // -- onTap: Callback fired when any tab is tapped, receives tab index --
  final ValueChanged<int> onTap;

  const LecturerBottomNavBar({
    super.key,
    required this.currentIndex, // Required: which tab is active
    required this.onTap, // Required: tap handler
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // -- Decorative container wrapping the BottomNavigationBar --
      // This matches the exact same Container used in AppBottomNavBar.
      decoration: BoxDecoration(
        color: AppColors.surface, // White background
        // -- Top border: 1px divider line separating nav from content --
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
        // -- Upward shadow for visual depth (nav bar floats above content) --
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow, // 10% black shadow
            blurRadius: 8, // Soft blur radius
            offset: const Offset(0, -2), // Shadow goes upward
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Only apply safe area at the bottom (for home indicator)
        child: BottomNavigationBar(
          // -- Currently selected tab index --
          currentIndex: currentIndex,
          // -- Tab tap callback --
          onTap: onTap,

          // ---- Visual configuration ----
          // All values below are IDENTICAL to AppBottomNavBar
          type: BottomNavigationBarType.fixed, // Show all labels always
          backgroundColor: AppColors.surface, // White background
          selectedItemColor: AppColors.primary, // Brand color when selected
          unselectedItemColor: AppColors.textSecondary, // Grey when unselected
          selectedFontSize: 12, // Font size for selected label
          unselectedFontSize: 12, // Font size for unselected label
          elevation: 0, // We handle elevation via the Container above

          // ---- Tab items: Lecturer-specific navigation tabs ----
          items: const [
            // Tab 0: QR Code Generation (Home equivalent for lecturer)
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_outlined), // Outlined when inactive
              activeIcon: Icon(Icons.qr_code), // Filled when active
              label: 'QR Code', // Tab label
            ),
            // Tab 1: Attendance List (view student attendance records)
            BottomNavigationBarItem(
              icon: Icon(Icons.fact_check_outlined), // Outlined when inactive
              activeIcon: Icon(Icons.fact_check), // Filled when active
              label: 'Attendance', // Tab label
            ),
            // Tab 2: Announcements (send messages to students)
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined), // Outlined when inactive
              activeIcon: Icon(Icons.campaign), // Filled when active
              label: 'Announce', // Tab label
            ),
            // Tab 3: Lecturer Profile
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), // Outlined when inactive
              activeIcon: Icon(Icons.person), // Filled when active
              label: 'Profile', // Tab label
            ),
            // Tab 4: Settings (replaces the student "Menu" tab)
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), // Outlined when inactive
              activeIcon: Icon(Icons.settings), // Filled when active
              label: 'Settings', // Tab label
            ),
          ],
        ),
      ),
    );
  }
}
