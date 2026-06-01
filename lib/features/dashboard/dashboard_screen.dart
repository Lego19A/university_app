// ============================================================
// DASHBOARD SCREEN - Main landing page after Login + MFA.
// This is the home screen from the Figma design showing:
//   1. Orange header greeting the user ("Hi Anas!")
//   2. Status alert card (e.g., "Attendance below 80%")
//   3. 2x2 grid of Quick Action cards
//
// This screen is displayed inside MainNavigationScreen
// as the first tab (Home).
//
// To change the greeting name, update the _userName variable
// or fetch it from your Firebase user object.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/orange_header.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/status_alert_card.dart';
import '../announcements/screens/student_notifications_screen.dart';

class DashboardScreen extends ConsumerWidget {
  // -- onNavigate: Callback to navigate to feature screens --
  // This receives a route path string like '/timetable'
  final void Function(String route) onNavigate;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.when(
      data: (user) => user?.full_name.split(' ').first ?? 'Student',
      loading: () => 'Student',
      error: (_, __) => 'Student',
    );

    return Column(
      children: [
        // ---- SECTION 1: Orange Header with greeting ----
        // Displays "Hi Anas!" and a notification bell icon
        // Change the title to use the logged-in user's name
        OrangeHeader(
          title: 'Hi $userName!',
        ),

        // ---- SECTION 2: Scrollable body content ----
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ---- SECTION 2a: Status Alert Card ----
                // Prominent orange banner showing critical alerts
                // Remove or hide this widget if there are no alerts
                StatusAlertCard(
                  message: 'Your attendance is below 80%. Please take action.',
                  icon: Icons.warning_amber_rounded,
                  onTap: () => onNavigate('/attendance'),
                ),

                const SizedBox(height: AppConstants.spacingLG),

                // ---- SECTION 2b: "Quick Actions" section title ----
                Text(
                  'Quick Actions',
                  style: AppTypography.header2,
                ),


                // ---- SECTION 2c: 2x2 Grid of Action Cards ----
                // Each card navigates to a different feature screen
                // Modify the GridView to add/remove action cards
                GridView.count(
                  // -- crossAxisCount: 2 columns for the 2x2 grid --
                  crossAxisCount: 2,
                  // -- shrinkWrap: Prevents GridView from taking infinite height --
                  shrinkWrap: true,
                  // -- physics: Disables GridView's own scrolling (parent scrolls) --
                  physics: const NeverScrollableScrollPhysics(),
                  // -- Spacing between cards --
                  crossAxisSpacing: AppConstants.spacingMD,
                  mainAxisSpacing: AppConstants.spacingMD,
                  // -- childAspectRatio: Controls card height relative to width --
                  // Decrease this number to make cards taller
                  childAspectRatio: 1.1,
                  children: [
                    // Card 1: Subject Enrolment
                    ActionCard(
                      icon: Icons.book_outlined,
                      label: 'Subject\nEnrolment',
                      onTap: () => onNavigate('/enrolment'),
                    ),
                    // Card 2: Timetable
                    ActionCard(
                      icon: Icons.schedule_outlined,
                      label: 'Timetable',
                      onTap: () => onNavigate('/timetable'),
                    ),
                    // Card 3: View Attendance
                    ActionCard(
                      icon: Icons.fact_check_outlined,
                      label: 'View\nAttendance',
                      onTap: () => onNavigate('/attendance'),
                    ),
                    // Card 4: Resume Generation
                    ActionCard(
                      icon: Icons.description_outlined,
                      label: 'Resume\nGeneration',
                      onTap: () => onNavigate('/resume'),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingLG),

                // ---- SECTION 2d: Recent News preview (optional) ----
                // Quick link to the news section
                
                // -- News preview card --
                // This card shows a preview of the latest news item
                // Tapping it navigates to the full news screen
                GestureDetector(
                  onTap: () => onNavigate('/news'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.spacingMD),
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
                    child: Row(
                      children: [
                        // -- Placeholder for news image --
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.newspaper,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSM),
                        // -- News text content --
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Announcments',
                                style: AppTypography.header3,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to view latest announcements',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
