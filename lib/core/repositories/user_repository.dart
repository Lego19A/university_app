// ============================================================
// USER REPOSITORY - Fetches and caches the current user's profile
// from the Firestore 'users' collection.
//
// This is the SINGLE SOURCE OF TRUTH for user data across:
//   - Student ProfileScreen
//   - Lecturer ProfileScreen
//   - DashboardScreen (greeting name)
//   - Any widget that needs role, name, or user metadata
//
// Usage (in a ConsumerWidget):
//   final userAsync = ref.watch(currentUserProvider);
//   userAsync.when(
//     data: (user) => Text(user?.fullName ?? 'Guest'),
//     loading: () => CircularProgressIndicator(),
//     error: (e, _) => Text('Error: $e'),
//   );
// ============================================================

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================
// AppUser - Clean model class for a user profile document.
// Replaces hardcoded strings scattered across profile screens.
// ============================================================
class AppUser {
  final String uid;
  final String role;          // "student" or "lecturer"
  final String full_name;
  final String university_id;  // Student ID or Staff ID
  final String email;

  // -- Flexible metadata map for role-specific fields --
  // Students: { programme, faculty, intake, cgpa, status }
  // Lecturers: { department, faculty, specialization, office, status }
  final Map<String, dynamic> metadata;

  // -- Registered subjects for lecturers --
  // Each entry is a map with at least { 'code': ..., 'name': ..., 'require_lab': ... }
  // Parsed from the 'registered_subjects' array in the user document.
  final List<Map<String, dynamic>> registeredSubjects;

  const AppUser({
    required this.uid,
    required this.role,
    required this.full_name,
    required this.university_id,
    required this.email,
    this.metadata = const {},
    this.registeredSubjects = const [],
  });

  // -- Factory: Parse Firestore document into AppUser --
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // -- Parse registered_subjects array from Firestore --
    List<Map<String, dynamic>> parsedSubjects = [];
    if (data['registered_subjects'] != null) {
      final regSubj = data['registered_subjects'];
      Iterable iterable;
      if (regSubj is List) {
        iterable = regSubj;
      } else if (regSubj is Map) {
        // Fallback: If accidentally created as a Map with "0", "1" keys
        iterable = regSubj.values;
      } else if (regSubj is String) {
        // Fallback: If saved as a JSON string
        try {
          final decoded = jsonDecode(regSubj);
          iterable = decoded is List ? decoded : [];
        } catch (_) {
          iterable = [];
        }
      } else {
        iterable = [];
      }

      parsedSubjects = iterable
          .where((item) => item is Map)
          .map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            
            // Handle boolean safely (it might be true/false or a string "true")
            bool reqLab = false;
            if (m['require_lab'] != null) {
              if (m['require_lab'] is bool) {
                reqLab = m['require_lab'];
              } else if (m['require_lab'] is String) {
                reqLab = m['require_lab'].toString().toLowerCase() == 'true';
              }
            }

            return {
              'code': m['code']?.toString() ?? '',
              'name': m['name']?.toString() ?? '',
              'require_lab': reqLab,
            };
          })
          .where((m) => (m['code'] as String).isNotEmpty)
          .toList();
    }

    return AppUser(
      uid: doc.id,
      role: (data['role'] as String?) ?? 'student',
      full_name: (data['full_name'] as String?) ?? 'Unknown',
      university_id: (data['university_id'] as String?) ?? (data['lecturer_id'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? {},
      registeredSubjects: parsedSubjects,
    );
  }

  // -- Convenience getters for common metadata fields --
  String get programme => metadata['programme'] as String? ?? '';
  String get faculty => metadata['faculty'] as String? ?? '';
  String get intake => metadata['intake'] as String? ?? '';
  String get cgpa => metadata['cgpa'] as String? ?? '';
  String get status => metadata['status'] as String? ?? 'Active';
  String get department => metadata['department'] as String? ?? '';
  String get specialization => metadata['specialization'] as String? ?? '';
  String get office => metadata['office'] as String? ?? '';

  // -- Whether this user is a lecturer --
  bool get isLecturer => role == 'lecturer';
  bool get isStudent => role == 'student';
}

// ============================================================
// UserRepository - Thin Firestore wrapper for user operations.
// ============================================================
class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -- Fetch a user profile by their Firebase Auth UID --
  Future<AppUser?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  // -- Fetch multiple users by their UIDs --
  Future<List<AppUser>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    List<AppUser> users = [];
    for (var i = 0; i < uids.length; i += 10) {
      final chunk = uids.sublist(
        i,
        i + 10 > uids.length ? uids.length : i + 10,
      );
      final snapshot = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      users.addAll(snapshot.docs.map((doc) => AppUser.fromFirestore(doc)));
    }
    return users;
  }

  // -- Stream a user profile (for real-time updates) --
  Stream<AppUser?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }
}

// ============================================================
// PROVIDERS
// ============================================================

// -- Singleton repository instance --
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// -- Reactively watch Firebase Auth State --
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// -- Current Firebase Auth UID (reactive) --
// This automatically updates when the user logs in or out.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

// -- Current user profile as an async future --
// Automatically refetches when the provider is first read.
// Returns null if not logged in or document doesn't exist.
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return ref.read(userRepositoryProvider).getUserById(uid);
});

// -- Current user profile as a real-time stream --
// Use this when you want the profile to update live.
final currentUserStreamProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.read(userRepositoryProvider).streamUser(uid);
});
