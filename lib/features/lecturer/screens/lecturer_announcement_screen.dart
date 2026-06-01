// ============================================================
// LECTURER ANNOUNCEMENT SCREEN - Compose and send announcements
// to students enrolled in a specific subject.
//
// Layout (mirrors existing screen structure):
//   1. OrangeHeader       → Title "Announcements"
//   2. Compose form card  → Subject dropdown, title, message fields
//   3. Send button        → Primary action button
//   4. History list       → Past announcements sent by this lecturer
//
// State: Managed by AnnouncementNotifier via announcementNotifierProvider.
// Data: Read/write from Firestore 'announcements' collection.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/orange_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/repositories/firestore_repository.dart';
import '../providers/lecturer_subjects_provider.dart';
import '../../announcements/providers/announcement_provider.dart';
import '../../announcements/models/announcement_model.dart';

// ============================================================
// LecturerAnnouncementScreen
// ============================================================
class LecturerAnnouncementScreen extends ConsumerStatefulWidget {
  const LecturerAnnouncementScreen({super.key});

  @override
  ConsumerState<LecturerAnnouncementScreen> createState() =>
      _LecturerAnnouncementScreenState();
}

class _LecturerAnnouncementScreenState
    extends ConsumerState<LecturerAnnouncementScreen> {
  // -- Form controllers --
  SubjectModel? _selectedSubject;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sendState = ref.watch(announcementNotifierProvider);
    final historyAsync = ref.watch(lecturerAnnouncementsStreamProvider);

    // -- Listen for successful send to clear the form --
    ref.listen<AnnouncementState>(announcementNotifierProvider,
        (previous, next) {
      if (previous?.lastSentAt != next.lastSentAt && next.lastSentAt != null) {
        // -- Send succeeded: clear the form fields --
        _titleController.clear();
        _messageController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement sent successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
      if (next.lastError != null && previous?.lastError != next.lastError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.lastError!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    });

    return Column(
      children: [
        // ---- SECTION 1: Orange header ----
        const OrangeHeader(title: 'Announcements'),

        // ---- SECTION 2: Scrollable body ----
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Compose Card ----
                _buildComposeCard(sendState),

                const SizedBox(height: AppConstants.spacingLG),

                // ---- Send Button ----
                PrimaryButton(
                  label: sendState.isSending ? 'Sending...' : 'Send Announcement',
                  onPressed: sendState.isSending ? null : _onSendTapped,
                ),

                const SizedBox(height: AppConstants.spacingXL),

                // ---- History Section ----
                Text('Sent Announcements', style: AppTypography.header2),
                const SizedBox(height: AppConstants.spacingMD),

                // -- History list from Firestore stream --
                historyAsync.when(
                  data: (announcements) {
                    if (announcements.isEmpty) {
                      return _buildEmptyState();
                    }
                    return Column(
                      children: announcements
                          .map((a) => _buildHistoryCard(a))
                          .toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'Failed to load history',
                      style: AppTypography.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // _buildComposeCard - Form for composing an announcement.
  // ============================================================
  Widget _buildComposeCard(AnnouncementState sendState) {
    return Container(
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
          // -- Section title --
          Text('New Announcement', style: AppTypography.header3),
          const SizedBox(height: AppConstants.spacingMD),

          // ---- Subject Dropdown ----
          Text('Subject', style: AppTypography.bodySmall),
          const SizedBox(height: AppConstants.spacingXS),
          ref.watch(lecturerSubjectsProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading subjects', style: AppTypography.body),
            data: (subjects) {
              // Auto-select the first subject if nothing is selected yet
              if (_selectedSubject == null && subjects.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedSubject == null) {
                    setState(() => _selectedSubject = subjects.first);
                  }
                });
              }

              if (subjects.isEmpty) {
                return Text('No subjects assigned', style: AppTypography.body);
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius:
                      BorderRadius.circular(AppConstants.buttonRadius),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SubjectModel>(
                    value: _selectedSubject,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary),
                    items: subjects
                        .map(
                          (s) => DropdownMenuItem<SubjectModel>(
                            value: s,
                            child: Text(
                              '${s.code} - ${s.name}',
                              style: AppTypography.body,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedSubject = value);
                    },
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppConstants.spacingMD),

          // ---- Title Field ----
          Text('Title', style: AppTypography.bodySmall),
          const SizedBox(height: AppConstants.spacingXS),
          TextField(
            controller: _titleController,
            style: AppTypography.body,
            decoration: InputDecoration(
              hintText: 'e.g. Class cancelled tomorrow',
              hintStyle:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.buttonRadius),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.buttonRadius),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.buttonRadius),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacingMD),

          // ---- Message Field ----
          Text('Message', style: AppTypography.bodySmall),
          const SizedBox(height: AppConstants.spacingXS),
          TextField(
            controller: _messageController,
            style: AppTypography.body,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Type your announcement message here...',
              hintStyle:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.buttonRadius),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.buttonRadius),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.buttonRadius),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _buildHistoryCard - A single past announcement card.
  // ============================================================
  Widget _buildHistoryCard(AnnouncementModel announcement) {
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
          // -- Subject badge + timestamp row --
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
              const Spacer(),
              // -- Timestamp --
              Text(
                _formatDate(announcement.createdAt),
                style: AppTypography.caption,
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

          // -- Message body --
          Text(
            announcement.message,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _buildEmptyState - Shown when no announcements have been sent.
  // ============================================================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXL),
        child: Column(
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: AppConstants.spacingMD),
            Text(
              'No announcements sent yet',
              style: AppTypography.body
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // _formatDate - Formats a DateTime to "29 Apr 2026, 10:30".
  // ============================================================
  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute';
  }

  // ============================================================
  // _onSendTapped - Validates and sends the announcement.
  // ============================================================
  void _onSendTapped() {
    if (_selectedSubject == null) return;
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    // -- Validate required fields --
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // -- Send via the Riverpod notifier --
    ref.read(announcementNotifierProvider.notifier).sendAnnouncement(
          subjectCode: _selectedSubject!.code,
          displayCode: _selectedSubject!.code,
          subjectName: _selectedSubject!.name,
          title: title,
          message: message,
        );
  }
}
