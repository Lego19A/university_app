// ============================================================
// ANNOUNCEMENTS SCREEN - Student announcements feed.
// Displays a scrollable list of announcements posted by
// lecturers for the subjects the student is enrolled in.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/orange_header.dart';
import '../enrolment/providers/enrolment_provider.dart';
import '../announcements/providers/announcement_provider.dart';
import '../announcements/models/announcement_model.dart';
import 'package:intl/intl.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get the list of enrolled subject codes
    final enrolledCodes = ref.watch(enrolledCodesListProvider);

    return Scaffold(
      body: Column(
        children: [
          // ---- Orange header ----
          const OrangeHeader(title: 'Announcements'),
            
          // ---- Announcements feed ----
          Expanded(
            child: enrolledCodes.isEmpty
                ? _buildEmptyState('You are not enrolled in any subjects yet.')
                : _buildAnnouncementsFeed(ref, enrolledCodes),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsFeed(WidgetRef ref, List<String> enrolledCodes) {
    // -- Watch real-time announcements from Firestore --
    final announcementsAsync = ref.watch(studentAnnouncementsStreamProvider);

    return announcementsAsync.when(
      data: (announcements) {
        if (announcements.isEmpty) {
          return _buildEmptyState('No announcements found for your subjects.');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            return _AnnouncementCard(announcement: announcement);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) => _buildEmptyState('Error loading announcements: $error'),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Text(
          message,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ============================================================
// _AnnouncementCard - Individual announcement item card.
// ============================================================
class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(announcement.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMD, left: 4, right: 4),
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
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Subject Code & Date Row --
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          announcement.displayCode,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          announcement.subjectName,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formattedDate,
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSM),

            // -- Title --
            Text(
              announcement.title,
              style: AppTypography.header3,
            ),
            const SizedBox(height: AppConstants.spacingXS),

            // -- Message --
            Text(
              announcement.message,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppConstants.spacingSM),

            // -- Lecturer Name --
            Text(
              'Posted by: ${announcement.lecturerName}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
