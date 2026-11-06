import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/date_keys.dart';
import '../common/formatters.dart';
import '../models/unit_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

const List<String> _dayInitials = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const double _maxBarHeight = 54;

/// Seven day volume chart from DESIGN.md section 8.11.
///
/// The text summary above the bars is the primary readable value; the bars are
/// a visual companion with dim placeholder heights for empty days.
class VolumeBars extends StatefulWidget {
  const VolumeBars({
    super.key,
    required this.volumeByDay,
    required this.now,
    this.unit = WeightUnit.kg,
  });

  final Map<String, double> volumeByDay;
  final DateTime now;
  final WeightUnit unit;

  @override
  State<VolumeBars> createState() => _VolumeBarsState();
}

class _VolumeBarsState extends State<VolumeBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant VolumeBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.volumeByDay != widget.volumeByDay ||
        oldWidget.now != widget.now ||
        oldWidget.unit != widget.unit) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DateTime> get _days {
    return <DateTime>[
      for (var offset = 6; offset >= 0; offset--)
        DateTime(widget.now.year, widget.now.month, widget.now.day - offset),
    ];
  }

  String get _summary {
    final total = widget.volumeByDay.values.fold(
      0.0,
      (sum, value) => sum + value,
    );
    if (total <= 0) {
      return 'No data yet';
    }
    return '${formatVolume(total, unit: widget.unit)} this week';
  }

  Widget _buildBar(DateTime day, double maxVolume) {
    final volume = widget.volumeByDay[DateKeys.dayKey(day)] ?? 0;
    final isEmpty = volume <= 0;
    final target = isEmpty
        ? _maxBarHeight * 0.3
        : math.max(6.0, volume / maxVolume * _maxBarHeight);
    final index = _days.indexOf(day);
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        (index * 0.075).clamp(0.0, 0.55),
        1,
        curve: Curves.easeOut,
      ),
    );
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: _maxBarHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  return Container(
                    height: math.max(2, target * animation.value),
                    decoration: BoxDecoration(
                      color: isEmpty ? AppColors.volumeEmpty : null,
                      gradient: isEmpty
                          ? null
                          : const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                AppColors.lime,
                                AppColors.volumeFillEnd,
                              ],
                            ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _dayInitials[day.weekday - 1],
            style: AppTypography.micro.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;
    final maxVolume = days
        .map((day) => widget.volumeByDay[DateKeys.dayKey(day)] ?? 0)
        .fold(0.0, math.max);
    return Semantics(
      label: 'Weekly volume',
      value: _summary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _summary,
            style: AppTypography.title.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (var index = 0; index < days.length; index++) ...<Widget>[
                if (index > 0) const SizedBox(width: AppSpacing.sm),
                _buildBar(days[index], maxVolume),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
