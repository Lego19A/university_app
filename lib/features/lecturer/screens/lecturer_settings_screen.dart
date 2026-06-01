// ============================================================
// LECTURER SETTINGS SCREEN - Basic system/user configurations.
//
// This screen provides the lecturer with essential toggles:
//   1. Notifications toggle (on/off)
//   2. Dark Mode toggle (on/off placeholder)
//   3. Default QR Duration selector
//   4. Logout action (with confirmation dialog)
//
// Layout mirrors the existing MenuScreen card/list pattern:
//   - OrangeHeader                   → Title "Settings"
//   - Settings list inside a card    → Toggle rows with dividers
//   - Logout button at the bottom    → Destructive action (red)
//
// State: Managed by LecturerSettingsNotifier via lecturerSettingsProvider.
// ============================================================

import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod state management

import '../../../core/theme/app_colors.dart'; // Centralized color tokens
import '../../../core/theme/app_typography.dart'; // Centralized text styles
import '../../../core/constants/app_constants.dart'; // Spacing + sizing constants
import '../../../core/widgets/orange_header.dart'; // Reusable curved header widget
import '../../../core/widgets/primary_button.dart'; // Reusable action button widget
import '../../../core/utils/auth_utils.dart'; // Secure logout utility
import '../providers/lecturer_settings_provider.dart'; // Settings state notifier

// ============================================================
// LecturerSettingsScreen - ConsumerWidget for reactive Riverpod binding.
// Rebuilds automatically when any setting value changes.
// ============================================================
class LecturerSettingsScreen extends ConsumerWidget {
  const LecturerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // -- Watch the current settings state snapshot --
    // Any mutation via the notifier triggers a rebuild here.
    final settings = ref.watch(lecturerSettingsProvider);

    return Column(
      children: [
        // ---- SECTION 1: Orange header with title ----
        const OrangeHeader(title: 'Settings'),

        // ---- SECTION 2: Scrollable settings body ----
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: Column(
              children: [
                // ---- Settings Card (matches existing card style) ----
                _buildSettingsCard(context, ref, settings),

                const SizedBox(height: AppConstants.spacingLG),

                // ---- Logout Button ----
                // Full-width destructive action button.
                // Uses the existing PrimaryButton widget in outlined style.
                PrimaryButton(
                  label: 'Logout', // Text on the button
                  isOutlined: true, // Outlined style for destructive action
                  onPressed: () => _showLogoutDialog(context, ref), // Open dialog
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // _buildSettingsCard - Card containing all setting rows.
  // Uses the same Container + BoxDecoration pattern as the
  // profile card and attendance card throughout the app.
  // ============================================================
  Widget _buildSettingsCard(
    BuildContext context,
    WidgetRef ref,
    LecturerSettingsState settings,
  ) {
    return Container(
      width: double.infinity, // Full width of parent
      padding: const EdgeInsets.all(AppConstants.spacingMD), // 16dp inner padding
      decoration: BoxDecoration(
        color: AppColors.surface, // White card background
        borderRadius: BorderRadius.circular(AppConstants.cardRadius), // 16dp radius
        // -- Standard card shadow matching all other cards in the app --
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow, // 10% black shadow color
            blurRadius: 8, // Soft shadow spread
            offset: const Offset(0, 2), // Shadow falls 2dp downward
          ),
        ],
      ),
      child: Column(
        children: [
          // ---- Row 1: Notifications Toggle ----
          _buildToggleRow(
            icon: Icons.notifications_outlined, // Bell icon
            label: 'Notifications', // Setting name
            value: settings.notificationsEnabled, // Current toggle state
            onChanged: (value) {
              // -- Delegate toggle to the Riverpod notifier --
              ref.read(lecturerSettingsProvider.notifier).toggleNotifications();
            },
          ),

          // -- Divider between rows (consistent with ProfileScreen pattern) --
          const Divider(height: 1),

          // ---- Row 2: Default QR Duration ----
          _buildDurationRow(
            context: context,
            currentDuration: settings.defaultQrDurationMinutes, // e.g. 15
            onChanged: (minutes) {
              // -- Save the selected duration in the provider --
              ref
                  .read(lecturerSettingsProvider.notifier)
                  .setDefaultQrDuration(minutes);
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _buildToggleRow - A single setting row with icon, label, and
  // a trailing Switch toggle. Matches the list-tile visual pattern
  // used in the existing MenuScreen and ProfileScreen.
  // ============================================================
  Widget _buildToggleRow({
    required IconData icon, // Leading icon
    required String label, // Setting name text
    required bool value, // Current on/off state
    required ValueChanged<bool> onChanged, // Toggle callback
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12), // Row vertical padding
      child: Row(
        children: [
          // -- Leading icon with light-tinted circular background --
          // Matches the ActionCard and MenuScreen icon container style.
          Container(
            padding: const EdgeInsets.all(8), // Icon inner padding
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1), // Light brand tint
              shape: BoxShape.circle, // Circular container
            ),
            child: Icon(
              icon, // e.g. Icons.notifications_outlined
              size: AppConstants.iconSizeMD, // 24dp standard icon size
              color: AppColors.primary, // Brand color for icon
            ),
          ),

          const SizedBox(width: AppConstants.spacingMD), // 16dp gap

          // -- Setting label text (fills remaining space) --
          Expanded(
            child: Text(
              label, // e.g. "Notifications"
              style: AppTypography.body, // 14dp Inter Regular
            ),
          ),

          // -- Trailing toggle switch --
          // Uses activeColor matching the primary brand to stay on-brand.
          Switch(
            value: value, // Current on/off state
            onChanged: onChanged, // Toggle callback
            activeThumbColor: AppColors.primary, // Brand color when ON
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _buildDurationRow - Setting row with icon, label, and a
  // trailing dropdown for selecting the default QR duration.
  // ============================================================
  Widget _buildDurationRow({
    required BuildContext context,
    required int currentDuration, // Current value in minutes
    required ValueChanged<int> onChanged, // Callback with new value
  }) {
    // -- Available duration options in minutes --
    const durations = [5, 10, 15, 30, 45, 60];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12), // Row vertical padding
      child: Row(
        children: [
          // -- Leading icon with light-tinted background --
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1), // Light brand tint
              shape: BoxShape.circle, // Circular container
            ),
            child: const Icon(
              Icons.timer_outlined, // Clock icon for duration
              size: AppConstants.iconSizeMD, // 24dp
              color: AppColors.primary, // Brand color
            ),
          ),

          const SizedBox(width: AppConstants.spacingMD), // 16dp gap

          // -- Label text --
          Expanded(
            child: Text(
              'Default QR Duration', // Setting name
              style: AppTypography.body, // 14dp Inter Regular
            ),
          ),

          // -- Trailing compact dropdown --
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider), // Subtle border
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius), // 12dp
            ),
            child: DropdownButtonHideUnderline(
              // -- Hide default underline; container provides the border --
              child: DropdownButton<int>(
                value: currentDuration, // Currently selected value
                // -- Build menu items from the durations list --
                items: durations
                    .map(
                      (d) => DropdownMenuItem<int>(
                        value: d,
                        child: Text(
                          '$d min', // e.g. "15 min"
                          style: AppTypography.bodySmall, // 12dp compact text
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onChanged(value); // Propagate selection
                },
                icon: const Icon(
                  Icons.keyboard_arrow_down, // Custom caret icon
                  size: AppConstants.iconSizeSM, // 20dp small icon
                  color: AppColors.textSecondary, // Grey caret color
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _showLogoutDialog - Two-step confirmation before signing out.
  // Identical pattern to the existing MenuScreen._showLogoutDialog.
  // On confirm: signs out from Firebase and navigates to LoginPage.
  // ============================================================
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          // -- Rounded dialog shape matching the existing logout dialog --
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners
          ),
          // -- Dialog title --
          title: Text('Logout', style: AppTypography.header2),
          // -- Confirmation message --
          content: Text(
            'Are you sure you want to logout?',
            style: AppTypography.body,
          ),
          actions: [
            // -- Cancel button: dismisses the dialog --
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(), // Close dialog
              child: Text('Cancel', style: AppTypography.body),
            ),
            // -- Logout button: signs out and navigates to login --
            TextButton(
              onPressed: () async {
                // -- Close the dialog first --
                Navigator.of(dialogContext).pop();

                // -- Secure logout: wipe all state + sign out --
                if (context.mounted) {
                  await AuthUtils.performLogout(context, ref);
                }
              },
              child: Text(
                'Logout', // Destructive action label
                style: AppTypography.body.copyWith(
                  color: AppColors.error, // Red color to indicate danger
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
