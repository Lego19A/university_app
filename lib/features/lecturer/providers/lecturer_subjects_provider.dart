// ============================================================
// LECTURER SUBJECTS PROVIDER - Shared provider that fetches the
// full SubjectModel details for a lecturer's registered subjects.
//
// Flow (Option C):
//   1. Read the lecturer's AppUser profile (which has registeredSubjects)
//   2. Extract the subject codes from registeredSubjects
//   3. Fetch full SubjectModel documents from the 'subjects' collection
//
// This provider is shared across:
//   - LecturerQrScreen (subject dropdown for QR generation)
//   - LecturerAnnouncementScreen (subject dropdown for announcements)
//   - LecturerAttendanceProvider (to know which subjects to query)
//
// Usage:
//   final subjectsAsync = ref.watch(lecturerSubjectsProvider);
//   subjectsAsync.when(
//     data: (subjects) => ...,
//     loading: () => ...,
//     error: (e, _) => ...,
//   );
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/firestore_repository.dart';

// -- FutureProvider: fetches once per session, auto-disposes on logout --
// -- FutureProvider: fetches once per session, auto-disposes on logout --
final lecturerSubjectsProvider = StreamProvider<List<SubjectModel>>((ref) async* {
  // Step 1: Get the current user's profile
  final user = await ref.watch(currentUserProvider.future);
  
  if (user == null) {
    yield [];
    return;
  }

  // Step 2: Fetch from the 'subjects' collection
  // Since you mentioned the lecturerId in the subjects collection is the staff ID (e.g. L202601),
  // we use user.university_id which stores that value.
  final firestoreRepo = ref.read(firestoreRepositoryProvider);
  yield* firestoreRepo.getSubjectsForLecturer(user.university_id);
});
