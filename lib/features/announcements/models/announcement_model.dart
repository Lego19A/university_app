// ============================================================
// ANNOUNCEMENT MODEL - Data class representing a lecturer
// announcement sent to students enrolled in a specific subject.
//
// Fields:
//   - id            : Firestore document ID
//   - lecturerId    : UID of the lecturer who sent it
//   - lecturerName  : Display name of the lecturer
//   - subjectCode   : e.g. "SE301"
//   - subjectName   : e.g. "Software Engineering"
//   - title         : Short announcement headline
//   - message       : Full announcement body text
//   - createdAt     : Timestamp when the announcement was sent
//
// Firestore collection: 'announcements'
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  // -- Firestore document ID (auto-generated) --
  final String id;

  // -- UID of the lecturer who created this announcement --
  final String lecturerId;

  // -- Display name of the lecturer (stored for easy rendering) --
  final String lecturerName;

  // -- Subject code this announcement is for (backend ID) --
  final String subjectCode;

  // -- Display code for UI (e.g. "SE301") --
  final String displayCode;

  // -- Full subject name (e.g. "Software Engineering") --
  final String subjectName;

  // -- Short headline for the announcement --
  final String title;

  // -- Full body text of the announcement --
  final String message;

  // -- When the announcement was created --
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.lecturerId,
    required this.lecturerName,
    required this.subjectCode,
    required this.displayCode,
    required this.subjectName,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  // ============================================================
  // toJson - Converts this model to a Firestore-compatible Map.
  // The 'createdAt' field uses Firestore's Timestamp type.
  // ============================================================
  Map<String, dynamic> toJson() => {
        'lecturerId': lecturerId,
        'lecturerName': lecturerName,
        'subjectCode': subjectCode,
        'displayCode': displayCode,
        'subjectName': subjectName,
        'title': title,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  // ============================================================
  // fromFirestore - Factory constructor to create an instance
  // from a Firestore DocumentSnapshot.
  // ============================================================
  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      lecturerId: data['lecturerId'] as String? ?? '',
      lecturerName: data['lecturerName'] as String? ?? 'Unknown',
      subjectCode: data['subjectCode'] as String? ?? '',
      displayCode: data['displayCode'] as String? ?? (data['subjectCode'] as String? ?? ''),
      subjectName: data['subjectName'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
