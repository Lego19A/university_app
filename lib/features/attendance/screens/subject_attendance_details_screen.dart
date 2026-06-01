import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/orange_header.dart';
import '../providers/attendance_tracking_provider.dart';

class SubjectAttendanceDetailsScreen extends StatelessWidget {
  final SubjectAttendanceSummary summary;

  const SubjectAttendanceDetailsScreen({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ---- Orange header with screen title ----
          OrangeHeader(
            title: '${summary.code} Attendance',
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              children: [
                // -- Title / Overall Percentage --
                Text(
                  '${summary.name} (${summary.type})',
                  style: AppTypography.header2,
                ),
                const SizedBox(height: AppConstants.spacingSM),
                
                Row(
                  children: [
                    Text(
                      'Overall Attendance: ',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${summary.percentage}%',
                      style: AppTypography.body.copyWith(
                        color: summary.percentage < 80 ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingLG),
                
                // -- List of Weeks 1 to 5 --
                for (int week = 1; week <= kMaxWeeks; week++)
                  _buildWeekCard(week),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCard(int week) {
    final bool isPresent = summary.weeksPresent.contains(week);
    final Color statusColor = isPresent ? AppColors.success : AppColors.error;
    final String statusText = isPresent ? 'Present' : 'Absent';
    final IconData statusIcon = isPresent ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMD),
      padding: const EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: AppColors.textSecondary,
                size: AppConstants.iconSizeSM,
              ),
              const SizedBox(width: AppConstants.spacingSM),
              Text(
                'Week $week',
                style: AppTypography.header3,
              ),
            ],
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: AppConstants.iconSizeSM,
                ),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
