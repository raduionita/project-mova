import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/date_keys.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/clock.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_onboarding_type.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_wheel_picker.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 3: birth date. The user must be 13 to 120 years old.
class BirthDateScreen extends StatefulWidget {
  const BirthDateScreen({super.key, this.onRoute, this.clock});

  /// Optional routing hook for tests. When null, named routes are pushed on
  /// the ambient navigator.
  final ValueChanged<String>? onRoute;

  /// Clock used for the default date and the age check.
  final Clock? clock;

  @override
  State<BirthDateScreen> createState() => _BirthDateScreenState();
}

class _BirthDateScreenState extends State<BirthDateScreen> {
  static const List<String> _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const int _minAge = 13;
  static const int _maxAge = 120;

  late final DateTime _today;
  late final int _minYear;
  late final int _maxYear;

  late int _year;
  late int _month;
  late int _day;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final now = (widget.clock ?? const SystemClock()).now();
    _today = DateTime(now.year, now.month, now.day);
    _minYear = _today.year - _maxAge;
    _maxYear = _today.year - _minAge;

    final stored = context.read<OnboardingProvider>().draft.birthDate;
    final initial =
        stored ?? DateTime(_today.year - 25, _today.month, _today.day);
    _year = initial.year.clamp(_minYear, _maxYear);
    _month = initial.month.clamp(1, 12);
    _day = initial.day.clamp(1, DateKeys.daysInMonth(_year, _month));
  }

  DateTime get _birthDate => DateTime(_year, _month, _day);

  bool get _isValidAge {
    final age = DateKeys.ageOn(_birthDate, _today);
    return age >= _minAge && age <= _maxAge;
  }

  String? get _errorText {
    final age = DateKeys.ageOn(_birthDate, _today);
    if (age < _minAge) {
      return 'You must be at least $_minAge years old.';
    }
    if (age > _maxAge) {
      return 'Enter a birth year within the last $_maxAge years.';
    }
    return null;
  }

  List<int> get _years {
    return List<int>.generate(
      _maxYear - _minYear + 1,
      (index) => _minYear + index,
    );
  }

  List<String> get _days {
    final count = DateKeys.daysInMonth(_year, _month);
    return List<String>.generate(count, (index) => '${index + 1}');
  }

  void _open(BuildContext context, String route) {
    final handler = widget.onRoute;
    if (handler != null) {
      handler(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  void _setMonth(int index) {
    setState(() {
      _month = index + 1;
      _day = _day.clamp(1, DateKeys.daysInMonth(_year, _month));
    });
  }

  void _setYear(int index) {
    setState(() {
      _year = _years[index];
      _day = _day.clamp(1, DateKeys.daysInMonth(_year, _month));
    });
  }

  void _setDay(int index) {
    setState(() => _day = index + 1);
  }

  Future<void> _continue() async {
    if (_isBusy || !_isValidAge) {
      return;
    }
    setState(() => _isBusy = true);
    final onboarding = context.read<OnboardingProvider>();
    await onboarding.setBirthDate(_birthDate);
    final next = OnboardingFlow.nextRoute(Routes.onboardingBirthDate)!;
    onboarding.syncStep(OnboardingFlow.stepFor(next));
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _open(context, next);
  }

  void _back(BuildContext context) {
    final previous = OnboardingFlow.previousRoute(Routes.onboardingBirthDate)!;
    context.read<OnboardingProvider>().syncStep(
      OnboardingFlow.stepFor(previous),
    );
    _open(context, previous);
  }

  Widget _buildWheelColumn(String label, Widget wheel) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: AppOnboardingType.micro.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          wheel,
        ],
      ),
    );
  }

  Widget _buildWheels() {
    final error = _errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            _buildWheelColumn(
              'Month',
              AppWheelPicker(
                key: const ValueKey<String>('birth-month-wheel'),
                values: _monthNames,
                selectedIndex: _month - 1,
                onSelectedIndexChanged: _setMonth,
                semanticLabel: 'Birth month',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _buildWheelColumn(
              'Day',
              AppWheelPicker(
                key: const ValueKey<String>('birth-day-wheel'),
                values: _days,
                selectedIndex: _day - 1,
                onSelectedIndexChanged: _setDay,
                semanticLabel: 'Birth day',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _buildWheelColumn(
              'Year',
              AppWheelPicker(
                key: const ValueKey<String>('birth-year-wheel'),
                values: _years.map((year) => '$year').toList(growable: false),
                selectedIndex: _year - _minYear,
                onSelectedIndexChanged: _setYear,
                semanticLabel: 'Birth year',
              ),
            ),
          ],
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          Text(
            error,
            textAlign: TextAlign.center,
            style: AppOnboardingType.caption.copyWith(color: AppColors.orange),
          ),
        ],
        const SizedBox(height: AppSpacing.x3l),
        AppCard(
          child: Text(
            'Must be at least 13 and no more than 120 years old. '
            'Leap years are handled.',
            style: AppOnboardingType.caption.copyWith(color: AppColors.muted),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'When were you born?',
      subtitle: 'Your age helps us tune the plan.',
      currentStep: OnboardingFlow.stepForRoute(Routes.onboardingBirthDate),
      onBack: () => _back(context),
      onContinue: _continue,
      continueEnabled: _isValidAge,
      isBusy: _isBusy,
      centerContent: true,
      child: _buildWheels(),
    );
  }
}
