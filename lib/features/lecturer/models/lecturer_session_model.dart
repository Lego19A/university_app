// ============================================================
// LECTURER SESSION MODEL - Data class representing a QR session
// created by the lecturer for student attendance tracking.
//
// This mirrors the QrSessionModel that students scan, because
// they must produce compatible JSON for the student-side parser.
//
// Fields:
//   - sessionId       : Unique identifier (prevents duplicate scans)
//   - subjectCode     : e.g. "SE301"
//   - subjectName     : e.g. "Software Engineering"
//   - sessionType     : "LEC" or "LAB"
//   - date            : Human-readable date string
//   - time            : Human-readable time range string
//   - expiryTimestamp : Unix ms timestamp when the QR expires
//   - durationMinutes : How long (in minutes) the QR stays valid
// ============================================================

import 'dart:convert'; // Needed for jsonEncode → converts model to QR string

class LecturerSessionModel {
  // -- Unique ID for this specific class session (used for duplicate prevention) --
  final String sessionId;

  // -- Short subject code matching the student's enrolled subject codes --
  final String subjectCode;

  // -- Display code for the UI --
  final String displayCode;

  // -- Full display name of the subject --
  final String subjectName;

  // -- Either "LEC" (Lecture) or "LAB" (Laboratory) --
  final String sessionType;

  // -- Human-readable date shown in the generated QR confirmation card --
  final String date;

  // -- Human-readable time range shown in the generated QR confirmation card --
  final String time;

  // -- Unix millisecond timestamp after which the QR code is invalid --
  final int expiryTimestamp;

  // -- The week number for this session (1 to 5) --
  final int week;

  // -- Duration in minutes for which this session is valid --
  final int durationMinutes;

  const LecturerSessionModel({
    required this.sessionId,
    required this.subjectCode,
    required this.displayCode,
    required this.subjectName,
    required this.sessionType,
    required this.date,
    required this.time,
    required this.week,
    required this.expiryTimestamp,
    required this.durationMinutes,
  });

  // ============================================================
  // toJson - Converts this model to a JSON-serializable Map.
  // The output must match the exact field names that the student-
  // side QrSessionModel.fromJson() expects, otherwise scans fail.
  // ============================================================
  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,        // Matches QrSessionModel.fromJson key
        'subjectCode': subjectCode,    // Matches QrSessionModel.fromJson key
        'displayCode': displayCode,    // Matches QrSessionModel.fromJson key
        'subjectName': subjectName,    // Matches QrSessionModel.fromJson key
        'sessionType': sessionType,    // Matches QrSessionModel.fromJson key
        'date': date,                  // Matches QrSessionModel.fromJson key
        'time': time,                  // Matches QrSessionModel.fromJson key
        'week': week,                  // Matches QrSessionModel.fromJson key
        'expiryTimestamp': expiryTimestamp, // Matches QrSessionModel.fromJson key
      };

  // ============================================================
  // toQrString - Encodes this model to a JSON string.
  // This string is what gets embedded in the QR code image.
  // The student scanner decodes this string back into a session.
  // ============================================================
  String toQrString() => jsonEncode(toJson());

  // ============================================================
  // isExpired - Returns true if the session expiry has passed.
  // Used by the QR screen timer to show the "Expired" state.
  // ============================================================
  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch > expiryTimestamp;

  // ============================================================
  // remainingSeconds - How many seconds remain before expiry.
  // Returns 0 if already expired (never returns negative).
  // ============================================================
  int get remainingSeconds {
    // -- Calculate remaining milliseconds, floor to 0 if negative --
    final remaining =
        expiryTimestamp - DateTime.now().millisecondsSinceEpoch;
    return (remaining / 1000).ceil().clamp(0, double.maxFinite.toInt());
  }

  // ============================================================
  // generate - Factory constructor that builds a new session
  // with an auto-generated sessionId and a computed expiry.
  //
  // Parameters:
  //   subjectCode     : Subject code selected by the lecturer
  //   subjectName     : Full name of the subject
  //   sessionType     : "LEC" or "LAB"
  //   week            : The week number (1 to 5)
  //   durationMinutes : Duration for which the QR should be valid
  // ============================================================
  factory LecturerSessionModel.generate({
    required String subjectCode,
    required String displayCode,
    required String subjectName,
    required String sessionType,
    required int week,
    required int durationMinutes,
  }) {
    // -- Capture the current timestamp for ID generation and expiry calc --
    final now = DateTime.now();

    // -- Build a unique session ID using code + type + timestamp --
    // Format: "se301_lec_20260422191200" → highly collision-resistant
    final id =
        '${subjectCode.toLowerCase()}_${sessionType.toLowerCase()}_'
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    // -- Compute expiry: current time + duration in milliseconds --
    final expiry =
        now.millisecondsSinceEpoch + (durationMinutes * 60 * 1000);

    // -- Format human-readable date: "22 April 2026" --
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    // -- Format human-readable time range: "19:12 - 20:12" --
    final endTime = now.add(Duration(minutes: durationMinutes));
    String pad(int n) => n.toString().padLeft(2, '0');
    final timeStr =
        '${pad(now.hour)}:${pad(now.minute)} - '
        '${pad(endTime.hour)}:${pad(endTime.minute)}';

    return LecturerSessionModel(
      sessionId: id,
      subjectCode: subjectCode,
      displayCode: displayCode,
      subjectName: subjectName,
      sessionType: sessionType,
      week: week,
      date: dateStr,
      time: timeStr,
      expiryTimestamp: expiry,
      durationMinutes: durationMinutes,
    );
  }
}
