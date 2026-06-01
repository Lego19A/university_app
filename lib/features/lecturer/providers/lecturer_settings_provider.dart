// ============================================================
// LECTURER SETTINGS PROVIDER - Riverpod state management for
// the lecturer's Settings screen.
//
// Manages:
//   - Notification toggle (on/off)
//   - Default QR duration preference (in minutes)
//
// Architecture mirrors existing providers: StateNotifier + Provider.
// In production, persist settings to SharedPreferences or Firestore.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================
// LecturerSettingsState - Immutable snapshot of all settings.
// ============================================================
class LecturerSettingsState {
  // -- notificationsEnabled: Whether push notifications are active --
  final bool notificationsEnabled;

  // -- defaultQrDurationMinutes: Pre-filled value in the QR duration picker --
  // Lecturers can change this once and not have to re-select each time.
  final int defaultQrDurationMinutes;

  const LecturerSettingsState({
    this.notificationsEnabled = true,    // On by default
    this.defaultQrDurationMinutes = 15,  // 15 minutes is a sensible default
  });

  // -- copyWith: Update only the changed fields --
  LecturerSettingsState copyWith({
    bool? notificationsEnabled,
    int? defaultQrDurationMinutes,
  }) {
    return LecturerSettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultQrDurationMinutes:
          defaultQrDurationMinutes ?? this.defaultQrDurationMinutes,
    );
  }
}

// ============================================================
// LecturerSettingsNotifier - Handles settings state mutations.
// ============================================================
class LecturerSettingsNotifier
    extends StateNotifier<LecturerSettingsState> {
  // -- Initialize with sensible defaults --
  LecturerSettingsNotifier() : super(const LecturerSettingsState());

  // ============================================================
  // toggleNotifications - Flips the notifications toggle.
  // ============================================================
  void toggleNotifications() {
    // -- Flip the current boolean value --
    state = state.copyWith(
      notificationsEnabled: !state.notificationsEnabled,
    );
  }

  // ============================================================
  // setDefaultQrDuration - Updates the saved QR duration (minutes).
  // ============================================================
  void setDefaultQrDuration(int minutes) {
    // -- Clamp to a reasonable range: 1 min minimum, 120 min maximum --
    state = state.copyWith(
      defaultQrDurationMinutes: minutes.clamp(1, 120),
    );
  }
}

// ============================================================
// PROVIDER - Exposed to the Settings screen via ref.watch
// ============================================================
final lecturerSettingsProvider =
    StateNotifierProvider<LecturerSettingsNotifier, LecturerSettingsState>(
  (ref) => LecturerSettingsNotifier(),
);
