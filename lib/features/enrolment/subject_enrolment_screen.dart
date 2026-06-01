// ============================================================
// SUBJECT ENROLMENT SCREEN - Semester + Subject selection with
// timetable builder integration.
//
// Flow:
//   1. User selects a semester from the dropdown
//   2. Available subjects update based on the selected semester
//   3. User selects subjects from the list
//   4. User taps "Enrol & Set Timetable"
//   5. System navigates to the Timetable Builder with selected
//      subjects converted to drag-and-drop session data
//
// To connect to real data, replace the _semesterSubjects map
// with data from your backend/Firebase.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/orange_header.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/repositories/firestore_repository.dart';
import '../timetable/models/timetable_models.dart';
import '../timetable/timetable_builder_screen.dart';
import 'providers/enrolment_provider.dart';

// -- ConsumerStatefulWidget: Gives access to Riverpod providers --
// This allows us to update the global enrolled subjects state
// when the user taps "Enrol & Set Timetable".
class SubjectEnrolmentScreen extends ConsumerStatefulWidget {
  const SubjectEnrolmentScreen({super.key});

  @override
  ConsumerState<SubjectEnrolmentScreen> createState() => _SubjectEnrolmentScreenState();
}

class _SubjectEnrolmentScreenState extends ConsumerState<SubjectEnrolmentScreen> {
  // -- Currently selected semester from the dropdown --
  String _selectedSemester = '';

  // -- Set of selected subject indices for enrolment --
  // Using a Set so subjects can be toggled on/off
  final Set<int> _selectedSubjects = {};

  // -- Dynamic data loaded from Firestore --
  List<String> _semesters = [];
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;

  // -- Get subjects for the currently selected semester --
  List<SubjectModel> get _currentSubjects => _subjects;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    final repo = ref.read(firestoreRepositoryProvider);
    final semesters = await repo.getAvailableSemesters();
    if (mounted && semesters.isNotEmpty) {
      setState(() {
        _semesters = semesters;
        _selectedSemester = semesters.first;
      });
      _loadSubjects(semesters.first);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSubjects(String semester) async {
    setState(() => _isLoading = true);
    final repo = ref.read(firestoreRepositoryProvider);
    // Use a listener on the stream; take the first snapshot for initial load
    repo.getSubjectsForSemester(semester).listen((subjects) {
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // -- Check if enrolment is permanently finalized --
    // If the user has already saved their timetable, the whole
    // screen is replaced with a locked "Completed" view.
    final isFinalized = ref.watch(isEnrolmentFinalizedProvider);
    if (isFinalized) {
      return Scaffold(
        body: Column(
          children: [
            const OrangeHeader(title: 'Subject Enrolment'),
            Expanded(child: _buildCompletedState(context)),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // ---- Orange header ----
          const OrangeHeader(title: 'Subject Enrolment'),

          // ---- Body content ----
          Expanded(
            child: _isLoading && _semesters.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Padding(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Semester Dropdown ----
                  // Allows the student to select which semester to enrol for.
                  // Changing the semester updates the available subject list.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSemester.isEmpty ? null : _selectedSemester,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _semesters.map((semester) {
                          return DropdownMenuItem(
                            value: semester,
                            child: Text(semester, style: AppTypography.body),
                          );
                        }).toList(),
                        onChanged: (value) {
                          // -- Update selected semester and clear subject selection --
                          setState(() {
                            _selectedSemester = value!;
                            _selectedSubjects.clear();
                          });
                          _loadSubjects(value!);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMD),

                  // ---- Section title ----
                  Text('Available Subjects', style: AppTypography.header2),

                  const SizedBox(height: AppConstants.spacingSM),

                  // ---- Subject list with selection circles ----
                  Expanded(
                    child: ListView.builder(
                      itemCount: _currentSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = _currentSubjects[index];
                        final isSelected = _selectedSubjects.contains(index);

                        return GestureDetector(
                          onTap: () {
                            // -- Toggle subject selection --
                            setState(() {
                              if (isSelected) {
                                _selectedSubjects.remove(index);
                              } else {
                                _selectedSubjects.add(index);
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: AppConstants.spacingSM),
                            padding: const EdgeInsets.all(AppConstants.spacingMD),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                              // -- Highlight border when selected --
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.divider,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // -- Selection circle (radio-style) --
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: AppColors.white, size: 16)
                                      : null,
                                ),
                                const SizedBox(width: AppConstants.spacingSM),

                                // -- Subject details --
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(subject.name, style: AppTypography.header3),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                         
                                          // -- Lab indicator --
                                          if (subject.requiresLab) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.timetablePurple.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'LEC + LAB',
                                                style: AppTypography.caption.copyWith(
                                                  color: AppColors.timetablePurple,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 8,
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (!subject.requiresLab) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.timetableBlue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'LEC',
                                                style: AppTypography.caption.copyWith(
                                                  color: AppColors.timetableBlue,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // -- Credit hours badge --
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${subject.credits} CR',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingSM),

                  // ---- Selection count indicator ----
                  // Shows how many subjects are selected and whether
                  // the 3–6 constraint is satisfied. Color changes
                  // from red (too few/many) to green (valid range).
                  _buildSelectionCounter(),

                  const SizedBox(height: AppConstants.spacingSM),

                  // ---- Enrol & Set Timetable button ----
                  // Disabled until exactly 3–6 subjects are selected.
                  PrimaryButton(
                    label: 'Enrol & Set Timetable (${_selectedSubjects.length} selected)',
                    onPressed: (_selectedSubjects.length >= kMinSubjects &&
                            _selectedSubjects.length <= kMaxSubjects)
                        ? () => _onEnrolPressed()
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // _onEnrolPressed - Converts selected subjects to timetable
  // Subject models and navigates to the Timetable Builder.
  // ============================================================
  void _onEnrolPressed() {
    // -- Guard: double-check constraint before proceeding --
    if (_selectedSubjects.length < kMinSubjects ||
        _selectedSubjects.length > kMaxSubjects) {
      return;
    }

    // -- Extract the subject codes from the selected indices --
    final selectedCodes = _selectedSubjects
        .map((index) => _currentSubjects[index].code)
        .toList();

    // -- Build metadata map for attendance initialization --
    // This gives the attendance system enough info to create
    // a 50% baseline record for each session (LEC/LAB).
    final metaMap = <String, EnrolledSubjectMeta>{};
    for (final index in _selectedSubjects) {
      final subject = _currentSubjects[index];
      final code = subject.code;
      metaMap[code] = EnrolledSubjectMeta(
        code: subject.code,
        name: subject.name,
        hasLab: subject.requiresLab,
      );
    }

    // -- Update the global enrolment state via Riverpod --
    // After this, Attendance and Timetable rebuild reactively.
    ref.read(enrolledSubjectCodesProvider.notifier).enrolSubjects(
          selectedCodes,
          meta: metaMap,
        );

    // -- Persist enrollment to Firestore --
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      ref.read(firestoreRepositoryProvider).enrollStudent(uid, selectedCodes);
    }

    // -- Convert selected subjects to timetable Subject models --
    final subjects = _buildSubjectsFromSelection();

    // -- Navigate to the Timetable Builder --
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimetableBuilderScreen(subjects: subjects),
      ),
    );
  }

  // ============================================================
  // _buildSubjectsFromSelection - Creates timetable Subject models
  // from the currently selected subjects.
  // Each subject gets a Lecture (2hr) and optionally a Lab (2hr).
  // ============================================================
  List<Subject> _buildSubjectsFromSelection() {
    // Color palette for visual distinction
    const colors = [
      Color(0xFF3498DB), // Blue
      Color(0xFFE74C3C), // Red
      Color(0xFFF39C12), // Yellow
      Color(0xFF2ECC71), // Green
      Color(0xFF9B59B6), // Purple
      Color(0xFFE67E22), // Orange
    ];

    final selectedList = _selectedSubjects.toList()..sort();

    return selectedList.asMap().entries.map((entry) {
      final colorIndex = entry.key;
      final subjectIndex = entry.value;

      final data = _subjects[subjectIndex];
      final color = colors[colorIndex % colors.length];
      final subjectId = data.code.toLowerCase().replaceAll(RegExp(r'[0-9]'), '');
      final name = data.name;
      final code = data.code;
      final requiresLab = data.requiresLab;

      // -- Convert Firestore SubjectSessionModels to timetable SubjectSessions --
      final allAvailableSessions = data.offered_sessions.map((fsSession) {
        return SubjectSession(
          id: fsSession.id,
          type: fsSession.type.toLowerCase() == 'lab'
              ? SessionType.lab
              : SessionType.lecture,
          dayOfWeek: fsSession.dayOfWeek,
          startHour: fsSession.startHour,
          durationHours: fsSession.durationHours,
        );
      }).toList();

      // -- Filter available slots by session type --
      final lectureSlots = allAvailableSessions
          .where((s) => s.type == SessionType.lecture)
          .toList();
      final labSlots = allAvailableSessions
          .where((s) => s.type == SessionType.lab)
          .toList();

      final sessions = <Session>[
        Session(
          id: '${code}_lec',
          subjectId: subjectId,
          subjectName: name,
          subjectCode: code,
          type: SessionType.lecture,
          durationHours: 2,
          color: color,
          availableSlots: lectureSlots,
        ),
      ];

      if (requiresLab) {
        sessions.add(Session(
          id: '${code}_lab',
          subjectId: subjectId,
          subjectName: name,
          subjectCode: code,
          type: SessionType.lab,
          durationHours: 2,
          color: color,
          availableSlots: labSlots,
        ));
      }

      return Subject(
        id: subjectId,
        name: name,
        code: code,
        requiresLab: requiresLab,
        color: color,
        sessions: sessions,
        availableSessions: allAvailableSessions,
      );
    }).toList();
  }

  // ============================================================
  // _buildSelectionCounter - Colour-coded constraint feedback.
  //   Red:   count < 3 or count > 6
  //   Green: count is 3–6 (valid, button becomes enabled)
  // ============================================================
  Widget _buildSelectionCounter() {
    final count = _selectedSubjects.length;
    final bool isValid = count >= kMinSubjects && count <= kMaxSubjects;
    final bool isTooMany = count > kMaxSubjects;

    final String message;
    if (count == 0) {
      message = 'Select between $kMinSubjects and $kMaxSubjects subjects';
    } else if (isTooMany) {
      message = '$count selected — maximum is $kMaxSubjects subjects';
    } else if (!isValid) {
      message = '$count selected — minimum is $kMinSubjects subjects';
    } else {
      message = '$count subject${count == 1 ? '' : 's'} selected ✓';
    }
    final color = isValid ? AppColors.success : AppColors.error;

    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle_outline : Icons.info_outline,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          message,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // _buildCompletedState - Permanently locked view displayed once
  // isFinalized is true (after the user saves their timetable).
  // All interactive elements are removed. Display only.
  // ============================================================
  Widget _buildCompletedState(BuildContext context) {
    final enrolmentState = ref.watch(enrolledSubjectCodesProvider);
    final enrolledCodes = enrolmentState.subjectCodes;
    final subjectMeta = enrolmentState.subjectMeta;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // -- Success icon --
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 56, color: AppColors.success),
            ),
            const SizedBox(height: AppConstants.spacingLG),
            Text('Enrolment Completed', style: AppTypography.header2, textAlign: TextAlign.center),
            const SizedBox(height: AppConstants.spacingSM),
            Text(
              'Your subject enrolment has been\nsubmitted and is now locked.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLG),

            // -- Read-only enrolled subject code list --
            if (enrolledCodes.isNotEmpty) ...[
              Text('Enrolled Subjects', style: AppTypography.header3),
              const SizedBox(height: AppConstants.spacingSM),
              ...enrolledCodes.map(
                (code) {
                  final name = subjectMeta[code]?.name ?? '';
                  final displayText = name.isEmpty ? code : '$name';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.circle, size: 8, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            displayText,
                            style: AppTypography.body,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

