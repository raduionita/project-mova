import '../models/user_profile.dart';
import 'experience_display.dart';

/// Name shown for the local profile.
///
/// A saved name wins. Until the user adds one, the experience level picked
/// during onboarding stands in, so the app never shows a fake name.
String profileDisplayName(UserProfile? profile) {
  final saved = profile?.displayName.trim() ?? '';
  if (saved.isNotEmpty) {
    return saved;
  }
  final level = profile?.experienceLevel;
  if (level != null) {
    return experienceLevelLabel(level);
  }
  return 'Guest';
}
