// ============================================================
// LECTURER NAVIGATION SCREEN - Root shell with responsive navigation.
//
// On NARROW screens (phones): Shows a bottom navigation bar.
// On WIDE screens (web/desktop): Shows a sidebar NavigationRail.
//
// On first load, fetches the lecturer's registered subject codes
// from the user profile and triggers attendance data loading.
//
// Tabs:
//   Tab 0: QR Code Generation  (LecturerQrScreen)
//   Tab 1: Attendance List     (LecturerAttendanceScreen)
//   Tab 2: Announcements       (LecturerAnnouncementScreen)
//   Tab 3: Profile             (LecturerProfileScreen)
//   Tab 4: Settings            (LecturerSettingsScreen)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';

// -- Lecturer-specific bottom navigation bar --
import '../lecturer/widgets/lecturer_bottom_nav_bar.dart';

// -- The five lecturer feature screens --
import '../lecturer/screens/lecturer_qr_screen.dart';
import '../lecturer/screens/lecturer_attendance_screen.dart';
import '../lecturer/screens/lecturer_announcement_screen.dart';
import '../lecturer/screens/lecturer_profile_screen.dart';
import '../lecturer/screens/lecturer_settings_screen.dart';

class LecturerNavigationScreen extends ConsumerStatefulWidget {
  const LecturerNavigationScreen({super.key});

  @override
  ConsumerState<LecturerNavigationScreen> createState() =>
      _LecturerNavigationScreenState();
}

class _LecturerNavigationScreenState
    extends ConsumerState<LecturerNavigationScreen> {
  // -- _currentIndex: Tracks which bottom tab is currently active --
  // 0 = QR Code, 1 = Attendance, 2 = Announce, 3 = Profile, 4 = Settings
  int _currentIndex = 0;

  // -- Whether the attendance data load has been triggered --
  bool _hasLoadedAttendance = false;

  @override
  void initState() {
    super.initState();
    // -- Load attendance data once the user profile is available --
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceData();
    });
  }

  // ============================================================
  // _loadAttendanceData - Reads subject codes from the user's
  // registered_subjects and passes them to the attendance provider.
  // ============================================================
  Future<void> _loadAttendanceData() async {
    if (_hasLoadedAttendance) return;
    // No longer needing to call loadLecturerSubjects here since subjects are 
    // streamed directly to the dropdown using lecturerSubjectsProvider
    _hasLoadedAttendance = true;
  }

  // -- Shared tab tap handler --
  void _handleTabTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    if (isWide) {
      return _buildWideLayout();
    }
    return _buildNarrowLayout();
  }

  // ============================================================
  // _buildNarrowLayout - Standard mobile layout with bottom nav.
  // ============================================================
  Widget _buildNarrowLayout() {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: LecturerBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleTabTap,
      ),
    );
  }

  // ============================================================
  // _buildWideLayout - Desktop/web layout with sidebar nav rail.
  // ============================================================
  Widget _buildWideLayout() {
    return Scaffold(
      body: Row(
        children: [
          // ---- Sidebar Navigation Rail ----
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _handleTabTap,
            labelType: NavigationRailLabelType.all,
            backgroundColor: AppColors.surface,
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedIconTheme:
                const IconThemeData(color: AppColors.textSecondary),
            unselectedLabelTextStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.qr_code_outlined),
                selectedIcon: Icon(Icons.qr_code),
                label: Text('QR Code'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check),
                label: Text('Attendance'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: Text('Announce'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),

          // ---- Vertical divider between sidebar and content ----
          const VerticalDivider(thickness: 1, width: 1),

          // ---- Main content area ----
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ============================================================
  // _buildBody - Returns the widget for the currently selected tab.
  // ============================================================
  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: const [
        LecturerQrScreen(),
        LecturerAttendanceScreen(),
        LecturerAnnouncementScreen(),
        LecturerProfileScreen(),
        LecturerSettingsScreen(),
      ],
    );
  }
}
