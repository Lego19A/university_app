import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/orange_header.dart';
import '../models/lecturer_attendance_record.dart';
import '../providers/lecturer_attendance_provider.dart';
import '../providers/lecturer_subjects_provider.dart';

class LecturerAttendanceScreen extends ConsumerStatefulWidget {
  const LecturerAttendanceScreen({super.key});

  @override
  ConsumerState<LecturerAttendanceScreen> createState() => _LecturerAttendanceScreenState();
}

class _LecturerAttendanceScreenState extends ConsumerState<LecturerAttendanceScreen> {


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lecturerAttendanceProvider);

    return Column(
      children: [
        const OrangeHeader(title: 'Attendance View'),
        
        Expanded(
          child: Column(
            children: [
              _buildSubjectSelector(state),
              
              if (state.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (state.selectedSubjectCode == null)
                _buildEmptyState('Select a subject to view enrolled students.')
              else if (state.students.isEmpty)
                _buildEmptyState('No students enrolled in this subject.')
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
                    itemCount: state.students.length,
                    itemBuilder: (context, index) {
                      return _StudentAttendanceCard(student: state.students[index]);
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectSelector(LecturerAttendanceState state) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.pagePadding),
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
          Text('Select Subject', style: AppTypography.bodySmall),
          const SizedBox(height: AppConstants.spacingSM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMD),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            ),
            child: DropdownButtonHideUnderline(
              child: ref.watch(lecturerSubjectsProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading subjects', style: AppTypography.body),
                data: (subjects) {
                  return DropdownButton<String>(
                    isExpanded: true,
                    value: state.selectedSubjectCode,
                    hint: Text('Choose a subject', style: AppTypography.body),
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Select Subject'),
                      ),
                      ...subjects.map(
                        (subject) => DropdownMenuItem<String>(
                          value: subject.code,
                          child: Text('${subject.code} - ${subject.name}', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      ref.read(lecturerAttendanceProvider.notifier).selectSubject(
                        value,
                        sessionType: state.selectedSessionType,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMD),
          Text('Session Type', style: AppTypography.bodySmall),
          const SizedBox(height: AppConstants.spacingSM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMD),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: state.selectedSessionType,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                items: const [
                  DropdownMenuItem(value: 'LEC', child: Text('Lecture (LEC)')),
                  DropdownMenuItem(value: 'LAB', child: Text('Lab (LAB)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(lecturerAttendanceProvider.notifier).selectSubject(
                      state.selectedSubjectCode,
                      sessionType: value,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: AppConstants.spacingMD),
              Text(
                'No Students',
                style: AppTypography.header2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingSM),
              Text(
                message,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentAttendanceCard extends ConsumerStatefulWidget {
  final LecturerStudentAttendance student;

  const _StudentAttendanceCard({required this.student});

  @override
  ConsumerState<_StudentAttendanceCard> createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends ConsumerState<_StudentAttendanceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final presentCount = widget.student.weekAttendance.values.where((v) => v).length;
    final percentage = (presentCount / 5 * 100).toInt();
    final bool isLow = percentage < 80;
    final Color barColor = isLow ? AppColors.error : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMD),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      widget.student.studentName.isNotEmpty ? widget.student.studentName[0].toUpperCase() : '?',
                      style: AppTypography.header3.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student.studentName,
                          style: AppTypography.header3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$percentage%',
                      style: AppTypography.caption.copyWith(
                        color: barColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppConstants.spacingMD, 0, AppConstants.spacingMD, AppConstants.spacingMD),
              child: Column(
                children: List.generate(5, (index) {
                  final week = index + 1;
                  // Present if true, Absent if false, Null if unrecorded. Let's treat null as absent for toggle purposes.
                  final isPresent = widget.student.weekAttendance[week] == true;
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: AppConstants.spacingSM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Week $week', style: AppTypography.body),
                        Switch(
                          value: isPresent,
                          activeColor: AppColors.success,
                          onChanged: (value) {
                            ref.read(lecturerAttendanceProvider.notifier)
                               .toggleAttendance(widget.student.studentId, week, value);
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
