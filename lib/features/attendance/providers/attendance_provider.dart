// ============================================================
// ATTENDANCE PROVIDER - Riverpod state management for scanning
// and marking attendance.
//
// Handles:
//   1. Processing scanned QR data (parse, validate, store)
//   2. Duplicate detection (same sessionId already recorded)
//   3. Expiry validation (QR code has passed its timestamp)
//   4. Format validation (invalid or malformed JSON)
//   5. Exposing scanned attendance history to the UI
//
// The ScanResult sealed class communicates outcomes back to
// the UI layer without coupling to Flutter widgets.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qr_session_model.dart';
import '../repositories/attendance_repository.dart';

// ============================================================
// SCAN RESULT - Represents the outcome of processing a scan.
// Used by the UI to decide what to show (confirmation, error).
// ============================================================
enum ScanResultType {
  success,       // Valid QR, ready for confirmation
  expired,       // QR code has passed its expiry time
  duplicate,     // Attendance already marked for this session
  invalidFormat, // Malformed or unrecognized QR content
}

class ScanResult {
  final ScanResultType type;
  final QrSessionModel? session;
  final String message;

  const ScanResult({
    required this.type,
    this.session,
    required this.message,
  });
}

// ============================================================
// ATTENDANCE NOTIFIER - Core logic for the attendance feature.
// ============================================================
class AttendanceNotifier extends StateNotifier<List<AttendanceRecord>> {
  final AttendanceRepository _repository;

  AttendanceNotifier(this._repository) : super(_repository.records);

  // ============================================================
  // processScannedData - Takes the raw string from the QR scanner
  // and runs it through validation. Returns a ScanResult.
  //
  // Validation order:
  //   1. Parse JSON → if fails → invalidFormat
  //   2. Check expiry → if expired → expired
  //   3. Check duplicate → if exists → duplicate
  //   4. All OK → success (session ready for confirmation)
  // ============================================================
  ScanResult processScannedData(String rawData) {
    // -- Step 1: Parse JSON --
    final session = QrSessionModel.fromRawString(rawData);
    if (session == null) {
      return const ScanResult(
        type: ScanResultType.invalidFormat,
        message: 'Invalid QR Code. Please scan a valid session QR.',
      );
    }

    // -- Step 2: Check expiry --
    if (session.isExpired) {
      return ScanResult(
        type: ScanResultType.expired,
        session: session,
        message: 'This QR Code has expired. Please request a new one.',
      );
    }

    // -- Step 3: Check duplicate --
    if (_repository.isAlreadyMarked(session.sessionId)) {
      return ScanResult(
        type: ScanResultType.duplicate,
        session: session,
        message: 'Attendance already marked for this session.',
      );
    }

    // -- Step 4: Valid → return for confirmation --
    return ScanResult(
      type: ScanResultType.success,
      session: session,
      message: 'Session found. Please confirm your attendance.',
    );
  }

  // ============================================================
  // confirmAttendance - Called when user taps "Update Attendance"
  // on the confirmation sheet. Persists the record.
  // Returns true if successfully recorded.
  // ============================================================
  Future<bool> confirmAttendance(QrSessionModel session) async {
    final success = await _repository.markAttendance(session);
    if (success) {
      // Refresh state from repository so UI updates
      state = List.from(_repository.records);
    }
    return success;
  }
}

// ============================================================
// PROVIDERS
// ============================================================

// -- Repository: singleton instance --
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

// -- Notifier: manages attendance state --
final attendanceNotifierProvider =
    StateNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return AttendanceNotifier(repository);
});
