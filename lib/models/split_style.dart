/// Split styles available when generating a rotation plan.
enum SplitStyle {
  auto,
  fullBody,
  upperLower,
  ppl;

  /// Human readable label used in the planner and onboarding.
  String get label {
    switch (this) {
      case SplitStyle.auto:
        return 'Auto';
      case SplitStyle.fullBody:
        return 'Full Body';
      case SplitStyle.upperLower:
        return 'Upper / Lower';
      case SplitStyle.ppl:
        return 'Push / Pull / Legs';
    }
  }
}
