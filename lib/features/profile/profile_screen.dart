// ============================================================
// PROFILE SCREEN - Student profile view.
// This screen from the Figma design shows:
//   1. Circular profile avatar at the top
//   2. Student name and ID
//   3. Detailed profile parameters in labeled rows
//
// To connect to real data, replace the hardcoded values
// with data from your Firebase user object or backend API.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/orange_header.dart';
import '../../core/repositories/user_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Column(
      children: [
        // ---- Orange header ----
        const OrangeHeader(title: 'Profile'),

        // ---- Profile content ----
        Expanded(
          child: userAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (user) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                children: [
                  const SizedBox(height: AppConstants.spacingMD),

                  // ---- Profile avatar ----
                  // Circular avatar with the student's profile picture
                  // Replace the Icon with a NetworkImage or FileImage
                  CircleAvatar(
                    radius: AppConstants.avatarRadius,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMD),

                  // ---- Student name ----
                  Text(
                    user?.full_name ?? 'Student',
                    style: AppTypography.header2,
                  ),
                  const SizedBox(height: 4),

                  // ---- Student ID ----
                  Text(
                    user?.university_id ?? '',
                    style: AppTypography.bodySmall,
                  ),

                  const SizedBox(height: AppConstants.spacingLG),

                  // ---- Profile detail rows ----
                  // Each row shows a labeled piece of profile information
                  // Modify or add rows to match your Figma exactly
                  _buildProfileCard([
                    _ProfileRow(label: 'Full Name', value: user?.full_name ?? ''),
                    _ProfileRow(label: 'Student ID', value: user?.university_id ?? ''),
                    _ProfileRow(label: 'Email', value: user?.email ?? ''),
                    _ProfileRow(label: 'Programme', value: user?.programme ?? ''),
                    _ProfileRow(label: 'Faculty', value: user?.faculty ?? ''),
                    _ProfileRow(label: 'Intake', value: user?.intake ?? ''),
                    _ProfileRow(label: 'CGPA', value: user?.cgpa ?? ''),
                    _ProfileRow(label: 'Status', value: user?.status ?? ''),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // _buildProfileCard - Wraps profile rows in a styled card.
  // Each row inside the card shows a label: value pair.
  // ============================================================
  Widget _buildProfileCard(List<_ProfileRow> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingMD),
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
        children: rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return Column(
            children: [
              // -- Individual row with label and value --
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // -- Label on the left --
                    Text(
                      row.label,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // -- Value on the right --
                    Text(
                      row.value,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // -- Divider between rows (not after the last one) --
              if (index < rows.length - 1)
                const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// _ProfileRow - Simple data class for a label-value pair.
// ============================================================
class _ProfileRow {
  final String label;
  final String value;

  _ProfileRow({required this.label, required this.value});
}
