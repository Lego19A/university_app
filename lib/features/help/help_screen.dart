// ============================================================
// HELP SCREEN - FAQ-style help and support section.
// This screen from the Figma design shows expandable FAQ
// items that students can tap to reveal answers.
//
// To connect to real data, replace the _mockFAQs list
// with data from your backend/Firebase or a static JSON file.
// ============================================================

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/orange_header.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ---- Orange header ----
          const OrangeHeader(title: 'Help & FAQ'),

          // ---- FAQ list ----
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              children: [
                // -- Search bar at the top --
                // Allows students to search for specific questions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search FAQ...',
                      hintStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      icon: const Icon(Icons.search, color: AppColors.textSecondary),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingMD),

                // -- FAQ expansion panels --
                // Each panel expands when tapped to reveal the answer
                ..._mockFAQs.map((faq) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppConstants.spacingSM),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Theme(
                      // -- Remove default ExpansionTile borders --
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        // -- Question text (always visible) --
                        title: Text(
                          faq['question']!,
                          style: AppTypography.header3,
                        ),
                        // -- Expand/collapse icon color --
                        iconColor: AppColors.primary,
                        collapsedIconColor: AppColors.textSecondary,
                        // -- Answer text (visible when expanded) --
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              faq['answer']!,
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: AppConstants.spacingLG),

                // -- Contact support section --
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.spacingMD),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.support_agent, size: 40, color: AppColors.primary),
                      const SizedBox(height: AppConstants.spacingSM),
                      Text('Need more help?', style: AppTypography.header3),
                      const SizedBox(height: 4),
                      Text(
                        'Contact student support at\nsupport@university.edu',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
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

// ============================================================
// MOCK FAQ DATA - Replace with real data from your backend.
// ============================================================
final List<Map<String, String>> _mockFAQs = [
  {
    'question': 'How do I enrol in subjects?',
    'answer': 'Go to Dashboard > Subject Enrolment. Select your trimester and choose the subjects you want to register for.',
  },
  {
    'question': 'How does QR attendance work?',
    'answer': 'Your lecturer will display a QR code during class. Open the QR scanner from the Scan tab and scan the code to mark your attendance.',
  },
  {
    'question': 'Where can I view my timetable?',
    'answer': 'Go to Dashboard > Timetable to view your weekly class schedule.',
  },
  {
    'question': 'How do I download my resume?',
    'answer': 'Go to Dashboard > Resume Generation. Review your resume preview and tap the Download button.',
  },
  {
    'question': 'What if my attendance is below 80%?',
    'answer': 'You will receive an alert on your dashboard. Contact your lecturer or academic advisor for guidance.',
  },
];
