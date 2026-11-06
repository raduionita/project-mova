import 'package:flutter/material.dart';

import '../common/constants.dart';
import '../common/date_keys.dart';
import '../services/clock.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_wheel_picker.dart';

/// Keyboard-free birth date picker used by profile editing.
class BirthDateSheet extends StatefulWidget {
  const BirthDateSheet({super.key, this.initialDate, this.clock});

  final DateTime? initialDate;
  final Clock? clock;

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    Clock? clock,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.panel,
      builder: (_) => BirthDateSheet(initialDate: initialDate, clock: clock),
    );
  }

  @override
  State<BirthDateSheet> createState() => _BirthDateSheetState();
}

class _BirthDateSheetState extends State<BirthDateSheet> {
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

  late final DateTime _today;
  late final int _minYear;
  late final int _maxYear;

  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    final now = (widget.clock ?? const SystemClock()).now();
    _today = DateTime(now.year, now.month, now.day);
    _minYear = _today.year - kMaxAge;
    _maxYear = _today.year - kMinAge;
    final initial =
        widget.initialDate ??
        DateTime(_today.year - 25, _today.month, _today.day);
    _year = initial.year.clamp(_minYear, _maxYear);
    _month = initial.month.clamp(1, 12);
    _day = initial.day.clamp(1, DateKeys.daysInMonth(_year, _month));
  }

  DateTime get _date => DateTime(_year, _month, _day);

  int get _age => DateKeys.ageOn(_date, _today);

  bool get _isValid => _age >= kMinAge && _age <= kMaxAge;

  String? get _errorText {
    if (_age < kMinAge) {
      return 'You must be at least $kMinAge years old.';
    }
    if (_age > kMaxAge) {
      return 'Enter a birth year within the last $kMaxAge years.';
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
    return List<String>.generate(
      DateKeys.daysInMonth(_year, _month),
      (index) => '${index + 1}',
    );
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

  Widget _buildWheelColumn(String label, Widget wheel) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          wheel,
        ],
      ),
    );
  }

  void _save() {
    if (_isValid) {
      Navigator.of(context).pop(_date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _errorText;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3l,
        AppSpacing.x2l,
        AppSpacing.x3l,
        AppSpacing.x3l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: AppSpacing.x6l,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x2l),
          Text(
            'Date of birth',
            style: AppTypography.h2.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your age helps us tune the plan. Stored only on this device.',
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.x2l),
          Row(
            children: <Widget>[
              _buildWheelColumn(
                'Month',
                AppWheelPicker(
                  key: const ValueKey<String>('profile-birth-month'),
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
                  key: const ValueKey<String>('profile-birth-day'),
                  values: _days,
                  selectedIndex: _day - 1,
                  onSelectedIndexChanged: (index) =>
                      setState(() => _day = index + 1),
                  semanticLabel: 'Birth day',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _buildWheelColumn(
                'Year',
                AppWheelPicker(
                  key: const ValueKey<String>('profile-birth-year'),
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
              style: AppTypography.caption.copyWith(color: AppColors.orange),
            ),
          ],
          const SizedBox(height: AppSpacing.x3l),
          AppButton(
            key: const Key('profile-birth-save'),
            label: 'Save date',
            onPressed: _isValid ? _save : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
