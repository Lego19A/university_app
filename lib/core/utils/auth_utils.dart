// ============================================================
// AUTH UTILS - Centralized logout utility.
//
// This class provides a single `performLogout` method that:
//   1. Signs out from Firebase Auth
//   2. Invalidates ALL user-specific Riverpod providers so the
//      next user gets a completely fresh state (no data bleeding)
//   3. Navigates back to the Login page
//
// Both the Student (MenuScreen) and Lecturer (LecturerSettingsScreen)
// logout flows must go through this utility.
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// -- Import ALL providers that hold user-specific data --
import '../../features/enrolment/providers/enrolment_provider.dart';
import '../../features/timetable/providers/timetable_provider.dart';
import '../../features/attendance/providers/attendance_tracking_provider.dart';
import '../../features/attendance/providers/attendance_provider.dart';
import '../../features/lecturer/providers/lecturer_qr_provider.dart';
import '../../features/lecturer/providers/lecturer_settings_provider.dart';
import '../../features/lecturer/providers/lecturer_attendance_provider.dart';
import '../../features/lecturer/providers/lecturer_subjects_provider.dart';
import '../repositories/user_repository.dart';
import '../../login_page.dart';

class AuthUtils {
  /// Performs a complete, secure logout:
  ///   1. Signs out from Firebase
  ///   2. Wipes ALL in-memory provider state
  ///   3. Navigates to the Login screen (clearing the nav stack)
  static Future<void> performLogout(BuildContext context, WidgetRef ref) async {
    // -- Step 1: Firebase sign-out --
    await FirebaseAuth.instance.signOut();

    // -- Step 2: Invalidate all user-specific providers --
    // This forces every provider to reset to its initial/empty state
    // so no data from the previous user leaks into the next session.

    // Student providers
    ref.invalidate(enrolledSubjectCodesProvider);
    ref.invalidate(timetableNotifierProvider);
    ref.invalidate(savedTimetableProvider);
    ref.invalidate(attendanceTrackingProvider);
    ref.invalidate(attendanceNotifierProvider);
    ref.invalidate(attendanceRepositoryProvider);

    // Lecturer providers
    ref.invalidate(lecturerQrProvider);
    ref.invalidate(lecturerSettingsProvider);
    ref.invalidate(lecturerAttendanceProvider);
    ref.invalidate(lecturerSubjectsProvider);

    // User profile
    ref.invalidate(currentUserProvider);
    ref.invalidate(currentUserStreamProvider);

    // -- Step 3: Navigate to Login and clear the entire navigation stack --
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false, // Remove all routes below
      );
    }
  }
}
