// ============================================================
// QR SESSION MODEL - Data class representing the decoded QR
// code payload for an attendance session.
//
// The QR code contains a JSON string with the following fields:
//   - sessionId: unique identifier to prevent duplicate scans
//   - subjectCode: e.g., "SE301"
//   - subjectName: e.g., "Software Engineering"
//   - sessionType: "LEC" or "LAB"
//   - date: formatted date string, e.g., "7 April 2026"
//   - time: formatted time range, e.g., "10:00 AM - 12:00 PM"
//   - expiryTimestamp: Unix ms timestamp after which the QR is invalid
//
// Example QR JSON:
// {
//   "sessionId": "se301_lec_202604071000",
//   "subjectCode": "SE301",
//   "subjectName": "Software Engineering",
//   "sessionType": "LEC",
//   "date": "7 April 2026",
//   "time": "10:00 AM - 12:00 PM",
//   "expiryTimestamp": 1712491200000
// }
// ============================================================

import 'dart:convert';

class QrSessionModel {
  final String sessionId;
  final String subjectCode;
  final String displayCode;
  final String subjectName;
  final String sessionType; // "LEC" or "LAB"
  final String date;
  final String time;
  final int week;
  final int expiryTimestamp;

  const QrSessionModel({
    required this.sessionId,
    required this.subjectCode,
    required this.displayCode,
    required this.subjectName,
    required this.sessionType,
    required this.date,
    required this.time,
    required this.week,
    required this.expiryTimestamp,
  });

  // ============================================================
  // fromJson - Parses a JSON map into a QrSessionModel.
  // Throws FormatException if required fields are missing.
  // ============================================================
  factory QrSessionModel.fromJson(Map<String, dynamic> json) {
    // -- Validate that all required fields are present --
    final requiredFields = [
      'sessionId',
      'subjectCode',
      'displayCode',
      'subjectName',
      'sessionType',
      'date',
      'time',
      'week',
      'expiryTimestamp',
    ];

    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        throw FormatException('Missing required field: $field');
      }
    }

    return QrSessionModel(
      sessionId: json['sessionId'] as String,
      subjectCode: json['subjectCode'] as String,
      displayCode: json['displayCode'] as String,
      subjectName: json['subjectName'] as String,
      sessionType: json['sessionType'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      week: json['week'] as int,
      expiryTimestamp: json['expiryTimestamp'] as int,
    );
  }

  // ============================================================
  // fromRawString - Parses a raw QR string (expected JSON) into
  // a QrSessionModel. Returns null if the string is invalid.
  // ============================================================
  static QrSessionModel? fromRawString(String rawString) {
    try {
      final Map<String, dynamic> json = jsonDecode(rawString);
      return QrSessionModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // -- Human-readable session type label --
  String get typeLabel {
    switch (sessionType.toUpperCase()) {
      case 'LEC':
        return 'Lecture (LEC)';
      case 'LAB':
        return 'Laboratory (LAB)';
      default:
        return sessionType;
    }
  }

  // -- Check if the QR code has expired --
  bool get isExpired {
    return DateTime.now().millisecondsSinceEpoch > expiryTimestamp;
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'subjectCode': subjectCode,
        'displayCode': displayCode,
        'subjectName': subjectName,
        'sessionType': sessionType,
        'date': date,
        'time': time,
        'week': week,
        'expiryTimestamp': expiryTimestamp,
      };
}
