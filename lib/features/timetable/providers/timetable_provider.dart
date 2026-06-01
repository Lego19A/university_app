// ============================================================
// TIMETABLE NOTIFIER - Riverpod StateNotifier for timetable
// builder state management. Handles:
//   - Initializing subjects from enrolment data
//   - Session placement with clash validation
//   - Session removal (to undo a drop)
//   - Sequential subject flow (next/previous)
//   - Completing and persisting the final timetable
//
// All mutations go through this notifier, ensuring a single
// source of truth for the drag & drop builder UI.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timetable_models.dart';

// ============================================================
// TIMETABLE NOTIFIER - Core state management class.
// ============================================================
class TimetableNotifier extends StateNotifier<TimetableState> {
  TimetableNotifier() : super(const TimetableState(subjects: []));

  // ============================================================
  // initializeFromSubjects - Call this when user taps "Set Timetable".
  // Converts the selected subject data into the builder state.
  // Each subject generates a Lecture session; if requiresLab,
  // a Lab session is also generated.
  // ============================================================
  void initializeFromSubjects(List<Subject> subjects) {
    state = TimetableState(
      subjects: subjects,
      currentSubjectIndex: 0,
      placedSessions: [],
      isComplete: false,
    );
  }

  // ============================================================
  // placeSession - Attempts to place a session at a target slot.
  // Returns true if successful, false if clash detected.
  //
  // Validation:
  //   1. Target slot must not overlap with any already placed session.
  //   2. The session must not already be placed (duplicate prevention).
  // ============================================================
  bool placeSession(String sessionId, TimeSlot targetSlot) {
    // -- Find the session to place --
    Session? sessionToPlace;
    for (final subject in state.subjects) {
      for (final session in subject.sessions) {
        if (session.id == sessionId) {
          sessionToPlace = session;
          break;
        }
      }
      if (sessionToPlace != null) break;
    }

    if (sessionToPlace == null) return false;

    // -- Build the full TimeSlot for this session --
    final fullSlot = TimeSlot(
      dayOfWeek: targetSlot.dayOfWeek,
      startHour: targetSlot.startHour,
      durationHours: sessionToPlace.durationHours,
    );

    // -- Check for duplicate placement --
    if (state.placedSessions.any((s) => s.id == sessionId)) {
      return false;
    }

    // -- Check for time clashes --
    if (hasClash(fullSlot)) {
      return false;
    }

    // -- Check if session would extend beyond grid bounds (past 6 PM = hour 18) --
    if (fullSlot.startHour + fullSlot.durationHours > 18) {
      return false;
    }

    // -- Place the session --
    final placedSession = sessionToPlace.copyWithTimeSlot(fullSlot);
    state = state.copyWith(
      placedSessions: [...state.placedSessions, placedSession],
    );

    return true;
  }

  // ============================================================
  // removeSession - Removes a placed session (undo/replace).
  // ============================================================
  void removeSession(String sessionId) {
    state = state.copyWith(
      placedSessions: state.placedSessions
          .where((s) => s.id != sessionId)
          .toList(),
    );
  }

  // ============================================================
  // hasClash - Checks if a proposed TimeSlot overlaps with any
  // already placed session. Uses the TimeSlot.overlapsWith method.
  // ============================================================
  bool hasClash(TimeSlot proposedSlot) {
    for (final placed in state.placedSessions) {
      if (placed.timeSlot != null && placed.timeSlot!.overlapsWith(proposedSlot)) {
        return true;
      }
    }
    return false;
  }

  // ============================================================
  // nextSubject - Advances to the next subject in the guided flow.
  // Only works if the current subject is fully scheduled.
  // If all subjects are done, marks the timetable as complete.
  // ============================================================
  bool nextSubject() {
    if (!state.isCurrentSubjectComplete) return false;

    final nextIndex = state.currentSubjectIndex + 1;

    if (nextIndex >= state.subjects.length) {
      // All subjects scheduled — mark complete
      state = state.copyWith(isComplete: true);
      return true;
    }

    state = state.copyWith(currentSubjectIndex: nextIndex);
    return true;
  }

  // ============================================================
  // previousSubject - Goes back to the previous subject.
  // Removes all placed sessions for the current subject first.
  // ============================================================
  void previousSubject() {
    if (state.currentSubjectIndex <= 0) return;

    final prevIndex = state.currentSubjectIndex - 1;
    final currentSubjectId = state.currentSubject?.id;

    // Remove all placed sessions from the current subject
    final updatedPlaced = currentSubjectId != null
        ? state.placedSessions
            .where((s) => s.subjectId != currentSubjectId)
            .toList()
        : state.placedSessions;

    state = state.copyWith(
      currentSubjectIndex: prevIndex,
      placedSessions: updatedPlaced,
      isComplete: false,
    );
  }

  // ============================================================
  // reset - Clears the entire timetable state.
  // ============================================================
  void reset() {
    state = const TimetableState(subjects: []);
  }
}

// ============================================================
// PROVIDERS - Riverpod providers for the timetable feature.
// ============================================================

// -- Main notifier provider --
final timetableNotifierProvider =
    StateNotifierProvider<TimetableNotifier, TimetableState>((ref) {
  return TimetableNotifier();
});

// -- Convenience: current subject being scheduled --
final currentSubjectProvider = Provider<Subject?>((ref) {
  return ref.watch(timetableNotifierProvider).currentSubject;
});

// -- Convenience: unplaced sessions for UI pool --
final unplacedSessionsProvider = Provider<List<Session>>((ref) {
  return ref.watch(timetableNotifierProvider).currentUnplacedSessions;
});

// -- Convenience: all placed sessions for grid rendering --
final placedSessionsProvider = Provider<List<Session>>((ref) {
  return ref.watch(timetableNotifierProvider).placedSessions;
});

// -- Convenience: whether current subject is fully scheduled --
final isCurrentSubjectCompleteProvider = Provider<bool>((ref) {
  return ref.watch(timetableNotifierProvider).isCurrentSubjectComplete;
});

// -- All unplaced sessions across ALL subjects (free-form mode) --
final allUnplacedSessionsProvider = Provider<List<Session>>((ref) {
  return ref.watch(timetableNotifierProvider).allUnplacedSessions;
});

// -- Whether ALL sessions across ALL subjects are placed --
final isAllCompleteProvider = Provider<bool>((ref) {
  return ref.watch(timetableNotifierProvider).isAllComplete;
});

// ============================================================
// SAVED TIMETABLE PROVIDER - Stores the final persisted timetable.
// Once the user finishes the builder and taps "Save", the placed
// sessions are copied here. The TimetableScreen reads from this.
// ============================================================
final savedTimetableProvider = StateProvider<List<Session>>((ref) => []);

// ============================================================
// DRAGGED SESSION PROVIDER - Tracks which session is currently
// being dragged from the pool. The TimetableGridWidget watches
// this to dynamically render DragTarget overlays ONLY at the
// valid slots defined in the session's availableSlots list.
//
// null = no drag in progress
// Session = the session currently being dragged
// ============================================================
final draggedSessionProvider = StateProvider<Session?>((ref) => null);

// ============================================================
// MOCK SUBJECT DATA - Generates subjects with sessions for testing.
// Replace with real data from your backend/Firebase.
// Each subject gets a Lecture (1hr) and a Lab (2hr if required).
// ============================================================
List<Subject> generateMockSubjects() {
  const colors = [
    Color(0xFF3498DB), // Blue
    Color(0xFFE74C3C), // Red
    Color(0xFFF39C12), // Yellow
    Color(0xFF2ECC71), // Green
    Color(0xFF9B59B6), // Purple
    Color(0xFFE67E22), // Orange
  ];

  final subjectData = [
    {'id': 'se', 'name': 'Software Engineering', 'code': 'SE301', 'lab': true},
    {'id': 'db', 'name': 'Database Systems', 'code': 'DB201', 'lab': true},
    {'id': 'cn', 'name': 'Computer Networks', 'code': 'CN301', 'lab': false},
    {'id': 'wd', 'name': 'Web Development', 'code': 'WD201', 'lab': true},
    {'id': 'os', 'name': 'Operating Systems', 'code': 'OS301', 'lab': false},
  ];

  return subjectData.asMap().entries.map((entry) {
    final i = entry.key;
    final data = entry.value;
    final color = colors[i % colors.length];
    final subjectId = data['id'] as String;
    final name = data['name'] as String;
    final code = data['code'] as String;
    final requiresLab = data['lab'] as bool;

    final sessions = <Session>[
      Session(
        id: '${subjectId}_lec',
        subjectId: subjectId,
        subjectName: name,
        subjectCode: code,
        type: SessionType.lecture,
        durationHours: 1,
        color: color,
      ),
    ];

    if (requiresLab) {
      sessions.add(Session(
        id: '${subjectId}_lab',
        subjectId: subjectId,
        subjectName: name,
        subjectCode: code,
        type: SessionType.lab,
        durationHours: 2,
        color: color,
      ));
    }

    return Subject(
      id: subjectId,
      name: name,
      code: code,
      requiresLab: requiresLab,
      color: color,
      sessions: sessions,
    );
  }).toList();
}
