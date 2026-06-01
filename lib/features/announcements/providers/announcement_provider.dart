// ============================================================
// ANNOUNCEMENT PROVIDER - Riverpod state management for the
// Announcement feature (both lecturer and student sides).
//
// Architecture mirrors existing providers (StateNotifier + Provider):
//   - AnnouncementNotifier : Handles sending announcements (lecturer)
//   - lecturerAnnouncementsProvider : Stream of announcements by lecturer
//   - studentAnnouncementsProvider  : Stream of announcements filtered
//                                     by enrolled subject codes
//
// Firestore collection: 'announcements'
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/firestore_repository.dart';
import '../models/announcement_model.dart';

// ============================================================
// Firestore reference for the announcements collection
// ============================================================
final _announcementsRef =
    FirebaseFirestore.instance.collection('announcements');

// ============================================================
// AnnouncementState - Immutable snapshot of the compose form.
// ============================================================
class AnnouncementState {
  // -- isSending: True while Firestore write is in progress --
  final bool isSending;

  // -- lastError: Error message if the last send failed --
  final String? lastError;

  // -- lastSentAt: Timestamp of the most recent successful send --
  final DateTime? lastSentAt;

  const AnnouncementState({
    this.isSending = false,
    this.lastError,
    this.lastSentAt,
  });

  AnnouncementState copyWith({
    bool? isSending,
    String? lastError,
    DateTime? lastSentAt,
    bool clearError = false,
  }) {
    return AnnouncementState(
      isSending: isSending ?? this.isSending,
      lastError: clearError ? null : lastError ?? this.lastError,
      lastSentAt: lastSentAt ?? this.lastSentAt,
    );
  }
}

// ============================================================
// AnnouncementNotifier - Handles sending announcements to
// Firestore. Used by the lecturer compose screen.
// ============================================================
class AnnouncementNotifier extends StateNotifier<AnnouncementState> {
  AnnouncementNotifier() : super(const AnnouncementState());

  // ============================================================
  // sendAnnouncement - Writes a new announcement document to
  // Firestore. The student side picks it up via a stream.
  //
  // Parameters:
  //   subjectCode  : Code of the target subject
  //   subjectName  : Full name of the target subject
  //   title        : Announcement headline
  //   message      : Announcement body text
  // ============================================================
  Future<bool> sendAnnouncement({
    required String subjectCode,
    required String displayCode,
    required String subjectName,
    required String title,
    required String message,
  }) async {
    // -- Set loading state --
    state = state.copyWith(isSending: true, clearError: true);

    try {
      // -- Get the current lecturer's info from Firebase Auth --
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = state.copyWith(
          isSending: false,
          lastError: 'Not authenticated',
        );
        return false;
      }

      // -- Fetch the lecturer's display name from Firestore user doc --
      String lecturerName = user.displayName ?? 'Lecturer';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          lecturerName =
              (userDoc.data()!['full_name'] as String?) ?? lecturerName;
        }
      } catch (_) {
        // Fall back to displayName if Firestore lookup fails
      }

      // -- Create the announcement document --
      final announcement = AnnouncementModel(
        id: '', // Firestore auto-generates the ID
        lecturerId: user.uid,
        lecturerName: lecturerName,
        subjectCode: subjectCode,
        displayCode: displayCode,
        subjectName: subjectName,
        title: title,
        message: message,
        createdAt: DateTime.now(),
      );

      // -- Write to Firestore --
      await _announcementsRef.add(announcement.toJson());

      // -- Update state with success --
      state = state.copyWith(
        isSending: false,
        lastSentAt: DateTime.now(),
      );
      return true;
    } catch (e) {
      // -- Update state with error --
      state = state.copyWith(
        isSending: false,
        lastError: 'Failed to send: $e',
      );
      return false;
    }
  }
}

// ============================================================
// PROVIDERS
// ============================================================

// -- Lecturer compose state provider --
final announcementNotifierProvider =
    StateNotifierProvider<AnnouncementNotifier, AnnouncementState>(
  (ref) => AnnouncementNotifier(),
);

// -- Lecturer's own announcements stream (most recent first) --
// Shows history of announcements the current lecturer has sent.
final lecturerAnnouncementsStreamProvider =
    StreamProvider<List<AnnouncementModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return _announcementsRef
      .where('lecturerId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
});

// -- Student announcements stream provider --
// Fetches the student's enrolled subject codes from Firestore and returns
// matching announcements in reverse chronological order.
final studentAnnouncementsStreamProvider = StreamProvider<List<AnnouncementModel>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield [];
    return;
  }

  // 1. Fetch the student's actual enrolled subject codes from Firestore
  final firestoreRepo = ref.read(firestoreRepositoryProvider);
  final subjectCodes = await firestoreRepo.getEnrolledSubjectCodes(user.uid);

  if (subjectCodes.isEmpty) {
    yield [];
    return;
  }

  // 2. Stream the announcements for those subjects
  // Firestore 'whereIn' supports a max of 30 values per query.
  yield* _announcementsRef
      .where('subjectCode', whereIn: subjectCodes)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
});
