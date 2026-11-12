import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wellness_provider.dart';
import 'numeric_input_sheet.dart';

/// Shared quick-add flows for the wellness placeholders.
Future<void> addNutrition(BuildContext context) async {
  final provider = context.read<WellnessProvider>();
  final current = provider.todayEntry;
  final calories = await showNumericInputSheet(
    context,
    title: 'Nutrition',
    label: 'Calories',
    initialValue: current?.calories?.toDouble() ?? 0,
    max: 20000,
  );
  if (!context.mounted || calories == null) {
    return;
  }
  final protein = await showNumericInputSheet(
    context,
    title: 'Nutrition',
    label: 'Protein (g)',
    initialValue: current?.proteinGrams?.toDouble() ?? 0,
    max: 1000,
  );
  if (!context.mounted) {
    return;
  }
  await provider.saveNutrition(
    calories: calories.round(),
    proteinGrams: protein?.round(),
  );
}

Future<void> addSleep(BuildContext context) async {
  final provider = context.read<WellnessProvider>();
  final current = provider.todayEntry?.sleepMinutes ?? 0;
  final hours = await showNumericInputSheet(
    context,
    title: 'Sleep',
    label: 'Hours',
    initialValue: (current ~/ 60).toDouble(),
    max: 23,
  );
  if (!context.mounted || hours == null) {
    return;
  }
  final minutes = await showNumericInputSheet(
    context,
    title: 'Sleep',
    label: 'Minutes',
    initialValue: (current % 60).toDouble(),
    max: 59,
  );
  if (!context.mounted) {
    return;
  }
  await provider.saveSleepMinutes(
    hours.round() * 60 + (minutes?.round() ?? 0),
  );
}

Future<void> addRestingHeartRate(BuildContext context) async {
  final provider = context.read<WellnessProvider>();
  final bpm = await showNumericInputSheet(
    context,
    title: 'Resting heart rate',
    label: 'Beats per minute',
    initialValue:
        provider.todayEntry?.restingHeartRate?.toDouble() ?? 0,
    max: 250,
    helperText: 'Measure while rested. This is a personal trend, not medical '
        'advice.',
  );
  if (!context.mounted || bpm == null) {
    return;
  }
  await provider.saveRestingHeartRate(bpm.round());
}

Future<void> addMeasurement(BuildContext context) async {
  final provider = context.read<WellnessProvider>();
  final value = await showNumericInputSheet(
    context,
    title: 'Measurements',
    label: 'Waist (cm)',
    initialValue: provider.latestMeasurement?.waistCm ?? 0,
    allowDecimal: true,
    max: 300,
  );
  if (!context.mounted || value == null) {
    return;
  }
  await provider.saveWaistCm(value);
}
