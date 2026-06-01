// ============================================================
// RESUME DATA MODEL - Holds the user's resume information.
// This data class decouples resume content from the UI and
// PDF rendering. In production, populate from backend/profile.
//
// Sections:
//   - Personal info (name, email, phone)
//   - Education (degree, university, years)
//   - Skills (list of skill strings)
//   - Experience (job title, company, dates, description)
// ============================================================

class ResumeData {
  final String name;
  final String email;
  final String phone;
  final String address;

  final List<EducationEntry> education;
  final List<String> skills;
  final List<ExperienceEntry> experience;
  final List<String> extracurriculars;

  const ResumeData({
    required this.name,
    required this.email,
    required this.phone,
    this.address = '',
    required this.education,
    required this.skills,
    required this.experience,
    required this.extracurriculars,
  });
}

class EducationEntry {
  final String degree;
  final String institution;
  final String years;
  final String? gpa;

  const EducationEntry({
    required this.degree,
    required this.institution,
    required this.years,
    this.gpa,
  });
}

class ExperienceEntry {
  final String title;
  final String company;
  final String dates;
  final String description;

  const ExperienceEntry({
    required this.title,
    required this.company,
    required this.dates,
    required this.description,
  });
}

// Removed mockResumeData to force dynamic generation
