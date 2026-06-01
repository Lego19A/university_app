// ============================================================
// STUDENT NOTIFICATIONS SCREEN - Displays announcements from
// lecturers for subjects the student is enrolled in.
//
// Layout (mirrors existing screen structure):
//   1. OrangeHeader       → Title "Notifications"
//   2. Announcement list  → Cards with subject badge, title,
//                           message, timestamp, lecturer name
//
// Data: Real-time stream from Firestore 'announcements' collection,
// filtered by the student's enrolled subject codes.
//
// State: Uses studentAnnouncementsStreamProvider from announcement_provider
//        and enrolledCodesListProvider from enrolment_provider.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/orange_header.dart';
import '../../announcements/providers/announcement_provider.dart';
import '../../announcements/models/announcement_model.dart';
import '../../enrolment/providers/enrolment_provider.dart';

// ============================================================
// StudentNotificationsScreen - ConsumerWidget that watches the
// student's enrolled subjects and queries matching announcements.
// ============================================================
class StudentNotificationsScreen extends ConsumerWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // -- Get enrolled subject codes from the enrolment provider --
    // enrolledCodesListProvider returns List<String> of subject codes
    // e.g. ['SE301', 'CS201', 'IT401']
    final subjectCodes = ref.watch(enrolledCodesListProvider);

    // -- Watch the announcements stream filtered by enrolled subjects --
    final announcementsAsync =
        ref.watch(studentAnnouncementsStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          // ---- Orange header ----
          const OrangeHeader(title: 'Notifications'),

          // ---- Announcement list ----
          Expanded(
            child: announcementsAsync.when(
              data: (announcements) {
                if (announcements.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.all(AppConstants.pagePadding),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    return _NotificationCard(
                      announcement: announcements[index],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingXL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error.withOpacity(0.6),
                      ),
                      const SizedBox(height: AppConstants.spacingMD),
                      Text(
                        'Unable to load notifications',
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _buildEmptyState - Shown when no announcements match.
  // ============================================================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: AppConstants.spacingMD),
            Text(
              'No notifications yet',
              style: AppTypography.header3
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppConstants.spacingSM),
            Text(
              'Announcements from your lecturers\nwill appear here',
              style: AppTypography.body
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// _NotificationCard - Individual announcement card for the
// student's notification list.
// ============================================================
class _NotificationCard extends StatelessWidget {
  final AnnouncementModel announcement;

  const _NotificationCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMD),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Top row: Subject badge + timestamp --
          Row(
            children: [
              // -- Subject code badge --
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  announcement.displayCode,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSM),
              // -- Subject name --
              Expanded(
                child: Text(
                  announcement.subjectName,
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // -- Timestamp --
              Text(
                _formatTimeAgo(announcement.createdAt),
                style: AppTypography.caption,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingSM),

          // -- Announcement title --
          Text(
            announcement.title,
            style: AppTypography.header3,
          ),

          const SizedBox(height: AppConstants.spacingXS),

          // -- Announcement message body --
          Text(
            announcement.message,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppConstants.spacingSM),

          // -- Lecturer name row --
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: AppConstants.iconSizeSM,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppConstants.spacingXS),
              Text(
                announcement.lecturerName,
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _formatTimeAgo - Shows relative time (e.g. "2h ago", "3d ago")
  // for recent items, or a date for older items.
  // ============================================================
  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    // -- For older announcements, show the full date --
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
