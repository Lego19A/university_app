// ============================================================
// ATTENDANCE TRACKING PROVIDER - Manages per-subject attendance
// percentages driven by enrollment and QR scans.
//
// Architecture:
//   - On enrollment finalization: initializes each enrolled
//     subject's LEC (and LAB if applicable) record at 50%.
//   - On successful QR scan confirmation: increments the matching
//     (subjectCode, sessionType) record by kAttendanceIncrement.
//   - Exposes an aggregated list for the AttendanceScreen UI.
//
// Key constants:
//   - kBaseAttendance: Starting percentage after enrollment (50%)
//   - kAttendanceIncrement: Percentage gained per valid scan (10%)
//   - kMaxAttendance: Ceiling so percentage never exceeds 100%
//
// Validation enforced here:
//   1. Enrollment check  → QR subjectCode must be in enrolled list
//   2. Session type check → "LEC"/"LAB" and subject must have lab
//   3. Duplicate check   → sessionId already recorded
//   4. Expiry check      → expiryTimestamp exceeded
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/firestore_repository.dart';
import '../../enrolment/providers/enrolment_provider.dart';
import '../models/qr_session_model.dart';

// -- Tuning constants --
const int kMaxWeeks = 5;
const int kMaxAttendance = 100;

// ============================================================
// SubjectAttendanceSummary - What the AttendanceScreen displays.
// Replaces the static _SubjectAttendance internal class.
// ============================================================
class SubjectAttendanceSummary {
  final String code;
  final String name;
  final String type; // "LEC" or "LAB"
  final int percentage;
  final Set<int> weeksPresent;

  const SubjectAttendanceSummary({
    required this.code,
    required this.name,
    required this.type,
    required this.percentage,
    required this.weeksPresent,
  });

  SubjectAttendanceSummary copyWith({
    int? percentage,
    Set<int>? weeksPresent,
  }) {
    return SubjectAttendanceSummary(
      code: code,
      name: name,
      type: type,
      percentage: percentage ?? this.percentage,
      weeksPresent: weeksPresent ?? this.weeksPresent,
    );
  }
}

// ============================================================
// AttendanceKey - Composite key for isolating attendance per
// subject session. Two subjects with the same code but different
// sessionType are tracked completely independently.
// ============================================================
class _AttendanceKey {
  final String subjectCode;
  final String sessionType;

  const _AttendanceKey._(this.subjectCode, this.sessionType);

  factory _AttendanceKey(String subjectCode, String sessionType) {
    return _AttendanceKey._(
      subjectCode.toLowerCase(),
      sessionType.toLowerCase(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _AttendanceKey &&
      other.subjectCode == subjectCode &&
      other.sessionType == sessionType;

  @override
  int get hashCode => Object.hash(subjectCode, sessionType);
}

// ============================================================
// AttendanceTrackingState - Full state held by the notifier.
// ============================================================
class AttendanceTrackingState {
  // -- Composite-keyed percentages: (code, type) → percentage --
  final Map<_AttendanceKey, SubjectAttendanceSummary> records;

  // -- Set of already-recorded sessionIds for duplicate prevention --
  final Set<String> markedSessionIds;

  const AttendanceTrackingState({
    this.records = const {},
    this.markedSessionIds = const {},
  });

  AttendanceTrackingState copyWith({
    Map<_AttendanceKey, SubjectAttendanceSummary>? records,
    Set<String>? markedSessionIds,
  }) {
    return AttendanceTrackingState(
      records: records ?? this.records,
      markedSessionIds: markedSessionIds ?? this.markedSessionIds,
    );
  }

  // -- Convenience: sorted list of all summaries for the UI --
  List<SubjectAttendanceSummary> get summaryList {
    final list = records.values.toList();
    // Sort: by code ascending, then LEC before LAB
    list.sort((a, b) {
      final codeCompare = a.code.compareTo(b.code);
      if (codeCompare != 0) return codeCompare;
      return a.type.compareTo(b.type); // LEC < LAB alphabetically
    });
    return list;
  }
}

// ============================================================
// AttendanceTrackingNotifier - Core logic.
// ============================================================

/// Result type for scan processing — used by the UI layer
enum ScanOutcome {
  success,        // Valid scan, confirmation shown
  notEnrolled,    // subjectCode not in enrolled list
  invalidSession, // sessionType invalid or subject has no lab
  duplicate,      // sessionId already recorded
  expired,        // QR expiryTimestamp exceeded
  invalidFormat,  // Malformed JSON (handled upstream but kept for safety)
}

class ScanOutcomeResult {
  final ScanOutcome outcome;
  final QrSessionModel? session;
  final String message;

  const ScanOutcomeResult({
    required this.outcome,
    this.session,
    required this.message,
  });
}

class AttendanceTrackingNotifier
    extends StateNotifier<AttendanceTrackingState> {
  final Ref _ref;

  AttendanceTrackingNotifier(this._ref)
      : super(const AttendanceTrackingState());

  // ============================================================
  // loadAttendanceFromFirestore - Replaces initializeFromEnrollment
  // Fetches actual attendance records from Firestore and builds the summaries
  // ============================================================
  Future<void> loadAttendanceFromFirestore() async {
    final enrolmentState = _ref.read(enrolledSubjectCodesProvider);
    final metaMap = enrolmentState.subjectMeta;

    if (metaMap.isEmpty) return;

    final studentId = FirebaseAuth.instance.currentUser?.uid;
    if (studentId == null) return;

    final rawRecords = await _ref.read(firestoreRepositoryProvider).getAttendanceForStudent(studentId);
    
    final newRecords = <_AttendanceKey, SubjectAttendanceSummary>{};
    final newSessionIds = <String>{};

    for (final meta in metaMap.values) {
      // -- Initialize Lecture record --
      final lecKey = _AttendanceKey(meta.code, 'LEC');
      newRecords[lecKey] = SubjectAttendanceSummary(
        code: meta.code,
        name: meta.name,
        type: 'LEC',
        percentage: 0,
        weeksPresent: {},
      );

      // -- Initialize Lab record if applicable --
      if (meta.hasLab) {
        final labKey = _AttendanceKey(meta.code, 'LAB');
        newRecords[labKey] = SubjectAttendanceSummary(
          code: meta.code,
          name: meta.name,
          type: 'LAB',
          percentage: 0,
          weeksPresent: {},
        );
      }
    }

    // Populate with actual records
    for (final doc in rawRecords) {
      final subjectCode = doc['subjectCode'] as String? ?? '';
      final sessionType = (doc['sessionType'] as String? ?? '').toUpperCase();
      final sessionId = doc['sessionId'] as String? ?? '';
      final week = doc['week'] as int?;
      final status = doc['status'] as String? ?? '';

      newSessionIds.add(sessionId);

      final key = _AttendanceKey(subjectCode, sessionType);
      if (newRecords.containsKey(key) && week != null && status == 'present') {
        final current = newRecords[key]!;
        final updatedWeeks = Set<int>.from(current.weeksPresent)..add(week);
        final newPercentage = ((updatedWeeks.length / kMaxWeeks) * 100).toInt().clamp(0, kMaxAttendance);
        
        newRecords[key] = current.copyWith(
          percentage: newPercentage,
          weeksPresent: updatedWeeks,
        );
      }
    }

    state = state.copyWith(records: newRecords, markedSessionIds: newSessionIds);
  }

  // ============================================================
  // processScannedData - Validates the raw QR string through
  // the full 4-step pipeline. Returns a ScanOutcomeResult that
  // the QrScanScreen uses to decide what to show.
  //
  // Validation order (strict):
  //   1. Format check   → handled upstream by QrSessionModel
  //   2. Enrollment check → subjectCode in enrolled list?
  //   3. Session type   → valid type? Subject has lab if LAB?
  //   4. Expiry check   → timestamp exceeded?
  //   5. Duplicate      → sessionId already marked?
  //   6. All OK         → success, ready for confirmation
  // ============================================================
  ScanOutcomeResult processScannedData(String rawData) {
    // -- Step 1: Parse JSON --
    final session = QrSessionModel.fromRawString(rawData);
    if (session == null) {
      return const ScanOutcomeResult(
        outcome: ScanOutcome.invalidFormat,
        message: 'Invalid QR Code. Please scan a valid session QR.',
      );
    }

    final enrolledCodes = _ref.read(enrolledCodesListProvider);
    final metaMap = _ref.read(enrolledSubjectCodesProvider).subjectMeta;

    // -- Step 2: Enrollment check --
    if (!enrolledCodes.contains(session.subjectCode)) {
      return ScanOutcomeResult(
        outcome: ScanOutcome.notEnrolled,
        session: session,
        message:
            'You are not enrolled in ${session.subjectCode}. Only enrolled subjects are scannable.',
      );
    }

    // -- Step 3: Session type validation --
    final type = session.sessionType.toUpperCase();
    if (type != 'LEC' && type != 'LAB') {
      return ScanOutcomeResult(
        outcome: ScanOutcome.invalidSession,
        session: session,
        message: 'Invalid session type "${session.sessionType}". Expected LEC or LAB.',
      );
    }
    // -- If type is LAB, confirm the subject actually has a lab --
    if (type == 'LAB') {
      final meta = metaMap[session.subjectCode];
      if (meta == null || !meta.hasLab) {
        return ScanOutcomeResult(
          outcome: ScanOutcome.invalidSession,
          session: session,
          message:
              '${session.subjectCode} does not have a Lab session. Scan rejected.',
        );
      }
    }

    // -- Step 4: Expiry check --
    if (session.isExpired) {
      return ScanOutcomeResult(
        outcome: ScanOutcome.expired,
        session: session,
        message: 'This QR Code has expired. Please request a new one from your lecturer.',
      );
    }

    // -- Step 5: Duplicate check --
    if (state.markedSessionIds.contains(session.sessionId)) {
      return ScanOutcomeResult(
        outcome: ScanOutcome.duplicate,
        session: session,
        message: 'Attendance already marked for this specific class session.',
      );
    }

    // -- Step 6: All checks passed → ready for confirmation --
    return ScanOutcomeResult(
      outcome: ScanOutcome.success,
      session: session,
      message: 'Session found. Please confirm your attendance.',
    );
  }

  // ============================================================
  // confirmAttendance - Called when user taps "Update Attendance".
  // Increments the (subjectCode, sessionType) percentage by
  // kAttendanceIncrement, capped at kMaxAttendance.
  // Records the sessionId to prevent future duplicates.
  // ============================================================
  Future<bool> confirmAttendance(QrSessionModel session) async {
    final key = _AttendanceKey(
      session.subjectCode,
      session.sessionType,
    );

    // -- Guard: duplicate safety (belt and suspenders) --
    if (state.markedSessionIds.contains(session.sessionId)) return false;

    try {
      final studentId = FirebaseAuth.instance.currentUser?.uid;
      if (studentId != null) {
        // -- Save to Firestore --
        await _ref.read(firestoreRepositoryProvider).markAttendance(
              studentId: studentId,
              subjectCode: session.subjectCode,
              sessionId: session.sessionId,
              sessionType: session.sessionType,
              week: session.week,
              status: 'present',
            );
      }
    } catch (e) {
      return false; // Failed to save to database
    }

    final updatedRecords =
        Map<_AttendanceKey, SubjectAttendanceSummary>.from(state.records);
        
    // -- Update local state if it exists, otherwise reject --
    if (updatedRecords.containsKey(key)) {
      final current = updatedRecords[key]!;
      final updatedWeeks = Set<int>.from(current.weeksPresent)..add(session.week);
      final newPercentage = ((updatedWeeks.length / kMaxWeeks) * 100).toInt().clamp(0, kMaxAttendance);

      updatedRecords[key] = current.copyWith(
          percentage: newPercentage,
          weeksPresent: updatedWeeks,
      );
    } else {
      // Key doesn't exist, meaning the student hasn't enrolled in this session type or subject.
      // Ghost container prevention.
      return false;
    }

    final updatedIds = Set<String>.from(state.markedSessionIds)
      ..add(session.sessionId);

    state = state.copyWith(
      records: updatedRecords,
      markedSessionIds: updatedIds,
    );

    return true;
  }
}

// ============================================================
// PROVIDERS
// ============================================================

final attendanceTrackingProvider = StateNotifierProvider<
    AttendanceTrackingNotifier, AttendanceTrackingState>((ref) {
  return AttendanceTrackingNotifier(ref);
});

// -- Convenience: pre-sorted list of summaries for the UI --
final attendanceSummaryListProvider =
    Provider<List<SubjectAttendanceSummary>>((ref) {
  return ref.watch(attendanceTrackingProvider).summaryList;
});
