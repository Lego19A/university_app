import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/firestore_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../models/lecturer_attendance_record.dart';

class LecturerAttendanceState {
  final String? selectedSubjectCode;
  final String selectedSessionType;
  final List<LecturerStudentAttendance> students;
  final bool isLoading;

  const LecturerAttendanceState({
    this.selectedSubjectCode,
    this.selectedSessionType = 'LEC',
    this.students = const [],
    this.isLoading = false,
  });

  LecturerAttendanceState copyWith({
    String? selectedSubjectCode,
    String? selectedSessionType,
    List<LecturerStudentAttendance>? students,
    bool? isLoading,
    bool clearSubject = false,
  }) {
    return LecturerAttendanceState(
      selectedSubjectCode: clearSubject ? null : selectedSubjectCode ?? this.selectedSubjectCode,
      selectedSessionType: selectedSessionType ?? this.selectedSessionType,
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LecturerAttendanceNotifier extends StateNotifier<LecturerAttendanceState> {
  final Ref _ref;
  LecturerAttendanceNotifier(this._ref) : super(const LecturerAttendanceState());

  Future<void> selectSubject(String? subjectCode, {String sessionType = 'LEC'}) async {
    if (subjectCode == null) {
      state = state.copyWith(clearSubject: true, students: []);
      return;
    }

    state = state.copyWith(
      selectedSubjectCode: subjectCode, 
      selectedSessionType: sessionType,
      isLoading: true
    );

    try {
      final firestore = _ref.read(firestoreRepositoryProvider);
      final userRepo = _ref.read(userRepositoryProvider);

      // 1. Get enrolled students
      final studentIds = await firestore.getStudentIdsForSubject(subjectCode);
      
      if (studentIds.isEmpty) {
        state = state.copyWith(students: [], isLoading: false);
        return;
      }

      // 2. Get student profiles for names and IDs
      final users = await userRepo.getUsersByIds(studentIds);
      final userMap = {for (var u in users) u.uid: u.full_name};
      final universityIdMap = {for (var u in users) u.uid: u.university_id};

      // 3. Get attendance records for this subject and session type
      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('subjectCode', isEqualTo: subjectCode)
          .where('sessionType', isEqualTo: sessionType)
          .get();

      final records = snapshot.docs;

      // 4. Build LecturerStudentAttendance list
      final studentsList = <LecturerStudentAttendance>[];
      for (final sid in studentIds) {
        final name = userMap[sid] ?? 'Unknown Student';
        final uniId = universityIdMap[sid] ?? 'Unknown ID';
        
        final Map<int, bool> weekAttendance = {};
        
        // Find records for this student
        for (final doc in records) {
          final data = doc.data();
          if (data['studentId'] == sid) {
            final week = data['week'] as int?;
            final status = data['status'] as String?;
            if (week != null && status != null) {
              weekAttendance[week] = status == 'present';
            }
          }
        }

        studentsList.add(LecturerStudentAttendance(
          studentId: sid,
          universityId: uniId,
          studentName: name,
          subjectCode: subjectCode,
          weekAttendance: weekAttendance,
        ));
      }

      studentsList.sort((a, b) => a.studentName.compareTo(b.studentName));
      state = state.copyWith(students: studentsList, isLoading: false);

    } catch (e) {
      state = state.copyWith(students: [], isLoading: false);
    }
  }

  Future<void> toggleAttendance(String studentId, int week, bool isPresent) async {
    if (state.selectedSubjectCode == null) return;
    
    // Optimistic UI update
    final updatedStudents = state.students.map((student) {
      if (student.studentId == studentId) {
        final newWeekAttendance = Map<int, bool>.from(student.weekAttendance);
        newWeekAttendance[week] = isPresent;
        return student.copyWith(weekAttendance: newWeekAttendance);
      }
      return student;
    }).toList();
    
    state = state.copyWith(students: updatedStudents);

    // Save to Firestore
    try {
      final firestore = _ref.read(firestoreRepositoryProvider);
      
      // Need to find existing record
      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('subjectCode', isEqualTo: state.selectedSubjectCode!)
          .where('sessionType', isEqualTo: state.selectedSessionType)
          .where('studentId', isEqualTo: studentId)
          .where('week', isEqualTo: week)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Update
        await snapshot.docs.first.reference.update({'status': isPresent ? 'present' : 'absent'});
      } else {
        // Create new
        await firestore.markAttendance(
          studentId: studentId,
          subjectCode: state.selectedSubjectCode!,
          sessionId: 'manual_${studentId}_${state.selectedSessionType}_week$week',
          sessionType: state.selectedSessionType,
          week: week,
          status: isPresent ? 'present' : 'absent',
        );
      }
    } catch (e) {
      // Revert on failure by reloading
      selectSubject(state.selectedSubjectCode, sessionType: state.selectedSessionType);
    }
  }
}

final lecturerAttendanceProvider =
    StateNotifierProvider<LecturerAttendanceNotifier, LecturerAttendanceState>((ref) {
  return LecturerAttendanceNotifier(ref);
});
