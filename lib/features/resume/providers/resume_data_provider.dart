import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resume_data_model.dart';

// ============================================================
// RESUME DATA PROVIDER - Holds the user's in-memory resume inputs.
// This allows the data to persist while the user navigates between
// the input form and the preview screen, without needing to save
// to Firestore.
// ============================================================

final resumeDataProvider = StateProvider<ResumeData?>((ref) {
  return null;
});
