// ============================================================
// QR SCAN SCREEN - Camera interface for scanning QR codes.
// This is the dark camera view from the Figma design with a
// white scanning frame in the center. When a QR code is scanned,
// it validates the data and shows the Session Update confirmation
// bottom sheet.
//
// Integrates:
//   - mobile_scanner for camera QR scanning
//   - AttendanceTrackingNotifier for full validation pipeline:
//       1. Enrollment check  → QR subjectCode must be enrolled
//       2. Session type check → valid type + subject has lab
//       3. Expiry check      → QR not past its timestamp
//       4. Duplicate check   → sessionId not already marked
//   - Confirmation bottom sheet before marking attendance
//
// The camera pauses when a QR is detected (to avoid multiple
// triggers) and resumes if the user dismisses the sheet.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/primary_button.dart';
import 'models/qr_session_model.dart';
import 'providers/attendance_tracking_provider.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  // -- Scanner controller for start/stop/lifecycle --
  late MobileScannerController _scannerController;

  // -- Prevents multiple scans from firing simultaneously --
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // -- Black background to simulate camera view --
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Top bar with back button and title ----
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMD),
              child: Row(
                children: [
                  // -- Back button to return to previous screen --
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppConstants.spacingSM),
                  // -- Screen title --
                  Text(
                    'Scan QR Code',
                    style: AppTypography.header1,
                  ),
                ],
              ),
            ),

            // ---- Camera viewfinder area ----
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // -- Scanning frame: white bordered square --
                    // Contains the mobile_scanner camera feed
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        // -- White border to simulate scanning frame --
                        border: Border.all(
                          color: AppColors.white,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: MobileScanner(
                          controller: _scannerController,
                          onDetect: _onQrDetected,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingLG),

                    // -- Instruction text below the scanner frame --
                    Text(
                      'Align QR code within the frame',
                      style: AppTypography.body.copyWith(
                        color: AppColors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Bottom section: Manual entry button ----
            // Allows fallback when QR scanning doesn't work
            
          ],
        ),
      ),
    );
  }

  // ============================================================
  // _onQrDetected - Called by MobileScanner when a barcode is
  // detected. Pauses the camera, processes the raw data through
  // the AttendanceTrackingNotifier validation pipeline, then
  // shows the appropriate UI (confirmation sheet or error dialog).
  // ============================================================
  void _onQrDetected(BarcodeCapture capture) {
    // -- Guard: prevent multiple simultaneous processing --
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    _isProcessing = true;

    // -- Pause scanning to avoid repeat detection --
    _scannerController.stop();

    final rawData = barcodes.first.rawValue!;
    _processRawData(rawData);
  }

  // ============================================================
  // _processRawData - Runs the raw string through the full
  // validation pipeline and routes to the correct UI response.
  // Shared by camera scan and manual entry.
  // ============================================================
  void _processRawData(String rawData) {
    final notifier = ref.read(attendanceTrackingProvider.notifier);
    final result = notifier.processScannedData(rawData);

    switch (result.outcome) {
      case ScanOutcome.success:
        // Valid → show confirmation bottom sheet
        _showSessionUpdate(context, result.session!);
        break;

      case ScanOutcome.notEnrolled:
        _showErrorDialog(
          context,
          'Not Enrolled',
          result.message,
          Icons.block,
        );
        break;

      case ScanOutcome.invalidSession:
        _showErrorDialog(
          context,
          'Invalid Session',
          result.message,
          Icons.warning_amber_outlined,
        );
        break;

      case ScanOutcome.expired:
        _showErrorDialog(
          context,
          'QR Code Expired',
          result.message,
          Icons.timer_off,
        );
        break;

      case ScanOutcome.duplicate:
        _showErrorDialog(
          context,
          'Already Marked',
          result.message,
          Icons.check_circle_outline,
        );
        break;

      case ScanOutcome.invalidFormat:
        _showErrorDialog(
          context,
          'Invalid QR Code',
          result.message,
          Icons.error_outline,
        );
        break;
    }
  }

  // ============================================================
  // _resumeScanning - Resumes camera and resets processing flag.
  // Called when user dismisses the bottom sheet or error dialog.
  // ============================================================
  void _resumeScanning() {
    _isProcessing = false;
    _scannerController.start();
  }

  // ============================================================
  // _showSessionUpdate - Shows a bottom sheet confirming the
  // scanned session details before updating attendance.
  // This matches the "Session Update" screen in Figma.
  // ============================================================
  void _showSessionUpdate(BuildContext context, QrSessionModel session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -- Drag handle at the top of the bottom sheet --
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // -- Title --
              Text('Session Details', style: AppTypography.header2),
              const SizedBox(height: AppConstants.spacingMD),

              // -- Session info rows (populated from QR data) --
              _buildInfoRow('Subject', session.subjectName),
              _buildInfoRow('Code', session.displayCode),
              _buildInfoRow('Type', session.typeLabel),
              _buildInfoRow('Date', session.date),
              _buildInfoRow('Time', session.time),

              const SizedBox(height: AppConstants.spacingLG),

              // -- Update Attendance button --
              PrimaryButton(
                label: 'Update Attendance',
                onPressed: () {
                  _confirmAttendance(sheetContext, session);
                },
              ),
              const SizedBox(height: AppConstants.spacingSM),
            ],
          ),
        );
      },
    ).then((_) {
      // -- Resume camera if user swipes down without confirming --
      _resumeScanning();
    });
  }

  // ============================================================
  // _confirmAttendance - Called when user taps "Update Attendance".
  // Delegates to AttendanceTrackingNotifier which increments the
  // correct (subjectCode, sessionType) percentage by 10%.
  // ============================================================
  void _confirmAttendance(BuildContext sheetContext, QrSessionModel session) async {
    final notifier = ref.read(attendanceTrackingProvider.notifier);
    final success = await notifier.confirmAttendance(session);

    // -- Close the bottom sheet --
    Navigator.of(sheetContext).pop();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance updated for ${session.subjectName} (${session.sessionType})!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update attendance. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    // -- Resume scanning for the next QR --
    _resumeScanning();
  }

  // ============================================================
  // _showErrorDialog - Displays a styled error dialog for
  // invalid, expired, not-enrolled, or duplicate QR codes.
  // ============================================================
  void _showErrorDialog(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
          title: Row(
            children: [
              Icon(icon, color: AppColors.error, size: 24),
              const SizedBox(width: 8),
              Flexible(child: Text(title, style: AppTypography.header3)),
            ],
          ),
          content: Text(message, style: AppTypography.body),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Try Again',
                style: AppTypography.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      // -- Resume scanning when dialog closed --
      _resumeScanning();
    });
  }

  // ============================================================
  // _showManualEntryDialog - Shows a dialog for manual QR code
  // entry as a fallback when camera scanning doesn't work.
  // Runs through the exact same validation pipeline.
  // ============================================================
  void _showManualEntryDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
          title: Text('Enter Session Code', style: AppTypography.header3),
          content: TextField(
            controller: textController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Paste the QR code data here...',
              hintStyle: AppTypography.bodySmall,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final rawData = textController.text.trim();
                if (rawData.isNotEmpty) {
                  // -- Process manual entry through the same pipeline --
                  _scannerController.stop();
                  _isProcessing = true;
                  _processRawData(rawData);
                }
              },
              child: Text(
                'Submit',
                style: AppTypography.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // -- Helper: Builds a row with label and value --
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.body
                  .copyWith(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
