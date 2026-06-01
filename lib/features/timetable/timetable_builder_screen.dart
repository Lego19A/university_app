// ============================================================
// TIMETABLE BUILDER SCREEN - Free-form drag & drop timetable.
// This screen brings together:
//   1. OrangeHeader (consistent with app design)
//   2. Progress indicator (X of Y sessions placed)
//   3. Draggable session pool (ALL unplaced blocks from ALL subjects)
//   4. Droppable timetable grid
//   5. Save footer (enabled when all sessions are placed)
//
// All subjects are shown simultaneously so the user can drag
// sessions in any order they prefer. Blocks are color-coded by
// subject for easy identification.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/orange_header.dart';
import '../../core/repositories/firestore_repository.dart';
import 'models/timetable_models.dart';
import 'providers/timetable_provider.dart';
import 'widgets/draggable_session_widget.dart';
import 'widgets/timetable_grid_widget.dart';
import '../enrolment/providers/enrolment_provider.dart';
import '../attendance/providers/attendance_tracking_provider.dart';

class TimetableBuilderScreen extends ConsumerStatefulWidget {
  // -- subjects: The subjects selected by the user on the Enrolment screen --
  final List<Subject> subjects;

  const TimetableBuilderScreen({super.key, required this.subjects});

  @override
  ConsumerState<TimetableBuilderScreen> createState() =>
      _TimetableBuilderScreenState();
}

class _TimetableBuilderScreenState
    extends ConsumerState<TimetableBuilderScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    // -- Initialize the timetable state with subjects from Enrolment --
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(timetableNotifierProvider.notifier);
      notifier.initializeFromSubjects(widget.subjects);
    });
  }

  @override
  Widget build(BuildContext context) {
    final timetableState = ref.watch(timetableNotifierProvider);
    final allUnplaced = ref.watch(allUnplacedSessionsProvider);
    final isAllComplete = ref.watch(isAllCompleteProvider);

    // -- If no subjects loaded yet, show loading --
    if (timetableState.subjects.isEmpty) {
      return Scaffold(
        body: Column(
          children: [
            const OrangeHeader(title: 'Set Timetable'),
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // ---- SECTION 1: Orange header ----
          const OrangeHeader(title: 'Set Timetable'),

          // ---- SECTION 2: Progress Bar ----
          _buildProgressSection(timetableState),

          // ---- SECTION 3: Draggable Pool (ALL subjects) ----
          _buildDraggablePool(allUnplaced, isAllComplete, _scrollController),

          // ---- SECTION 4: Timetable Grid ----
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: TimetableGridWidget(),
            ),
          ),

          // ---- SECTION 5: Save Footer ----
          _buildSaveFooter(timetableState, isAllComplete),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION 2: Progress indicator showing overall session count.
  // Displays "3 of 8 Sessions Placed" with a linear progress bar.
  // ============================================================
  Widget _buildProgressSection(TimetableState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.pagePadding,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Session count label --
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.placedSessionCount} of ${state.totalSessionCount} Sessions Placed',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (state.isAllComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'All Done ✓',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // -- Progress bar --
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                state.isAllComplete ? AppColors.success : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION 3: Draggable pool showing ALL unplaced sessions
  // from every subject. Color-coded by subject.
  // ============================================================
  Widget _buildDraggablePool(
      List<Session> allUnplaced, bool isAllComplete, ScrollController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.pagePadding,
        vertical: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Section label --
          Row(
            children: [
              Icon(
                isAllComplete
                    ? Icons.check_circle
                    : Icons.drag_indicator,
                size: 18,
                color: isAllComplete ? AppColors.success : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                isAllComplete
                    ? 'All sessions placed!'
                    : 'Drag sessions to the grid below',
                style: AppTypography.bodySmall.copyWith(
                  color: isAllComplete ? AppColors.success : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // -- Draggable session blocks from ALL subjects --
          if (allUnplaced.isNotEmpty)
            Scrollbar(
              controller: controller,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: controller,
                scrollDirection: Axis.horizontal, reverse: true,
                // -- INCREASED BOTTOM PADDING to push scrollbar further down --
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  children: allUnplaced.map((session) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: DraggableSessionWidget(session: session),
                    );
                  }).toList(),
                ),
              ),
            ),
          if (isAllComplete && allUnplaced.isEmpty)
            Text(
              'Tap a placed session on the grid to remove it.',
              style: AppTypography.caption.copyWith(fontSize: 10),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION 5: Save footer. Single "Save Timetable" button that
  // is disabled until all sessions are placed.
  // ============================================================
  Widget _buildSaveFooter(TimetableState state, bool isAllComplete) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.pagePadding,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isAllComplete ? () => _saveTimetable() : null,
            icon: const Icon(Icons.save_alt, size: 18),
            label: Text(
              isAllComplete
                  ? 'Save Timetable'
                  : '${state.totalSessionCount - state.placedSessionCount} sessions remaining',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.divider,
              disabledForegroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // _saveTimetable - Persists placed sessions to both local state
  // AND Firestore, then navigates back.
  // ============================================================
  void _saveTimetable() {
    final placedSessions = ref.read(placedSessionsProvider);

    // -- Persist to the saved timetable provider (local state) --
    ref.read(savedTimetableProvider.notifier).state =
        List.from(placedSessions);

    // -- Permanently lock the enrolment --
    ref.read(enrolledSubjectCodesProvider.notifier).finalizeEnrolment();

    // -- Initialize attendance records at 50% for every enrolled subject --
    ref.read(attendanceTrackingProvider.notifier).loadAttendanceFromFirestore();

    // -- Persist timetable layout to Firestore --
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final sessionMaps = placedSessions.map((s) => s.toMap()).toList();
      ref.read(firestoreRepositoryProvider).saveTimetable(uid, sessionMaps);
    }

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Timetable saved! (${placedSessions.length} sessions scheduled)',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // Navigate back (the TimetableScreen will now show the saved data)
    Navigator.of(context).pop();
  }
}
