// ============================================================
// LECTURER ATTENDANCE RECORD - Data class for a single student's
// attendance entry as seen in the lecturer's Attendance List.
//
// This model represents one row in the attendance list table,
// containing all information needed to display and filter by
// student, subject, session, date, and attendance status.
// ============================================================

// ============================================================
// AttendanceStatus - Enum representing the three possible
// attendance states visible in the lecturer's attendance list.
// ============================================================
class LecturerStudentAttendance {
  final String studentId;
  final String studentName;
  final String subjectCode;
  
  // Maps week number (1-5) to a boolean representing presence (true = present, false = absent)
  // If a week is not in the map, it means attendance hasn't been taken for that week yet.
  final Map<int, bool> weekAttendance;

  const LecturerStudentAttendance({
    required this.studentId,
    required this.studentName,
    required this.subjectCode,
    this.weekAttendance = const {},
  });

  LecturerStudentAttendance copyWith({
    Map<int, bool>? weekAttendance,
  }) {
    return LecturerStudentAttendance(
      studentId: studentId,
      studentName: studentName,
      subjectCode: subjectCode,
      weekAttendance: weekAttendance ?? this.weekAttendance,
    );
  }
}
