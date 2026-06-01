// ============================================================
// ENROLMENT PROVIDER - Global state for enrolled subjects.
// This Riverpod provider holds the list of subject codes that
// the user has enrolled in (e.g., ['CS101', 'SE301']).
//
// It is the SINGLE SOURCE OF TRUTH linking:
//   Subject Enrollment page → View Attendance page → Timetable page.
//
// Rules enforced here:
//   - Minimum 3 subjects required before enrolment.
//   - Maximum 6 subjects allowed.
//   - Once finalized (isFinalized = true), the state is locked
//     and no further changes are permitted.
//
// Usage:
//   // Read enrolled codes:
//   final codes = ref.watch(enrolledSubjectCodesProvider);
//
//   // Check finalization:
//   final state = ref.watch(enrolledSubjectCodesProvider.notifier);
//
//   // Enrol subjects (only valid before finalization):
//   ref.read(enrolledSubjectCodesProvider.notifier).enrolSubjects(['CS101'], metadata);
//
//   // Finalize enrolment (called after timetable is saved):
//   ref.read(enrolledSubjectCodesProvider.notifier).finalizeEnrolment();
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================
// EnrolledSubjectMeta - Lightweight metadata about each enrolled
// subject that other modules (attendance) need for initialization.
// Stored here so attendance doesn't need to import enrolment
// screen internals.
// ============================================================
class EnrolledSubjectMeta {
  final String code;
  final String name;
  final bool hasLab;

  const EnrolledSubjectMeta({
    required this.code,
    required this.name,
    required this.hasLab,
  });
}

// -- Constraint constants --
// You can modify these values to change selection limits.
const int kMinSubjects = 3;
const int kMaxSubjects = 6;

// ============================================================
// EnrolmentState - Holds the full enrolment state.
// Separate from just the list so we can add isFinalized cleanly.
// ============================================================
class EnrolmentState {
  // -- The list of enrolled subject codes (e.g., 'SE301', 'CS101') --
  final List<String> subjectCodes;

  // -- Subject metadata keyed by code: name and hasLab --
  // Populated at enrollment time; consumed by the attendance system
  // to initialize per-subject attendance records at 50%.
  final Map<String, EnrolledSubjectMeta> subjectMeta;

  // -- isFinalized: true after "Save Timetable" is tapped --
  // Once true, the enrolment screen shows a locked "Completed" state
  // and all mutation methods become no-ops.
  final bool isFinalized;

  const EnrolmentState({
    this.subjectCodes = const [],
    this.subjectMeta = const {},
    this.isFinalized = false,
  });

  // -- Helper: creates a modified copy of this state --
  EnrolmentState copyWith({
    List<String>? subjectCodes,
    Map<String, EnrolledSubjectMeta>? subjectMeta,
    bool? isFinalized,
  }) {
    return EnrolmentState(
      subjectCodes: subjectCodes ?? this.subjectCodes,
      subjectMeta: subjectMeta ?? this.subjectMeta,
      isFinalized: isFinalized ?? this.isFinalized,
    );
  }

  // -- Convenience: whether the current count satisfies constraints --
  bool get meetsMinimum => subjectCodes.length >= kMinSubjects;
  bool get meetsMaximum => subjectCodes.length <= kMaxSubjects;
  bool get isValidCount => meetsMinimum && meetsMaximum;
}

// -- Provider: Exposes EnrolledSubjectsNotifier globally --
// Any widget that watches this will rebuild when enrolment changes.
final enrolledSubjectCodesProvider =
    NotifierProvider<EnrolledSubjectsNotifier, EnrolmentState>(
  EnrolledSubjectsNotifier.new,
);

// -- Legacy convenience provider: returns ONLY the subject codes list --
// Kept for backwards compatibility with AttendanceScreen which reads
// a flat List<String> to filter subjects.
final enrolledCodesListProvider = Provider<List<String>>((ref) {
  return ref.watch(enrolledSubjectCodesProvider).subjectCodes;
});

// -- Convenience: returns whether enrolment is finalized --
final isEnrolmentFinalizedProvider = Provider<bool>((ref) {
  return ref.watch(enrolledSubjectCodesProvider).isFinalized;
});

// ============================================================
// EnrolledSubjectsNotifier - Manages the EnrolmentState.
// Starts empty with isFinalized = false.
// ============================================================
class EnrolledSubjectsNotifier extends Notifier<EnrolmentState> {
  @override
  EnrolmentState build() {
    // -- Initial state: empty, not finalized --
    return const EnrolmentState();
  }

  // -- enrolSubjects: Replaces the enrolled list with new codes --
  // Called from the Subject Enrolment screen after the user
  // taps "Enrol & Set Timetable".
  // BLOCKED if already finalized or count violates constraints.
  //
  // meta: Map of code → EnrolledSubjectMeta so attendance can
  // initialize 50% records per subject (with/without lab).
  void enrolSubjects(
    List<String> subjectCodes, {
    Map<String, EnrolledSubjectMeta> meta = const {},
  }) {
    // -- Block if already finalized --
    if (state.isFinalized) return;

    // -- Block if count is outside 3–6 range --
    if (subjectCodes.length < kMinSubjects ||
        subjectCodes.length > kMaxSubjects) {
      return;
    }

    state = state.copyWith(
      subjectCodes: [...subjectCodes],
      subjectMeta: {...meta},
    );
  }

  // -- finalizeEnrolment: Permanently locks the enrolment --
  // Called after the user successfully saves their timetable.
  // After this, the enrolment screen shows a locked view and
  // all mutations are ignored.
  void finalizeEnrolment() {
    // -- Only finalize if subjects were enrolled --
    if (state.subjectCodes.isEmpty) return;
    state = state.copyWith(isFinalized: true);
  }

  // -- clearAll: Removes all enrolled subjects --
  // BLOCKED if already finalized.
  void clearAll() {
    if (state.isFinalized) return;
    state = const EnrolmentState();
  }
}
