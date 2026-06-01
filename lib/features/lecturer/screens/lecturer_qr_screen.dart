// ============================================================
// LECTURER QR SCREEN - QR Code Session Generation feature.
//
// This is the HOME tab of the Lecturer Interface. It allows the
// lecturer to select a subject, session type, and duration, then
// generate a QR code that students scan to mark attendance.
//
// Layout (mirrors existing screen structure):
//   1. OrangeHeader  → Title "Generate QR"
//   2. Session form  → Subject / Session Type / Duration dropdowns
//   3. Generate button → Primary action button
//   4. QR display   → Large QR image + countdown timer
//   5. Clear button  → Resets the QR state
//
// State: Managed by LecturerQrNotifier via lecturerQrProvider.
// Package: qr_flutter for QR code image rendering.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Renders the QR code image

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/orange_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/repositories/firestore_repository.dart';
import '../providers/lecturer_qr_provider.dart';
import '../providers/lecturer_subjects_provider.dart';


// ============================================================
// LecturerQrScreen - Main widget (ConsumerStatefulWidget because
// it owns local form state AND watches Riverpod state).
// ============================================================
class LecturerQrScreen extends ConsumerStatefulWidget {
  const LecturerQrScreen({super.key});

  @override
  ConsumerState<LecturerQrScreen> createState() => _LecturerQrScreenState();
}

class _LecturerQrScreenState extends ConsumerState<LecturerQrScreen> {
  // -- Available QR validity durations (in minutes) --
  final List<int> _durations = const [1, 2, 3, 4, 5, 6];

  // -- Selected form values (local UI state, not in Riverpod) --
  SubjectModel? _selectedSubject;           // Currently selected subject
  String _selectedSessionType = 'LEC';  // Default to Lecture
  late int _selectedDuration;            // Duration in minutes
  int _selectedWeek = 1;                 // Week 1 to 5

  @override
  void initState() {
    super.initState();
    _selectedDuration = _durations[0]; // Default: 15 minutes
  }

  @override
  Widget build(BuildContext context) {
    // -- Watch the QR provider state for reactivity (rebuilds on change) --
    final qrState = ref.watch(lecturerQrProvider);

    return Column(
      children: [
        // ---- SECTION 1: Orange header ----
        const OrangeHeader(title: 'Generate QR'),

        // ---- SECTION 2: Scrollable body ----
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Session Configuration Card ----
                // Contains all the dropdowns for configuring the session
                _buildConfigCard(),

                const SizedBox(height: AppConstants.spacingLG),

                // ---- Generate Button ----
                PrimaryButton(
                  label: 'Generate QR Code',
                  onPressed: _onGenerateTapped, // Calls Riverpod notifier
                ),

                // ---- QR Code Display (only visible after generation) ----
                // Conditionally shown when an active session exists
                if (qrState.activeSession != null) ...[
                  const SizedBox(height: AppConstants.spacingLG),
                  _buildQrDisplay(qrState), // The QR image + timer widget
                  const SizedBox(height: AppConstants.spacingMD),

                  // -- Clear button resets the state back to the form --
                  PrimaryButton(
                    label: 'Clear / New Session',
                    isOutlined: true, // Secondary style matches existing pattern
                    onPressed: () {
                      // -- Delegate to the notifier to reset state --
                      ref.read(lecturerQrProvider.notifier).clearSession();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // _buildConfigCard - Renders the session configuration form.
  // Matches the existing card style (same shadow + radius tokens).
  // ============================================================
  Widget _buildConfigCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,                                  // White card background
        borderRadius: BorderRadius.circular(AppConstants.cardRadius), // 16dp radius
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,   // Subtle shadow from AppColors tokens
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Card section title --
          Text('Session Configuration', style: AppTypography.header3),
          const SizedBox(height: AppConstants.spacingMD),

          // ---- Subject Dropdown ----
          // Loaded from the lecturer's registered_subjects via the shared provider
          ref.watch(lecturerSubjectsProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading subjects', style: AppTypography.body),
            data: (subjects) {
              // Auto-select the first subject if nothing is selected yet
              if (_selectedSubject == null && subjects.isNotEmpty) {
                // Schedule the setState to avoid calling it during build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedSubject == null) {
                    setState(() => _selectedSubject = subjects.first);
                  }
                });
              }

              if (subjects.isEmpty) {
                return Text('No subjects assigned', style: AppTypography.body);
              }

              return _buildDropdownField<SubjectModel>(
                label: 'Subject',
                icon: Icons.book_outlined,
                value: _selectedSubject,
                // -- Map each subject to a DropdownMenuItem --
                items: subjects
                    .map(
                      (s) => DropdownMenuItem<SubjectModel>(
                        value: s,
                        child: Text(
                          '${s.code} - ${s.name}', // "SE301 - Software Engineering"
                          style: AppTypography.body,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedSubject = value; // Update selected subject
                    // -- Reset session type if subject has no lab --
                    if (!value.requiresLab) _selectedSessionType = 'LEC';
                  });
                },
              );
            },
          ),

          const SizedBox(height: AppConstants.spacingMD),

          // ---- Session Type Selector (LEC / LAB) ----
          Text(
            'Session Type',
            style: AppTypography.bodySmall, // Same label style as form fields
          ),
          const SizedBox(height: AppConstants.spacingSM),
          Row(
            children: [
              // -- LEC option (always available) --
              _buildTypeChip(
                label: 'LEC',
                isSelected: _selectedSessionType == 'LEC',
                onTap: () => setState(() => _selectedSessionType = 'LEC'),
              ),
              const SizedBox(width: AppConstants.spacingSM),
              // -- LAB option (greyed out when subject has no lab) --
              _buildTypeChip(
                label: 'LAB',
                isSelected: _selectedSessionType == 'LAB',
                isDisabled: _selectedSubject == null || !_selectedSubject!.requiresLab, // Disabled if no lab
                onTap: _selectedSubject != null && _selectedSubject!.requiresLab
                    ? () => setState(() => _selectedSessionType = 'LAB')
                    : null,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMD),

          // ---- Duration Dropdown ----
          _buildDropdownField<int>(
            label: 'QR Valid Duration',
            icon: Icons.timer_outlined,
            value: _selectedDuration,
            items: _durations
                .map(
                  (d) => DropdownMenuItem<int>(
                    value: d,
                    child: Text(
                      '$d minutes', // e.g. "15 minutes"
                      style: AppTypography.body,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedDuration = value); // Update duration
            },
          ),
          
          const SizedBox(height: AppConstants.spacingMD),

          // ---- Week Dropdown ----
          _buildDropdownField<int>(
            label: 'Academic Week',
            icon: Icons.calendar_month_outlined,
            value: _selectedWeek,
            items: [1, 2, 3, 4, 5]
                .map(
                  (w) => DropdownMenuItem<int>(
                    value: w,
                    child: Text(
                      'Week $w',
                      style: AppTypography.body,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedWeek = value);
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _buildDropdownField - Generic reusable labeled dropdown.
  // Matches the existing text field visual style (border + icon).
  // ============================================================
  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -- Label above the dropdown --
        Text(label, style: AppTypography.bodySmall),
        const SizedBox(height: AppConstants.spacingXS),

        // -- Decorated dropdown container (matches app form field style) --
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider), // Subtle border
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          ),
          child: DropdownButtonHideUnderline(
            // -- Hide default underline; container provides the border --
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true, // Full width inside the container
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary), // Custom caret icon
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // _buildTypeChip - Tap-to-select chip for "LEC" / "LAB".
  // Selected state uses the primary brand color (AppColors.primary).
  // Disabled state is shown when the subject has no lab.
  // ============================================================
  Widget _buildTypeChip({
    required String label,
    required bool isSelected,
    bool isDisabled = false,
    VoidCallback? onTap,
  }) {
    // -- Determine background and text colors based on state --
    final bgColor = isDisabled
        ? AppColors.divider              // Greyed out when disabled
        : isSelected
            ? AppColors.primary          // Brand color when selected
            : AppColors.surface;         // White when unselected

    final textColor = isDisabled
        ? AppColors.textSecondary        // Grey text when disabled
        : isSelected
            ? AppColors.white            // White text when selected
            : AppColors.textPrimary;     // Dark text when unselected

    return GestureDetector(
      onTap: isDisabled ? null : onTap, // Block tap when disabled
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          // -- Show primary border when selected, grey when not --
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label, // "LEC" or "LAB"
          style: AppTypography.body.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // _buildQrDisplay - Shows the generated QR code, subject info,
  // and the live countdown timer. Appears after "Generate" is tapped.
  // ============================================================
  Widget _buildQrDisplay(LecturerQrState qrState) {
    final session = qrState.activeSession!; // Safe: checked before calling

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // -- Subject name and type badge row --
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // -- Subject code and name --
              Text(
                '${session.displayCode} · ${session.subjectName}',
                style: AppTypography.header3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: AppConstants.spacingSM),
              // -- Session type badge (e.g. "LEC") --
              _buildTypeBadge(session.sessionType),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMD),

          // -- QR Code image (or "Expired" overlay if time is up) --
          qrState.isExpired
              ? _buildExpiredOverlay() // Show expired state
              : QrImageView(
                  data: session.toQrString(), // JSON string embedded in QR
                  version: QrVersions.auto,   // Auto-pick the smallest QR size
                  size: kIsWeb ? 500.0 : 220.0, // Much larger on web for projection
                  backgroundColor: Colors.white, // White background for contrast
                ),

          const SizedBox(height: AppConstants.spacingMD),

          // -- Countdown timer row --
          if (!qrState.isExpired)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // -- Timer icon --
                const Icon(
                  Icons.timer_outlined,
                  size: AppConstants.iconSizeSM,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppConstants.spacingXS),
                // -- "Expires in X seconds" label --
                Text(
                  'Expires in ${_formatCountdown(qrState.remainingSeconds)}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),

          // -- "Expired" label when the QR is no longer valid --
          if (qrState.isExpired)
            Text(
              'This QR code has expired.',
              style: AppTypography.body.copyWith(color: AppColors.error),
            ),

          const SizedBox(height: AppConstants.spacingSM),

          // -- Session details row: date and time --
          Text(
            '${session.date}  ·  ${session.time}',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _buildTypeBadge - Small pill-shaped badge for "LEC" or "LAB".
  // Matches the same badge style used in AttendanceScreen.
  // ============================================================
  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1), // Light brand tint
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type, // "LEC" or "LAB"
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // _buildExpiredOverlay - Placeholder shown when QR has expired.
  // Same size as the QR image to prevent layout jump.
  // ============================================================
  Widget _buildExpiredOverlay() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.divider,                                   // Light grey background
        borderRadius: BorderRadius.circular(AppConstants.cardRadius), // Rounded box
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // -- Large error icon --
          Icon(
            Icons.qr_code_2,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5), // Faded icon
          ),
          const SizedBox(height: AppConstants.spacingSM),
          Text(
            'QR Expired',
            style: AppTypography.body.copyWith(color: AppColors.error),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _formatCountdown - Converts raw seconds to "MM:SS" string.
  // Example: 125 → "02:05"
  // ============================================================
  String _formatCountdown(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;       // Integer division for minutes
    final seconds = totalSeconds % 60;        // Remainder for seconds
    // -- Left-pad both to 2 digits for consistent MM:SS format --
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // _onGenerateTapped - Validates form and calls the notifier.
  // Called when the "Generate QR Code" button is pressed.
  // ============================================================
  void _onGenerateTapped() {
    if (_selectedSubject == null) return;
    // -- Call the Riverpod notifier to generate and start the timer --
    ref.read(lecturerQrProvider.notifier).generateSession(
          subjectCode: _selectedSubject!.code,
          displayCode: _selectedSubject!.code,
          subjectName: _selectedSubject!.name,
          sessionType: _selectedSessionType,
          week: _selectedWeek,
          durationMinutes: _selectedDuration,
        );
  }
}
