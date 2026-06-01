// ============================================================
// ATTENDANCE SCREEN - Displays attendance percentage per subject.
// This screen shows a vertical list of subjects, each with:
//   - Subject name
//   - Type label (LEC / LAB)
//   - Horizontal progress bar showing attendance percentage
//
// The progress bar turns red when attendance drops below 80%.
//
// DATA SOURCE:
//   Reads from attendanceSummaryListProvider (Riverpod), which
//   is driven by the attendanceTrackingProvider. Records are
//   initialized at 50% when the user finalizes enrollment and
//   increment by 10% per successful QR scan confirmation.
//
// FILTERING:
//   The attendanceTrackingProvider only contains records for
//   enrolled subjects, so no extra filtering is needed here.
//   If no subjects are enrolled yet, an empty state is shown.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/orange_header.dart';
import 'providers/attendance_tracking_provider.dart';
import 'screens/subject_attendance_details_screen.dart';

// -- ConsumerWidget: Reactively rebuilds when attendance data changes --
// Attendance updates immediately after a successful QR scan confirmation.
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // -- Watch the sorted, aggregated attendance list --
    // This list is empty until the user finalizes enrollment.
    // Each item has: code, name, type ("LEC"/"LAB"), percentage.
    final summaries = ref.watch(attendanceSummaryListProvider);

    return Column(
      children: [
        // ---- Orange header with screen title ----
        const OrangeHeader(title: 'View Attendance'),

        // ---- Content: Either the subject list or an empty state ----
        Expanded(
          child: summaries.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  itemCount: summaries.length,
                  itemBuilder: (context, index) {
                    final summary = summaries[index];
                    return _SubjectAttendanceCard(summary: summary);
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================
  // _buildEmptyState - Shown when no attendance records exist yet.
  // This means the user has not completed enrollment + timetable.
  // ============================================================
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // -- Empty state icon --
            Icon(
              Icons.school_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.spacingMD),

            // -- Empty state message --
            Text(
              'No Enrolled Subjects',
              style: AppTypography.header2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingSM),
            Text(
              'You are not enrolled in any subjects yet.\nEnrol in subjects to view your attendance.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// _SubjectAttendanceCard - Individual subject attendance row.
// Identical visual layout to the original screen.
// Now driven by SubjectAttendanceSummary from Riverpod state.
// ============================================================
class _SubjectAttendanceCard extends StatelessWidget {
  final SubjectAttendanceSummary summary;

  const _SubjectAttendanceCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    // -- Determine progress bar color based on attendance threshold --
    // Green if >= 80%, Red if below 80%
    final bool isLow = summary.percentage < 80;
    final Color barColor = isLow ? AppColors.error : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingMD),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        elevation: 6,
        shadowColor: AppColors.shadow.withOpacity(0.5),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubjectAttendanceDetailsScreen(summary: summary),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -- Row 1: Subject name and type badge --
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // -- Subject name --
                    Expanded(
                      child: Text(
                        summary.name,
                        style: AppTypography.header3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // -- Type badge (LEC / LAB) --
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        summary.type,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingSM),

                // -- Row 2: Progress bar showing attendance percentage --
                Row(
                  children: [
                    // -- The progress bar itself --
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8), // Rounded bar ends
                        child: LinearProgressIndicator(
                          value: summary.percentage / 100, // 0.0 to 1.0
                          minHeight: 10,                   // Bar thickness
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSM),
                    // -- Percentage text label --
                    Text(
                      '${summary.percentage}%',
                      style: AppTypography.body.copyWith(
                        color: barColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingSM),

                // -- "View Details" hint --
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'View Details',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
