import 'package:intl/intl.dart';

import '../models/unit_preferences.dart';

final DateFormat _shortDateFormat = DateFormat('EEE, MMM d', 'en_US');
final DateFormat _detailDateFormat = DateFormat('MMM d, y', 'en_US');
final DateFormat _monthYearFormat = DateFormat('MMMM y', 'en_US');
final NumberFormat _stepFormat = NumberFormat('#,##0', 'en_US');
const double _lbPerKg = 2.2046226218487757;

/// Strips a trailing `.0` so integers render without a decimal.
String _trimDecimal(String value) {
  return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
}

/// Formats workout volume in the selected weight unit.
///
/// Stored values stay in kilograms. Metric volume switches to tonnes at
/// 1000 kg; imperial volume always reads in pounds.
String formatVolume(double kilograms, {WeightUnit unit = WeightUnit.kg}) {
  final safe = kilograms < 0 ? 0.0 : kilograms;
  if (unit == WeightUnit.kg) {
    if (safe >= 1000) {
      return '${_trimDecimal((safe / 1000).toStringAsFixed(1))} t';
    }
    return '${_trimDecimal(safe.toStringAsFixed(1))} kg';
  }
  return '${_trimDecimal((safe * _lbPerKg).toStringAsFixed(1))} lb';
}

/// Formats seconds as `mm:ss` below one hour and `h:mm` above it.
String formatDuration(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  if (safe < 3600) {
    final minutes = safe ~/ 60;
    final remainder = safe % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainder.toString().padLeft(2, '0')}';
  }
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  return '$hours:${minutes.toString().padLeft(2, '0')}';
}

/// Formats a step count with thousands separators, for example `8,240`.
String formatSteps(int steps) {
  return _stepFormat.format(steps < 0 ? 0 : steps);
}

/// Formats a list date, for example `Mon, Nov 2`.
String formatShortDate(DateTime date) {
  return _shortDateFormat.format(date);
}

/// Formats a detail date, for example `Nov 2, 2026`.
String formatDetailDate(DateTime date) {
  return _detailDateFormat.format(date);
}

/// Formats a history month header, for example `November 2026`.
String formatMonthYear(DateTime date) {
  return _monthYearFormat.format(date);
}

/// Short relative time for feed posts, for example `Just now`, `3h`, or a date.
String formatRelativeTime(DateTime date, DateTime now) {
  final difference = now.difference(date);
  if (difference.isNegative || difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}d';
  }
  return formatShortDate(date);
}
