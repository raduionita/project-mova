import 'package:flutter/material.dart';

import '../models/plate_calculation.dart';
import '../models/plate_loadout.dart';
import '../models/unit_preferences.dart';
import '../services/plate_calculator_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_chip.dart';

/// Opens the plate calculator without changing the workout.
Future<void> showPlateCalculatorSheet(
  BuildContext context, {
  required WeightUnit unit,
  String? exerciseName,
  double targetWeight = 0,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.x3l)),
    ),
    builder: (_) => PlateCalculatorSheet(
      unit: unit,
      exerciseName: exerciseName,
      targetWeight: targetWeight,
    ),
  );
}

/// Plate loading helper for one barbell target.
class PlateCalculatorSheet extends StatefulWidget {
  const PlateCalculatorSheet({
    super.key,
    required this.unit,
    this.exerciseName,
    this.targetWeight = 0,
  });

  final WeightUnit unit;
  final String? exerciseName;
  final double targetWeight;

  @override
  State<PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<PlateCalculatorSheet> {
  static const PlateCalculatorService _calculator = PlateCalculatorService();

  late final PlateLoadout _loadout = PlateLoadout.forUnit(widget.unit);
  late final TextEditingController _targetController;
  late double _barWeight;
  double _target = 0;

  @override
  void initState() {
    super.initState();
    _barWeight = _loadout.defaultBarWeight;
    _target = widget.targetWeight > 0
        ? widget.targetWeight
        : _loadout.defaultBarWeight;
    _targetController = TextEditingController(text: _format(_target));
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  String get _unitLabel => widget.unit == WeightUnit.kg ? 'kg' : 'lb';

  double get _maxTarget => widget.unit == WeightUnit.kg ? 500 : 1102.31;

  String _format(double value) {
    final rounded = (value * 100).round() / 100;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toStringAsFixed(0);
    }
    return rounded.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  PlateCalculation get _result => _calculator.calculate(
    target: _target,
    loadout: _loadout,
    barWeight: _barWeight,
  );

  void _onTargetChanged(String value) {
    setState(() {
      _target = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    });
  }

  Widget _buildHeader() {
    return Column(
      children: <Widget>[
        const SizedBox(height: AppSpacing.md),
        Container(
          width: AppSpacing.x5l,
          height: AppSpacing.xs,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x2l,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Plate calculator',
                      style: AppTypography.h2.copyWith(color: AppColors.text),
                    ),
                    if (widget.exerciseName != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        widget.exerciseName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close plate calculator',
                icon: const Icon(Icons.close, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetField() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      borderSide: const BorderSide(color: AppColors.line),
    );
    return TextField(
      key: const Key('plate-target'),
      controller: _targetController,
      onChanged: _onTargetChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTypography.title.copyWith(color: AppColors.text),
      cursorColor: AppColors.lime,
      decoration: InputDecoration(
        labelText: 'Target weight',
        labelStyle: AppTypography.caption.copyWith(color: AppColors.muted),
        suffixText: _unitLabel,
        suffixStyle: AppTypography.body.copyWith(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x2l,
          vertical: AppSpacing.lg,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: AppColors.limeBorder45),
        ),
      ),
    );
  }

  Widget _buildBarChips() {
    return SizedBox(
      height: AppSpacing.x5l,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _loadout.barWeights.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final weight = _loadout.barWeights[index];
          return AppChip(
            key: Key('plate-bar-${_format(weight)}'),
            label: '${_format(weight)} $_unitLabel bar',
            selected: _barWeight == weight,
            onTap: () => setState(() => _barWeight = weight),
          );
        },
      ),
    );
  }

  Widget _buildPlateRow(double plate, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Container(
            width: AppSpacing.x5l,
            height: AppSpacing.x5l,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              '$count',
              style: AppTypography.label.copyWith(color: AppColors.text),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${_format(plate)} $_unitLabel',
            style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
          ),
          const Spacer(),
          Text(
            'per side',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(PlateCalculation result) {
    final invalid = _target <= 0 || _target > _maxTarget;
    final Widget body;
    if (invalid) {
      body = Text(
        'Enter a target between 0 and ${_format(_maxTarget)} $_unitLabel.',
        style: AppTypography.body.copyWith(color: AppColors.orange),
      );
    } else if (result.belowBar) {
      body = Text(
        'That target is below the ${_format(_barWeight)} $_unitLabel bar.',
        style: AppTypography.body.copyWith(color: AppColors.orange),
      );
    } else if (result.platesPerSide.isEmpty) {
      body = Text(
        'Bar only. Add plates to reach the target.',
        style: AppTypography.body.copyWith(color: AppColors.muted),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Per side',
            style: AppTypography.micro.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final entry in result.platesPerSide.entries)
            _buildPlateRow(entry.key, entry.value),
        ],
      );
    }

    return Container(
      key: const Key('plate-result'),
      padding: const EdgeInsets.all(AppSpacing.x2l),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.x2l),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Total',
            style: AppTypography.micro.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${_format(result.achieved)} $_unitLabel',
            style: AppTypography.h1.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!invalid && !result.belowBar)
            Text(
              result.isExact
                  ? 'Exact load'
                  : 'Closest loadable. '
                        '${_format(result.remainder)} $_unitLabel short.',
              style: AppTypography.caption.copyWith(
                color: result.isExact ? AppColors.lime : AppColors.orange,
              ),
            ),
          if (!invalid && !result.belowBar) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            body,
          ] else ...<Widget>[const SizedBox(height: AppSpacing.sm), body],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x2l,
            0,
            AppSpacing.x2l,
            AppSpacing.x3l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: AppSpacing.lg),
              _buildTargetField(),
              const SizedBox(height: AppSpacing.x2l),
              Text(
                'Bar',
                style: AppTypography.micro.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildBarChips(),
              const SizedBox(height: AppSpacing.x2l),
              _buildResult(result),
            ],
          ),
        ),
      ),
    );
  }
}
