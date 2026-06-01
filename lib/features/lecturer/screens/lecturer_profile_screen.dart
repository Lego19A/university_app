// ============================================================
// LECTURER PROFILE SCREEN - Lecturer profile details management.
//
// Layout mirrors the existing ProfileScreen exactly:
//   1. OrangeHeader         → Title "Profile"
//   2. CircleAvatar         → Lecturer photo placeholder
//   3. Name + ID text       → Lecturer name and staff ID
//   4. Profile detail card  → Labeled rows (same _buildProfileCard pattern)
//
// Design: Pixel-perfect match to the student ProfileScreen in
// profile_screen.dart — same card, same row layout, same spacing.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/orange_header.dart';
import '../../../core/repositories/user_repository.dart';

// ConsumerWidget: profile data is fetched from Firestore via Riverpod
class LecturerProfileScreen extends ConsumerWidget {
  const LecturerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Column(
      children: [
        // ---- SECTION 1: Orange header (same OrangeHeader widget) ----
        const OrangeHeader(title: 'Profile'),

        // ---- SECTION 2: Scrollable profile content ----
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
                  // Circular avatar matching the student ProfileScreen layout.
                  // Replace Icon with NetworkImage when a real photo is available.
                  CircleAvatar(
                    radius: AppConstants.avatarRadius, // 50dp, same as student profile
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      size: 60, // Large icon to fill the 100dp diameter circle
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMD),

                  // ---- Lecturer full name ----
                  Text(
                    user?.full_name ?? 'Lecturer',
                    style: AppTypography.header2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // ---- Staff ID ----
                  Text(
                    user?.university_id ?? '',
                    style: AppTypography.bodySmall,
                  ),

                  const SizedBox(height: AppConstants.spacingLG),

                  // ---- Profile detail card ----
                  // Uses the same _buildProfileCard helper that ProfileScreen uses.
                  // Each _ProfileRow shows a label on the left and a value on the right.
                  _buildProfileCard([
                    _ProfileRow(label: 'Full Name', value: user?.full_name ?? ''),
                    _ProfileRow(label: 'Staff ID', value: user?.university_id ?? ''),
                    _ProfileRow(label: 'Email', value: user?.email ?? ''),
                    _ProfileRow(label: 'Department', value: user?.department ?? ''),
                    _ProfileRow(label: 'Faculty', value: user?.faculty ?? ''),
                    _ProfileRow(label: 'Specialization', value: user?.specialization ?? ''),
                    _ProfileRow(label: 'Office', value: user?.office ?? ''),
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
  // _buildProfileCard - Identical implementation to ProfileScreen.
  // Wraps a list of labeled rows in a white card with shadow.
  // ============================================================
  Widget _buildProfileCard(List<_ProfileRow> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius), // 16dp
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
              // -- Individual label:value row --
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // -- Label on the left (secondary muted color) --
                    Text(
                      row.label,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // -- Value on the right (bold primary color) --
                    Flexible(
                      child: Text(
                        row.value,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // -- Divider between rows (excluded after the last row) --
              if (index < rows.length - 1) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// _ProfileRow - Simple data class for a label-value pair.
// Identical to the one in ProfileScreen; kept private here
// to avoid an extra shared file for such a minimal model.
// ============================================================
class _ProfileRow {
  final String label; // e.g. "Full Name"
  final String value; // e.g. "Dr. Ahmad Bin Hassan"

  _ProfileRow({required this.label, required this.value});
}
