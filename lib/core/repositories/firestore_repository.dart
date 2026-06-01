// ============================================================
// FIRESTORE REPOSITORY - Central data access layer for subjects,
// enrollments, and attendance records.
//
// This replaces ALL hardcoded data throughout the app:
//   - _semesterSubjects map in SubjectEnrolmentScreen
//   - _mockRecords() in LecturerAttendanceProvider
//   - _subjects list in LecturerQrScreen & AnnouncementScreen
//   - In-memory AttendanceRepository
//
// Architecture:
//   - Each method is focused on a single collection query
//   - Streams are used for real-time UI updates (StreamBuilder)
//   - Futures are used for one-time fetches
//   - Batch writes are used for atomic multi-document operations
//
// Firestore Collections:
//   - users        : Student/Lecturer profiles (see user_repository.dart)
//   - subjects     : Available subjects with semester + lecturer assignment
//   - enrollments  : Student-to-subject links (many-to-many)
//   - attendance   : Individual attendance scan records
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================
// SubjectSessionModel - Represents one available time slot for
// a subject session in Firestore. Stored inside the subject
// document as an array of maps under 'availableSessions'.
//
// Firestore schema for each entry:
//   { "id": "SE301_lec_mon10", "type": "lecture",
//     "day": "MON", "startTime": 1000, "durationHours": 1 }
// ============================================================
class SubjectSessionModel {
  final String id;             // Unique ID, e.g. "SE301_lec_mon10"
  final String type;           // "lecture" or "lab"
  final String day;            // "MON", "TUE", "WED", "THU", "FRI"
  final int time;         // Military time: 800, 1000, 1400, etc.
  final int durationHours;     // 2 for lecture, 2 for lab, etc.

  const SubjectSessionModel({
    required this.id,
    required this.type,
    required this.day,
    required this.time,
    required this.durationHours,
  });

  // -- Parse from a Map (inside the Firestore array) --
  factory SubjectSessionModel.fromMap(Map<String, dynamic> map) {
    // Safely parse time (could be int or String)
    int parsedStartTime = 800;
    if (map['time'] != null) {
      if (map['time'] is num) {
        parsedStartTime = (map['time'] as num).toInt();
      } else if (map['time'] is String) {
        parsedStartTime = int.tryParse(map['time']) ?? 800;
      }
    }

    return SubjectSessionModel(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'lecture',
      day: map['day']?.toString().toUpperCase() ?? 'MON',
      time: parsedStartTime,
      durationHours: 2, // Hardcoded to 2 hours per user request
    );
  }

  // -- Convert to Map for Firestore writes --
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'day': day,
        'time': time,
      };

  // -- Convert day string ("MON") to dayOfWeek int (1=Mon, 5=Fri) --
  int get dayOfWeek {
    switch (day.toUpperCase()) {
      case 'MON': return 1;
      case 'TUE': return 2;
      case 'WED': return 3;
      case 'THU': return 4;
      case 'FRI': return 5;
      default: return 1;
    }
  }

  // -- Convert military time (1000) to hour int (10), or handle normal hours (10) --
  int get startHour {
    if (time < 24) return time; // Already in hours format (e.g., 8, 14)
    return time ~/ 100; // Convert from military (e.g., 800 -> 8)
  }
}

// ============================================================
// SubjectModel - Clean model for a Firestore 'subjects' document.
// Replaces the raw Map<String, String> used in the old screen.
// ============================================================
class SubjectModel {
  final String id;            // Document ID
  final String code;          // e.g. "SE301"
  final String name;          // "Software Engineering"
  final int credits;          // 3 or 4
  final bool requiresLab;    // Whether it has LEC + LAB
  final String semester;      // "Semester 1", "Semester 2", etc.
  final String lecturerId;    // Firebase Auth UID of assigned lecturer
  final List<SubjectSessionModel> offered_sessions; // Pre-defined time slots

  const SubjectModel({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.requiresLab,
    required this.semester,
    required this.lecturerId,
    this.offered_sessions = const [],
  });

  // -- Factory: Parse a Firestore document into SubjectModel --
  factory SubjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Safely parse credits
    int parsedCredits = 3;
    if (data['credits'] != null) {
      if (data['credits'] is num) {
        parsedCredits = (data['credits'] as num).toInt();
      } else if (data['credits'] is String) {
        parsedCredits = int.tryParse(data['credits']) ?? 3;
      }
    }

    // Safely parse requiresLab
    bool parsedRequiresLab = false;
    if (data['requiresLab'] != null) {
      if (data['requiresLab'] is bool) {
        parsedRequiresLab = data['requiresLab'];
      } else if (data['requiresLab'] is String) {
        parsedRequiresLab = data['requiresLab'].toString().toLowerCase() == 'true';
      }
    }

    // Parse offered_sessions array from Firestore
    List<SubjectSessionModel> parsedSessions = [];
    if (data['offered_sessions'] != null && data['offered_sessions'] is List) {
      parsedSessions = (data['offered_sessions'] as List)
          .where((item) => item is Map)
          .map((item) => SubjectSessionModel.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    return SubjectModel(
      id: doc.id,
      code: data['code']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'Unknown Subject',
      credits: parsedCredits,
      requiresLab: parsedRequiresLab,
      semester: data['semester']?.toString() ?? '',
      lecturerId: data['lecturerId']?.toString() ?? '',
      offered_sessions: parsedSessions,
    );
  }

  // -- Convert to Map for Firestore writes (admin/seeding use) --
  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'credits': credits,
        'requiresLab': requiresLab,
        'semester': semester,
        'lecturerId': lecturerId,
        'offered_sessions': offered_sessions.map((s) => s.toMap()).toList(),
      };
}

// ============================================================
// EnrollmentModel - Represents a student → subject enrollment.
// ============================================================
class EnrollmentModel {
  final String id;            // Firestore document ID
  final String studentId;     // Firebase Auth UID
  final String subjectCode;   // References subjects collection
  final DateTime enrolledAt;
  final String status;        // "active" | "dropped"

  const EnrollmentModel({
    required this.id,
    required this.studentId,
    required this.subjectCode,
    required this.enrolledAt,
    required this.status,
  });

  factory EnrollmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EnrollmentModel(
      id: doc.id,
      studentId: (data['studentId'] as String?) ?? '',
      subjectCode: (data['subjectCode'] as String?) ?? '',
      enrolledAt: (data['enrolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: (data['status'] as String?) ?? 'active',
    );
  }
}

// ============================================================
// FirestoreRepository - Central data access class.
// ============================================================
class FirestoreRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // SUBJECTS
  // ============================================================

  // -- Fetch all subjects for a given semester (real-time stream) --
  // Used by SubjectEnrolmentScreen to populate the subject list.
  // Returns a Stream so the UI updates instantly if subjects change.
  Stream<List<SubjectModel>> getSubjectsForSemester(String semester) {
    return _db
        .collection('subjects')
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SubjectModel.fromFirestore(doc)).toList());
  }

  // -- Fetch all available semesters (distinct values) --
  // Used to populate the semester dropdown. Since Firestore
  // doesn't support DISTINCT, we fetch all subjects and extract
  // unique semester values client-side.
  Future<List<String>> getAvailableSemesters() async {
    final snapshot = await _db.collection('subjects').get();
    final semesters = snapshot.docs
        .map((doc) => (doc.data()['semester'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    semesters.sort(); // Alphabetical sort: "Semester 1", "Semester 2", etc.
    return semesters;
  }

  // -- Fetch subjects assigned to a specific lecturer --
  // Used by LecturerQrScreen and LecturerAnnouncementScreen
  // to populate the subject dropdown dynamically.
  Stream<List<SubjectModel>> getSubjectsForLecturer(String lecturerId) {
    return _db
        .collection('subjects')
        .where('lecturerId', isEqualTo: lecturerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SubjectModel.fromFirestore(doc)).toList());
  }

  // -- Fetch full SubjectModel details for a list of subject codes --
  // Used by the lecturer interface: the user profile has a
  // 'registered_subjects' array with {code, name}. We take those
  // codes and fetch the full documents from the 'subjects' collection
  // so we get requiresLab, offered_sessions, etc.
  Future<List<SubjectModel>> getSubjectsByCodes(List<String> codes) async {
    if (codes.isEmpty) return [];

    // Firestore 'whereIn' supports max 30 items. Chunk for safety.
    List<SubjectModel> results = [];
    for (var i = 0; i < codes.length; i += 10) {
      final chunk = codes.sublist(
        i,
        i + 10 > codes.length ? codes.length : i + 10,
      );
      final snapshot = await _db
          .collection('subjects')
          .where('code', whereIn: chunk)
          .get();
      results.addAll(
        snapshot.docs.map((doc) => SubjectModel.fromFirestore(doc)).toList(),
      );
    }
    return results;
  }

  // -- Fetch a single subject by code --
  Future<SubjectModel?> getSubjectByCode(String code) async {
    final doc = await _db.collection('subjects').doc(code).get();
    if (!doc.exists) return null;
    return SubjectModel.fromFirestore(doc);
  }

  // ============================================================
  // ENROLLMENTS
  // ============================================================

  // -- Enroll a student in multiple subjects atomically --
  // Uses a WriteBatch so all enrollments succeed or none do.
  Future<void> enrollStudent(String studentId, List<String> subjectCodes) async {
    final batch = _db.batch();

    // Option A: One document per student in 'enrollments' containing the list of subjects
    final userDoc = await _db.collection('users').doc(studentId).get();
    final universityId = userDoc.data()?['universityId'] ?? userDoc.data()?['lecturerId'] ?? '';

    final docRef = _db.collection('enrollments').doc(studentId);
    batch.set(docRef, {
      'studentId': studentId,
      'universityId': universityId,
      'subjects': subjectCodes,
      'enrolledAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    await batch.commit();
  }

  // -- Check if a student has any active enrollments --
  // Used to determine if enrolment is already finalized.
  Future<bool> hasActiveEnrollments(String studentId) async {
    final doc = await _db.collection('enrollments').doc(studentId).get();
    if (!doc.exists) return false;
    
    final data = doc.data();
    return data != null && data['status'] == 'active';
  }

  // -- Get all active enrollments for a student (real-time) --
  // Used by AttendanceScreen to know which subjects to show.
  Stream<List<EnrollmentModel>> getStudentEnrollments(String studentId) {
    return _db
        .collection('enrollments')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EnrollmentModel.fromFirestore(doc)).toList());
  }

  Future<List<String>> getEnrolledSubjectCodes(String studentId) async {
    final doc = await _db.collection('enrollments').doc(studentId).get();
    if (!doc.exists) return [];
    
    final data = doc.data();
    if (data == null || data['status'] != 'active') return [];

    final subjects = data['subjects'] as List<dynamic>? ?? [];
    return subjects.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  // -- Get all students enrolled in a specific subject --
  // Used by LecturerAttendanceScreen to see enrolled students.
  Future<List<String>> getStudentIdsForSubject(String subjectCode) async {
    final snapshot = await _db
        .collection('enrollments')
        .where('subjects', arrayContains: subjectCode)
        .where('status', isEqualTo: 'active')
        .get();
    return snapshot.docs
        .map((doc) => (doc.data()['studentId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  // ============================================================
  // ATTENDANCE
  // ============================================================

  // -- Record a student's attendance scan --
  // Called after a student successfully scans a QR code.
  Future<void> markAttendance({
    required String studentId,
    required String subjectCode,
    required String sessionId,
    required String sessionType,
    required int week,
    required String status, // "present" or "late"
  }) async {
    await _db.collection('attendance').add({
      'studentId': studentId,
      'subjectCode': subjectCode,
      'sessionId': sessionId,
      'sessionType': sessionType,
      'week': week,
      'status': status,
      'markedAt': FieldValue.serverTimestamp(),
    });
  }

  // -- Check if a student has already scanned for a specific session --
  Future<bool> isAttendanceMarked(String studentId, String sessionId) async {
    final snapshot = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .where('sessionId', isEqualTo: sessionId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // -- Get all attendance records for subjects taught by a lecturer --
  // Used by LecturerAttendanceProvider to populate the attendance list.
  // First resolves the lecturer's subject codes, then queries attendance.
  Stream<List<Map<String, dynamic>>> getAttendanceForLecturer(
      String lecturerId) {
    // We need a two-step query:
    // 1. Get the lecturer's subject codes
    // 2. Query attendance for those subject codes
    return _db
        .collection('subjects')
        .where('lecturerId', isEqualTo: lecturerId)
        .snapshots()
        .asyncMap((subjectsSnapshot) async {
      final subjectCodes =
          subjectsSnapshot.docs.map((doc) => doc.id).toList();

      if (subjectCodes.isEmpty) return <Map<String, dynamic>>[];

      // Firestore 'whereIn' supports max 30 values (updated limit).
      // For safety, we chunk at 10 to maintain broad compatibility.
      List<Map<String, dynamic>> allRecords = [];
      for (var i = 0; i < subjectCodes.length; i += 10) {
        final chunk = subjectCodes.sublist(
          i,
          i + 10 > subjectCodes.length ? subjectCodes.length : i + 10,
        );
        final attendanceSnapshot = await _db
            .collection('attendance')
            .where('subjectCode', whereIn: chunk)
            .orderBy('markedAt', descending: true)
            .get();

        for (final doc in attendanceSnapshot.docs) {
          allRecords.add({
            'id': doc.id,
            ...doc.data(),
          });
        }
      }
      return allRecords;
    });
  }

  // -- Get all attendance records for a specific student --
  Future<List<Map<String, dynamic>>> getAttendanceForStudent(
      String studentId) async {
    final snapshot = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // ============================================================
  // TIMETABLE PERSISTENCE
  // ============================================================

  // -- Save a student's timetable layout to Firestore --
  // Each session is serialized as a Map (via Session.toMap()).
  // Stored as a single document under timetables/{studentId}.
  Future<void> saveTimetable(
      String studentId, List<Map<String, dynamic>> sessions) async {
    await _db.collection('timetables').doc(studentId).set({
      'sessions': sessions,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  // -- Retrieve a student's saved timetable from Firestore --
  // Returns a list of raw Maps, or null if no timetable is saved.
  Future<List<Map<String, dynamic>>?> getTimetable(String studentId) async {
    final doc = await _db.collection('timetables').doc(studentId).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    if (data['sessions'] == null || data['sessions'] is! List) return null;

    return (data['sessions'] as List)
        .where((item) => item is Map)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}

// ============================================================
// PROVIDERS
// ============================================================

// -- Singleton Firestore repository instance --
final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  return FirestoreRepository();
});

// -- Available semesters for the enrollment dropdown --
final availableSemestersProvider = FutureProvider<List<String>>((ref) {
  return ref.read(firestoreRepositoryProvider).getAvailableSemesters();
});

