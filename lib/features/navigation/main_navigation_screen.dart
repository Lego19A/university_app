// ============================================================
// MAIN NAVIGATION SCREEN - Root shell with responsive navigation.
//
// On NARROW screens (phones): Shows a bottom navigation bar.
// On WIDE screens (web/desktop): Shows a sidebar NavigationRail.
//
// On first load, checks Firestore for saved timetable and
// enrollment data so the user's session is restored after logout.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/widgets/bottom_nav_bar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/repositories/firestore_repository.dart';
import '../dashboard/dashboard_screen.dart';
import '../attendance/qr_scan_screen.dart';
import '../attendance/attendance_screen.dart';
import '../attendance/providers/attendance_tracking_provider.dart';
import '../enrolment/subject_enrolment_screen.dart';
import '../enrolment/providers/enrolment_provider.dart';
import '../timetable/timetable_screen.dart';
import '../timetable/models/timetable_models.dart';
import '../timetable/providers/timetable_provider.dart';
import '../resume/resume_screen.dart';
import '../resume/resume_input_screen.dart';
import '../news/news_screen.dart';
import '../help/help_screen.dart';
import '../profile/profile_screen.dart';
import '../menu/menu_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  // -- _currentIndex: Tracks which tab is currently active --
  // 0 = Home, 1 = QR Scan (modal), 2 = Profile, 3 = Menu
  int _currentIndex = 0;

  // -- Whether the restore-from-Firestore check has already run --
  bool _hasRestoredState = false;

  @override
  void initState() {
    super.initState();
    // -- Restore saved timetable & enrollment from Firestore --
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreUserState();
    });
  }

  // ============================================================
  // _restoreUserState - Checks Firestore for a previously saved
  // timetable for the current user. If found, hydrates the local
  // providers so the app resumes exactly where the user left off.
  // ============================================================
  Future<void> _restoreUserState() async {
    if (_hasRestoredState) return;
    _hasRestoredState = true;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final repo = ref.read(firestoreRepositoryProvider);

    // -- 1. Restore Enrollment State --
    final enrolledCodes = await repo.getEnrolledSubjectCodes(uid);
    if (enrolledCodes.isNotEmpty) {
      final subjects = await repo.getSubjectsByCodes(enrolledCodes);
      final metaMap = <String, EnrolledSubjectMeta>{};
      for (final subject in subjects) {
        metaMap[subject.code] = EnrolledSubjectMeta(
          code: subject.code,
          name: subject.name,
          hasLab: subject.requiresLab,
        );
      }
      ref.read(enrolledSubjectCodesProvider.notifier).enrolSubjects(
        enrolledCodes,
        meta: metaMap,
      );
      // Lock the enrollment permanently since they have active enrollments
      ref.read(enrolledSubjectCodesProvider.notifier).finalizeEnrolment();
      
      // -- Restore Attendance --
      ref.read(attendanceTrackingProvider.notifier).loadAttendanceFromFirestore();
    }

    // -- 2. Restore Saved Timetable --
    final savedMaps = await repo.getTimetable(uid);
    if (savedMaps != null && savedMaps.isNotEmpty) {
      // Deserialize sessions from Firestore
      final sessions = savedMaps.map((m) => Session.fromMap(m)).toList();

      // Hydrate the saved timetable provider
      ref.read(savedTimetableProvider.notifier).state = sessions;
    }
  }

  // ============================================================
  // _handleTabTap - Handles bottom nav / rail tap events.
  // ============================================================
  void _handleTabTap(int index) {
    // -- Handle QR scan tab differently (opens as full screen) --
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QrScanScreen()),
      );
      return; // Don't change the selected tab
    }
    // -- Switch to the tapped tab --
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
      bottomNavigationBar: AppBottomNavBar(
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
            selectedIndex: _currentIndex > 1 ? _currentIndex - 1 : _currentIndex,
            onDestinationSelected: (index) {
              // Map rail index back to tab index (QR is modal, not in rail)
              // Rail: 0=Home, 1=Profile, 2=Menu → Tab: 0, 2, 3
              final tabIndex = index == 0 ? 0 : index + 1;
              _handleTabTap(tabIndex);
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: AppColors.surface,
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
            unselectedLabelTextStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: FloatingActionButton.small(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QrScanScreen()),
                  );
                },
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.qr_code_scanner, color: Colors.white),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.menu),
                selectedIcon: Icon(Icons.menu),
                label: Text('More'),
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
      index: _currentIndex > 1 ? _currentIndex - 1 : _currentIndex,
      children: [
        // Tab 0: Dashboard (Home)
        DashboardScreen(
          onNavigate: (route) => _navigateToFeature(route),
        ),
        // Tab 2: Profile (index shifted because QR is a modal)
        const ProfileScreen(),
        // Tab 3: More
        MenuScreen(
          onNavigate: (route) => _navigateToFeature(route),
        ),
      ],
    );
  }

  // ============================================================
  // _navigateToFeature - Navigates to a feature sub-screen.
  // ============================================================
  void _navigateToFeature(String route) {
    Widget screen;

    switch (route) {
      case '/attendance':
        screen = const Scaffold(body: AttendanceScreen());
        break;
      case '/enrolment':
        screen = const SubjectEnrolmentScreen();
        break;
      case '/timetable':
        screen = const TimetableScreen();
        break;
      case '/resume':
        screen = const ResumeInputScreen();
        break;
      case '/news':
        screen = const NewsScreen();
        break;
      case '/help':
        screen = const HelpScreen();
        break;
      default:
        screen = Scaffold(
          body: Center(child: Text('Screen not found: $route')),
        );
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
