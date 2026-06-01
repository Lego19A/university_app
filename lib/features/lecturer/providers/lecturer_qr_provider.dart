// ============================================================
// LECTURER QR PROVIDER - Riverpod state management for the
// QR Code Session Generation feature.
//
// Architecture (mirrors the existing attendance_tracking_provider.dart):
//   - LecturerQrState      : Immutable state snapshot
//   - LecturerQrNotifier   : Mutates state via named methods
//   - lecturerQrProvider   : StateNotifierProvider exposed to UI
//
// Responsibilities:
//   1. Hold the currently generated session (or null if none)
//   2. Track the active countdown timer
//   3. Expose a "generate" method called by the QR screen
//   4. Expose a "clearSession" method to reset the QR display
// ============================================================

import 'dart:async'; // Needed for Timer (countdown tick)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lecturer_session_model.dart';

// ============================================================
// LecturerQrState - Immutable snapshot of the QR generation UI.
//
// Fields:
//   - activeSession    : The currently displayed session, or null
//   - remainingSeconds : Countdown value shown in the UI timer
//   - isExpired        : True when the countdown hits 0
// ============================================================
class LecturerQrState {
  // -- The session currently displayed as a QR code (null = no QR shown) --
  final LecturerSessionModel? activeSession;

  // -- Countdown seconds displayed in the "Expires in X seconds" label --
  final int remainingSeconds;

  // -- True once remainingSeconds reaches 0; triggers the expired UI state --
  final bool isExpired;

  const LecturerQrState({
    this.activeSession,
    this.remainingSeconds = 0,
    this.isExpired = false,
  });

  // -- copyWith: Creates a new state with only the specified fields changed --
  // This keeps state immutable (following Riverpod best practices).
  LecturerQrState copyWith({
    LecturerSessionModel? activeSession,
    int? remainingSeconds,
    bool? isExpired,
    bool clearSession = false, // Special flag to null out the session
  }) {
    return LecturerQrState(
      // -- If clearSession is true, set to null; otherwise use new or old value --
      activeSession: clearSession ? null : activeSession ?? this.activeSession,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}

// ============================================================
// LecturerQrNotifier - Manages state mutations and the countdown
// timer for the QR generation feature.
// ============================================================
class LecturerQrNotifier extends StateNotifier<LecturerQrState> {
  // -- Internal timer reference; kept so we can cancel it on re-generate --
  Timer? _countdownTimer;

  // -- Initialize with no active session --
  LecturerQrNotifier() : super(const LecturerQrState());

  // ============================================================
  // generateSession - Creates a new session QR code.
  // Cancels any existing countdown, generates a fresh session,
  // and starts a new per-second countdown timer.
  //
  // Parameters:
  //   subjectCode     : Code of the selected subject
  //   subjectName     : Display name of the selected subject
  //   sessionType     : "LEC" or "LAB"
  //   durationMinutes : How long (in minutes) the QR is valid
  // ============================================================
  void generateSession({
    required String subjectCode,
    required String displayCode,
    required String subjectName,
    required String sessionType,
    required int week,
    required int durationMinutes,
  }) {
    // -- Cancel any existing countdown before starting a new one --
    _countdownTimer?.cancel();

    // -- Generate the new session model using the factory constructor --
    final session = LecturerSessionModel.generate(
      subjectCode: subjectCode,
      displayCode: displayCode,
      subjectName: subjectName,
      sessionType: sessionType,
      week: week,
      durationMinutes: durationMinutes,
    );

    // -- Set the initial state with the new session and remaining time --
    state = LecturerQrState(
      activeSession: session,
      remainingSeconds: session.remainingSeconds, // e.g. 300 for 5 minutes
      isExpired: false,
    );

    // -- Start a 1-second periodic timer to decrement the countdown --
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1), // Fires every second
      (_) => _tick(), // Update state on each tick
    );
  }

  // ============================================================
  // _tick - Called every second by the countdown timer.
  // Decrements remainingSeconds and marks as expired when done.
  // ============================================================
  void _tick() {
    // -- Guard: if no session or already expired, stop the timer --
    if (state.activeSession == null || state.isExpired) {
      _countdownTimer?.cancel();
      return;
    }

    // -- Get fresh remaining seconds directly from the model (clock-accurate) --
    final remaining = state.activeSession!.remainingSeconds;

    if (remaining <= 0) {
      // -- Session has expired: update state and stop the timer --
      state = state.copyWith(remainingSeconds: 0, isExpired: true);
      _countdownTimer?.cancel();
    } else {
      // -- Still valid: decrement the counter by 1 second --
      state = state.copyWith(remainingSeconds: remaining);
    }
  }

  // ============================================================
  // clearSession - Resets the QR screen to its initial empty state.
  // Called when the lecturer taps "Clear" or navigates away.
  // ============================================================
  void clearSession() {
    // -- Cancel any running countdown first --
    _countdownTimer?.cancel();

    // -- Reset state to the initial empty state --
    state = const LecturerQrState();
  }

  // ============================================================
  // dispose - Called by Riverpod when this notifier is removed.
  // Always cancel timers in dispose to prevent memory leaks.
  // ============================================================
  @override
  void dispose() {
    _countdownTimer?.cancel(); // Prevent timer callbacks after disposal
    super.dispose();
  }
}

// ============================================================
// PROVIDERS - Exposed to the UI layer via ref.watch / ref.read
// ============================================================

// -- Main provider: access state and call notifier methods --
// Usage: ref.watch(lecturerQrProvider) → LecturerQrState
// Usage: ref.read(lecturerQrProvider.notifier).generateSession(...)
final lecturerQrProvider =
    StateNotifierProvider<LecturerQrNotifier, LecturerQrState>(
  (ref) => LecturerQrNotifier(),
);
