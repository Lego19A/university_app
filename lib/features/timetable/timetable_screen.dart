// ============================================================
// TIMETABLE SCREEN - Weekly timetable grid view (READ-ONLY).
// This screen displays the saved timetable built by the user
// after completing the enrolment + timetable builder flow.
//
// If no timetable is saved yet, it shows an empty state
// directing the user to the Subject Enrolment screen.
//
// If a timetable is saved, it shows the weekly grid with
// colored subject blocks using an absolute Positioned Stack.
// This ensures that multi-hour blocks are rendered as a single
// connected block.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/orange_header.dart';
import 'models/timetable_models.dart';
import 'providers/timetable_provider.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSessions = ref.watch(savedTimetableProvider);

    return Scaffold(
      body: Column(
        children: [
          // ---- Orange header ----
          const OrangeHeader(title: 'Timetable'),

          // ---- Content: empty state or timetable grid ----
          Expanded(
            child: savedSessions.isEmpty
                ? _buildEmptyState(context)
                : _buildSavedTimetable(savedSessions),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _buildEmptyState - Shown when no timetable has been saved.
  // Directs the user to the Subject Enrolment screen to select
  // subjects and build their timetable.
  // ============================================================
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // -- Icon --
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              size: 56,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLG),

          // -- Title --
          Text(
            'No Timetable Yet',
            style: AppTypography.header2,
          ),
          const SizedBox(height: AppConstants.spacingSM),

          // -- Description --
          Text(
            'Enrol in your subjects first to build\nyour personalized weekly timetable.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingMD),

          // -- Hint --
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Go to Subject Enrolment to get started',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRID CONFIGURATION (Matches TimetableBuilder grid)
  // ============================================================
  static const int startHour = 8;
  static const int endHour = 19; // 7 PM
  static const int totalHours = endHour - startHour; // 11 slots
  static const double timeColumnWidth = 48;
  static const double cellWidth = 60;
  static const double cellHeight = 46;
  static const double headerHeight = 32;
  static const List<String> dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI'];

  // ============================================================
  // _buildSavedTimetable - Renders the saved timetable grid.
  // Uses absolute positioning to mimic the Builder layout perfectly
  // ensuring multi-hour blocks render as single contiguous rectangles.
  // ============================================================
  Widget _buildSavedTimetable(List<Session> sessions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: timeColumnWidth + (cellWidth * 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDayHeaders(),
              SizedBox(
                height: cellHeight * totalHours,
                child: Stack(
                  children: [
                    // Base grid
                    Column(
                      children: List.generate(totalHours, (hourIndex) {
                        final hour = startHour + hourIndex;
                        return _buildGridRow(hour);
                      }),
                    ),
                    // Placed sessions
                    ...sessions.map((session) {
                      if (session.timeSlot == null) return const SizedBox.shrink();
                      return _buildPlacedSessionOverlay(session);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayHeaders() {
    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          SizedBox(
            width: timeColumnWidth,
            child: Center(
              child: Text(
                'Time',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          ...dayLabels.map((day) {
            return SizedBox(
              width: cellWidth,
              child: Center(
                child: Text(
                  day,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGridRow(int hour) {
    return SizedBox(
      height: cellHeight,
      child: Row(
        children: [
          SizedBox(
            width: timeColumnWidth,
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionalTranslation(
                translation: const Offset(0, -0.5),
                child: Text(
                  _formatHour(hour),
                  style: AppTypography.caption.copyWith(fontSize: 9),
                ),
              ),
            ),
          ),
          ...List.generate(5, (dayIndex) {
            return Container(
              width: cellWidth,
              height: cellHeight,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(
                  color: AppColors.divider,
                  width: 0.5,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlacedSessionOverlay(Session session) {
    final slot = session.timeSlot!;
    final dayIndex = slot.dayOfWeek - 1;
    final hourOffset = slot.startHour - startHour;

    final left = timeColumnWidth + (dayIndex * cellWidth) + 1;
    final top = (hourOffset * cellHeight) + 1.0;
    final height = (slot.durationHours * cellHeight) - 2.0;

    return Positioned(
      left: left,
      top: top,
      width: cellWidth - 2,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: session.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: session.color, width: 1.2),
        ),
        padding: const EdgeInsets.all(3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              session.subjectCode,
              style: AppTypography.caption.copyWith(
                color: session.color,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              session.typeLabel,
              style: AppTypography.caption.copyWith(
                color: session.color.withOpacity(0.8),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 12) return '12 PM';
    if (hour > 12) return '${hour - 12} PM';
    return '$hour AM';
  }
}
