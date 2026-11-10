import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/display_name.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/user_profile.dart';

final DateTime _now = DateTime.utc(2026, 11, 10, 12);

UserProfile _profile({String displayName = '', ExperienceLevel? level}) {
  return UserProfile(
    id: 'profile-1',
    displayName: displayName,
    experienceLevel: level,
    createdAt: _now,
    updatedAt: _now,
  );
}

void main() {
  test('a saved name wins over the experience level', () {
    final profile = _profile(
      displayName: '  Andrei  ',
      level: ExperienceLevel.gymRat,
    );

    expect(profileDisplayName(profile), 'Andrei');
  });

  test('an empty name falls back to the experience level label', () {
    final profile = _profile(level: ExperienceLevel.regular);

    expect(profileDisplayName(profile), 'Regular');
  });

  test('a missing profile falls back to Guest', () {
    expect(profileDisplayName(null), 'Guest');
  });
}
