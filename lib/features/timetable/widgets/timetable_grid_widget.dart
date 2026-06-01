// ============================================================
// TIMETABLE GRID WIDGET - Guided drag-and-drop timetable grid.
//
// The grid renders a 5-day × 9-hour layout (Mon-Fri, 8 AM – 5 PM).
// The core mechanic is "Guided Drag-and-Drop":
//
//   1. When no drag is in progress, the grid shows a clean
//      base grid with any already-placed sessions overlaid.
//
//   2. When the user starts dragging a session from the pool,
//      the draggedSessionProvider fires. This widget watches
//      it and renders highlighted DragTarget overlays ONLY at
//      the valid slots defined in that session's availableSlots.
//
//   3. Each guided DragTarget uses onWillAcceptWithDetails to
//      run clash detection: same day AND time overlap formula.
//      Valid targets show a green dashed highlight.
//      Clashing targets show a red highlight.
//
//   4. On drop, the session is locked into the grid via the
//      TimetableNotifier and removed from the unplaced pool.
//
// Multi-hour sessions (e.g. 2hr labs) span multiple grid rows
// using a single Positioned DragTarget overlay.
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';

class TimetableGridWidget extends ConsumerWidget {
  const TimetableGridWidget({super.key});

  // -- Grid configuration --
  static const int startHour = 8;
  static const int endHour = 19; // 7 PM (exclusive: last slot is 6-7)
  static const int totalHours = endHour - startHour; // 11 slots
  static const double timeColumnWidth = 48;
  static const double cellWidth = 60;
  static const double cellHeight = 46;
  static const double headerHeight = 32;

  static const List<String> dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placedSessions = ref.watch(placedSessionsProvider);
    final draggedSession = ref.watch(draggedSessionProvider);

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: timeColumnWidth + (cellWidth * 5),
          child: Column(
            children: [
              // ---- Day Header Row ----
              _buildDayHeaders(),

              // ---- Grid Body with placed sessions + guided targets ----
              SizedBox(
                height: cellHeight * totalHours,
                child: Stack(
                  children: [
                    // -- Base grid: time labels + empty cells --
                    Column(
                      children: List.generate(totalHours, (hourIndex) {
                        final hour = startHour + hourIndex;
                        return _buildGridRow(hour);
                      }),
                    ),

                    // -- Overlaid placed sessions (handles multi-hour spans) --
                    ...placedSessions.map((session) {
                      if (session.timeSlot == null) {
                        return const SizedBox.shrink();
                      }
                      return _buildPlacedSessionOverlay(session, ref);
                    }),

                    // -- Guided DragTarget overlays (only visible during drag) --
                    if (draggedSession != null)
                      ..._buildGuidedTargets(draggedSession, ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // _buildDayHeaders - Row of day labels aligned with columns.
  // ============================================================
  Widget _buildDayHeaders() {
    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          // Time column header (empty)
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
          // Day labels
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

  // ============================================================
  // _buildGridRow - One row of the grid (time label + 5 cells).
  // These are purely visual — no DragTarget on individual cells.
  // DragTargets are rendered as overlays via _buildGuidedTargets.
  // ============================================================
  Widget _buildGridRow(int hour) {
    return SizedBox(
      height: cellHeight,
      child: Row(
        children: [
          // -- Time label --
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
          // -- 5 empty visual cells (Mon-Fri) --
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

  // ============================================================
  // _buildGuidedTargets - THE CORE MECHANIC.
  // Renders DragTarget overlays ONLY at the valid time slots
  // defined in the dragged session's availableSlots list.
  //
  // Each target is a Positioned widget placed precisely over
  // the corresponding grid cells, with:
  //   - A dashed-border visual guide (green if valid, red if clash)
  //   - A DragTarget<Session> that validates via onWillAccept
  //   - Multi-hour spans for lab sessions
  // ============================================================
  List<Widget> _buildGuidedTargets(Session draggedSession, WidgetRef ref) {
    final availableSlots = draggedSession.availableSlots;
    if (availableSlots.isEmpty) return [];

    return availableSlots.map((slot) {
      final dayIndex = slot.dayOfWeek - 1; // 0-indexed for positioning
      final hourOffset = slot.startHour - startHour;

      // Skip slots that are outside the visible grid
      if (hourOffset < 0 || hourOffset + slot.durationHours > totalHours) {
        return const SizedBox.shrink();
      }
      if (dayIndex < 0 || dayIndex > 4) {
        return const SizedBox.shrink();
      }

      final left = timeColumnWidth + (dayIndex * cellWidth) + 1;
      final top = (hourOffset * cellHeight) + 1.0;
      final height = (slot.durationHours * cellHeight) - 2.0;

      // Pre-check if this slot clashes with an existing placed session
      final proposedSlot = slot.toTimeSlot();
      final hasClash = ref.read(timetableNotifierProvider.notifier).hasClash(proposedSlot);

      return Positioned(
        left: left,
        top: top,
        width: cellWidth - 2,
        height: height,
        child: DragTarget<Session>(
          onWillAcceptWithDetails: (details) {
            final session = details.data;
            final targetSlot = TimeSlot(
              dayOfWeek: slot.dayOfWeek,
              startHour: slot.startHour,
              durationHours: session.durationHours,
            );

            // Reject if session already placed
            final placed = ref.read(placedSessionsProvider);
            if (placed.any((s) => s.id == session.id)) return false;

            // Reject if extends past grid boundary
            if (slot.startHour + session.durationHours > endHour) return false;

            // Reject if clash with an already placed session
            return !ref.read(timetableNotifierProvider.notifier).hasClash(targetSlot);
          },
          onAcceptWithDetails: (details) {
            final session = details.data;
            final targetSlot = TimeSlot(
              dayOfWeek: slot.dayOfWeek,
              startHour: slot.startHour,
              durationHours: session.durationHours,
            );
            ref
                .read(timetableNotifierProvider.notifier)
                .placeSession(session.id, targetSlot);
          },
          builder: (context, candidateData, rejectedData) {
            final isAccepting = candidateData.isNotEmpty;
            final isRejected = rejectedData.isNotEmpty;

            // Determine visual state
            Color bgColor;
            Color borderColor;
            if (isAccepting) {
              // Hovering and valid — green highlight
              bgColor = AppColors.success.withValues(alpha: 0.18);
              borderColor = AppColors.success;
            } else if (isRejected || hasClash) {
              // Hovering but clashing, or pre-detected clash — red
              bgColor = AppColors.error.withValues(alpha: 0.12);
              borderColor = AppColors.error.withValues(alpha: 0.6);
            } else {
              // Idle guide — subtle tint with dashed border
              bgColor = draggedSession.color.withValues(alpha: 0.08);
              borderColor = draggedSession.color.withValues(alpha: 0.5);
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: borderColor,
                  width: isAccepting ? 2.0 : 1.5,
                ),
              ),
              child: CustomPaint(
                painter: hasClash
                    ? null
                    : _DashedBorderPainter(
                        color: borderColor,
                        strokeWidth: 1.0,
                        dashWidth: 4,
                        dashSpace: 3,
                      ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasClash
                            ? Icons.block
                            : isAccepting
                                ? Icons.check_circle_outline
                                : Icons.add_circle_outline,
                        size: 16,
                        color: hasClash
                            ? AppColors.error.withValues(alpha: 0.7)
                            : isAccepting
                                ? AppColors.success
                                : borderColor,
                      ),
                      if (slot.durationHours > 1) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatSlotTime(slot.startHour, slot.durationHours),
                          style: AppTypography.caption.copyWith(
                            fontSize: 7,
                            color: borderColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  // ============================================================
  // _buildPlacedSessionOverlay - Positioned session block
  // rendered over the grid. Spans multiple rows for multi-hour sessions.
  // Tapping a placed session removes it (allows re-dragging).
  // ============================================================
  Widget _buildPlacedSessionOverlay(Session session, WidgetRef ref) {
    final slot = session.timeSlot!;
    final dayIndex = slot.dayOfWeek - 1; // 0-indexed
    final hourOffset = slot.startHour - startHour; // Rows from top

    final left = timeColumnWidth + (dayIndex * cellWidth) + 1;
    final top = (hourOffset * cellHeight) + 1.0;
    final height = (slot.durationHours * cellHeight) - 2.0;

    return Positioned(
      left: left,
      top: top,
      width: cellWidth - 2,
      height: height,
      child: GestureDetector(
        onTap: () {
          // -- Tap to remove (allows user to re-place the session) --
          ref.read(timetableNotifierProvider.notifier).removeSession(session.id);
        },
        child: Container(
          decoration: BoxDecoration(
            color: session.color.withValues(alpha: 0.2),
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
                  color: session.color.withValues(alpha: 0.8),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Helper: format hour integer to label --
  String _formatHour(int hour) {
    if (hour == 12) return '12 PM';
    if (hour > 12) return '${hour - 12} PM';
    return '$hour AM';
  }

  // -- Helper: format a slot time range --
  String _formatSlotTime(int startHour, int duration) {
    final endHour = startHour + duration;
    return '${_formatHour(startHour)} - ${_formatHour(endHour)}';
  }
}

// ============================================================
// _DashedBorderPainter - Draws a dashed rectangle border inside
// the widget to visually indicate a guided drop zone.
// Used when no drag hover is active to show "drop here" guides.
// ============================================================
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(6),
      ));

    // Draw dashed path
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = min(distance + dashWidth, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
