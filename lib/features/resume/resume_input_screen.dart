import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/orange_header.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/repositories/user_repository.dart';
import 'models/resume_data_model.dart';
import 'providers/resume_data_provider.dart';
import 'resume_screen.dart';

class ResumeInputScreen extends ConsumerStatefulWidget {
  const ResumeInputScreen({super.key});

  @override
  ConsumerState<ResumeInputScreen> createState() => _ResumeInputScreenState();
}

class _ResumeInputScreenState extends ConsumerState<ResumeInputScreen> {
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceTitleController = TextEditingController();
  final _experienceDescController = TextEditingController();
  final _extracurricularController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill existing state if the user navigates back from preview
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existingData = ref.read(resumeDataProvider);
      if (existingData != null) {
        _phoneController.text = existingData.phone;
        _addressController.text = existingData.address;
        _skillsController.text = existingData.skills.join(', ');
        if (existingData.experience.isNotEmpty) {
          _experienceTitleController.text = existingData.experience.first.title;
          _experienceDescController.text = existingData.experience.first.description;
        }
        if (existingData.extracurriculars.isNotEmpty) {
          _extracurricularController.text = existingData.extracurriculars.join(', ');
        }
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _skillsController.dispose();
    _experienceTitleController.dispose();
    _experienceDescController.dispose();
    _extracurricularController.dispose();
    super.dispose();
  }

  void _generateResume(AppUser user) {
    if (!_formKey.currentState!.validate()) return;

    final programme = user.metadata['programme'] as String? ?? 'University Degree';

    final data = ResumeData(
      name: user.full_name.toUpperCase(),
      email: user.email,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      education: [
        EducationEntry(
          degree: programme,
          institution: 'University', // Hardcoded as per normal layout
          years: 'Present',
        ),
      ],
      skills: _skillsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      experience: _experienceTitleController.text.isNotEmpty || _experienceDescController.text.isNotEmpty
          ? [
              ExperienceEntry(
                title: _experienceTitleController.text.trim(),
                company: 'Self/Project', // Fallback
                dates: 'Recent',
                description: _experienceDescController.text.trim(),
              )
            ]
          : [],
      extracurriculars: _extracurricularController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );

    // Save to local session state
    ref.read(resumeDataProvider.notifier).state = data;

    // Navigate to preview
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ResumeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: Column(
        children: [
          const OrangeHeader(title: 'Resume Details'),
          Expanded(
            child: userAsync.when(
              data: (user) {
                if (user == null) return const Center(child: Text('User not found'));
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Information',
                          style: AppTypography.header3,
                        ),
                        const SizedBox(height: 12),
                        // Name and Email are read-only since they come from the profile
                        TextFormField(
                          initialValue: user.full_name,
                          enabled: false,
                          decoration: const InputDecoration(labelText: 'Full Name'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          initialValue: user.email,
                          enabled: false,
                          decoration: const InputDecoration(labelText: 'Email Address'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone Number (e.g. +60...)'),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Address'),
                        ),
                        
                        const SizedBox(height: 24),
                        Text(
                          'Skills',
                          style: AppTypography.header3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _skillsController,
                          decoration: const InputDecoration(
                            labelText: 'Skills (comma separated)',
                            hintText: 'e.g. Flutter, Dart, Firebase',
                          ),
                        ),

                        const SizedBox(height: 24),
                        Text(
                          'Experience',
                          style: AppTypography.header3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _experienceTitleController,
                          decoration: const InputDecoration(labelText: 'Role / Project Title'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _experienceDescController,
                          decoration: const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 24),
                        Text(
                          'Extracurricular Activities',
                          style: AppTypography.header3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _extracurricularController,
                          decoration: const InputDecoration(
                            labelText: 'Activities (comma separated)',
                            hintText: 'e.g. Coding Club, Student Council',
                          ),
                          maxLines: 2,
                        ),

                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: 'Generate Resume',
                          onPressed: () => _generateResume(user),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
