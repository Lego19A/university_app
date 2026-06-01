// ============================================================
// ATTENDANCE REPOSITORY - Simulated data layer for attendance
// records. This acts as the bridge between the app's state
// management and a future backend/database.
//
// Currently stores data in-memory. To connect to a real
// backend, replace the method bodies with HTTP/Firebase calls.
//
// Responsibilities:
//   - Store marked attendance records
//   - Check if a session has already been attended
//   - Return all recorded attendance entries
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/qr_session_model.dart';

// ============================================================
// AttendanceRecord - Represents a single marked attendance entry.
// Stores the session data + the timestamp when it was confirmed.
// ============================================================
class AttendanceRecord {
  final QrSessionModel session;
  final DateTime markedAt;

  const AttendanceRecord({
    required this.session,
    required this.markedAt,
  });
}

// ============================================================
// AttendanceRepository - Simulated repository.
// Replace the in-memory list with your backend API calls.
// ============================================================
class AttendanceRepository {
  // -- In-memory store of all attended sessions --
  final List<AttendanceRecord> _records = [];

  // -- Get all recorded attendance entries --
  List<AttendanceRecord> get records => List.unmodifiable(_records);

  // ============================================================
  // isAlreadyMarked - Checks if the given sessionId has already
  // been recorded. Used to prevent duplicate attendance.
  // ============================================================
  bool isAlreadyMarked(String sessionId) {
    return _records.any((record) => record.session.sessionId == sessionId);
  }

  // ============================================================
  // markAttendance - Records a new attendance entry.
  // Writes to both local state AND Firestore for persistence.
  // Returns true if successfully recorded.
  // ============================================================
  Future<bool> markAttendance(QrSessionModel session) async {
    if (isAlreadyMarked(session.sessionId)) {
      return false;
    }

    // -- Write to Firestore for permanent persistence --
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('attendance').add({
        'studentId': uid,
        'subjectCode': session.subjectCode,
        'sessionId': session.sessionId,
        'sessionType': session.sessionType,
        'week': session.week,
        'status': 'present',
        'markedAt': FieldValue.serverTimestamp(),
      });
    }

    // -- Also store locally for in-session duplicate detection --
    _records.add(AttendanceRecord(
      session: session,
      markedAt: DateTime.now(),
    ));

    return true;
  }
}
