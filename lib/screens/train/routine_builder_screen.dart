import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/routine.dart';
import '../../models/routine_exercise.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/routine_provider.dart';
import '../../services/id_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/exercise_picker_sheet.dart';

/// Creates a routine or edits an existing one at `/train/routines/new` and
/// `/train/routines/:id/edit`.
class RoutineBuilderScreen extends StatefulWidget {
  const RoutineBuilderScreen({super.key, this.routineId, this.idService});

  final String? routineId;
  final IdService? idService;

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  static const int _maxExercises = 20;

  late final TextEditingController _nameController;
  late final IdService _idService;

  Routine? _existing;
  List<RoutineExercise> _exercises = const <RoutineExercise>[];
  bool _loaded = false;
  bool _notFound = false;
  bool _saving = false;
  bool _dirty = false;
  String? _nameError;
  String? _exercisesError;

  bool get _isEditing => widget.routineId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _idService = widget.idService ?? IdService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final routines = context.read<RoutineProvider>();
    final exercises = context.read<ExerciseProvider>();
    final loads = <Future<void>>[];
    if (_isEditing && routines.routines.isEmpty && !routines.isLoading) {
      loads.add(routines.load());
    }
    if (exercises.exercises.isEmpty && !exercises.isLoading) {
      loads.add(exercises.load());
    }
    if (loads.isNotEmpty) {
      await Future.wait(loads);
    }
    if (!mounted) {
      return;
    }
    Routine? routine;
    if (_isEditing) {
      routine = routines.routines
          .where((item) => item.id == widget.routineId)
          .firstOrNull;
    }
    if (_isEditing && routine == null) {
      setState(() {
        _notFound = true;
        _loaded = true;
      });
      return;
    }
    if (routine != null) {
      _existing = routine;
      _nameController.text = routine.name;
      _exercises = <RoutineExercise>[...routine.exercises]
        ..sort((a, b) => a.order.compareTo(b.order));
    }
    setState(() => _loaded = true);
  }

  Future<void> _addExercises() async {
    final result = await showExercisePicker(
      context,
      mode: ExercisePickerMode.routine,
      multiSelect: true,
    );
    if (result == null || result.exercises.isEmpty || !mounted) {
      return;
    }
    final existingIds = _exercises.map((item) => item.exerciseId).toSet();
    final additions = result.exercises
        .where((exercise) => !existingIds.contains(exercise.id))
        .take(_maxExercises - _exercises.length)
        .toList(growable: false);
    if (additions.isEmpty) {
      return;
    }
    setState(() {
      _exercises = <RoutineExercise>[
        ..._exercises,
        for (var index = 0; index < additions.length; index++)
          RoutineExercise(
            exerciseId: additions[index].id,
            sets: 3,
            repsLow: 8,
            repsHigh: 12,
            restSeconds: 90,
            order: _exercises.length + index,
          ),
      ];
      _exercisesError = null;
      _dirty = true;
    });
  }

  void _removeExercise(int index) {
    setState(() {
      final next = <RoutineExercise>[..._exercises]..removeAt(index);
      _exercises = _withOrder(next);
      _dirty = true;
    });
  }

  void _updateExercise(int index, RoutineExercise next) {
    setState(() {
      final exercises = <RoutineExercise>[..._exercises];
      exercises[index] = next;
      _exercises = exercises;
      _dirty = true;
    });
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      final next = <RoutineExercise>[..._exercises];
      final moved = next.removeAt(oldIndex);
      next.insert(newIndex, moved);
      _exercises = _withOrder(next);
      _dirty = true;
    });
  }

  List<RoutineExercise> _withOrder(List<RoutineExercise> exercises) {
    return <RoutineExercise>[
      for (var index = 0; index < exercises.length; index++)
        exercises[index].copyWith(order: index),
    ];
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final nameError = name.isEmpty ? 'Name your routine.' : null;
    final exercisesError = _exercises.isEmpty
        ? 'Add at least one exercise.'
        : null;
    if (nameError != null || exercisesError != null) {
      setState(() {
        _nameError = nameError;
        _exercisesError = exercisesError;
      });
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final routine = Routine(
      id: _existing?.id ?? _idService.next(),
      name: name,
      exercises: _withOrder(_exercises),
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
    );
    final provider = context.read<RoutineProvider>();
    final saved = await provider.save(routine);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not save routine.')),
      );
      return;
    }
    _dirty = false;
    Navigator.of(context).pop();
  }

  Future<void> _requestClose() async {
    if (!_dirty) {
      Navigator.of(context).maybePop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.x2l),
        ),
        title: Text(
          'Discard changes?',
          style: AppTypography.h2.copyWith(color: AppColors.text),
        ),
        content: Text(
          'Your routine changes have not been saved.',
          style: AppTypography.body.copyWith(color: AppColors.muted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Keep editing',
              style: AppTypography.label.copyWith(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Discard',
              style: AppTypography.label.copyWith(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) {
      return;
    }
    setState(() => _dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {
            _nameError = null;
            _dirty = true;
          }),
          style: AppTypography.body.copyWith(color: AppColors.text),
          decoration: InputDecoration(
            labelText: 'Routine name',
            hintText: 'Push day',
            labelStyle: AppTypography.caption.copyWith(color: AppColors.muted),
            hintStyle: AppTypography.body.copyWith(color: AppColors.muted),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x2l,
              vertical: AppSpacing.xl,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: BorderSide(color: AppColors.limeBorder45),
            ),
          ),
        ),
        if (_nameError != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _nameError!,
            style: AppTypography.caption.copyWith(color: AppColors.orange),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyExercises() {
    return AppEmptyState(
      assetIcon: AppIcons.list,
      title: 'No exercises yet',
      message: 'Add exercises to build this routine.',
    );
  }

  Widget _buildExerciseCard(int index, RoutineExercise exercise) {
    final name =
        context.read<ExerciseProvider>().byId(exercise.exerciseId)?.name ??
        'Unknown exercise';
    return Container(
      key: ValueKey<String>('routine-exercise-${exercise.exerciseId}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              ReorderableDelayedDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: AppIcon(
                    asset: AppIcons.drag,
                    size: 20,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyStrong.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${exercise.sets} sets · '
                      '${exercise.repsLow}-${exercise.repsHigh} reps',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeExercise(index),
                tooltip: 'Remove $name',
                visualDensity: VisualDensity.compact,
                icon: const AppIcon(
                  asset: AppIcons.trash,
                  size: 20,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildMiniStepper(
                  label: 'Sets',
                  value: exercise.sets,
                  min: 1,
                  max: 10,
                  onChanged: (value) =>
                      _updateExercise(index, exercise.copyWith(sets: value)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildMiniStepper(
                  label: 'Reps',
                  value: exercise.repsLow,
                  min: 1,
                  max: 30,
                  onChanged: (value) => _updateExercise(
                    index,
                    exercise.copyWith(
                      repsLow: value,
                      repsHigh: value > exercise.repsHigh
                          ? value
                          : exercise.repsHigh,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildMiniStepper(
                  label: 'Max',
                  value: exercise.repsHigh,
                  min: exercise.repsLow,
                  max: 30,
                  onChanged: (value) => _updateExercise(
                    index,
                    exercise.copyWith(repsHigh: value),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.micro.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: AppSpacing.x5l,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: <Widget>[
              _buildStepButton(
                asset: AppIcons.minus,
                semanticLabel: 'Decrease $label',
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: AppTypography.label.copyWith(color: AppColors.text),
                  ),
                ),
              ),
              _buildStepButton(
                asset: AppIcons.plus,
                semanticLabel: 'Increase $label',
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepButton({
    required String asset,
    required String semanticLabel,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: semanticLabel,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: AppSpacing.x5l,
        height: AppSpacing.x5l,
      ),
      iconSize: 16,
      icon: AppIcon(
        asset: asset,
        color: onPressed == null ? AppColors.line : AppColors.muted,
      ),
    );
  }

  Widget _buildExerciseList() {
    if (_exercises.isEmpty) {
      return _buildEmptyExercises();
    }
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
      itemCount: _exercises.length,
      onReorderItem: _reorderExercises,
      itemBuilder: (context, index) =>
          _buildExerciseCard(index, _exercises[index]),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppBackBar(label: 'Routines', onBack: _requestClose),
        const SizedBox(height: AppSpacing.xl),
        Text(
          _isEditing ? 'Edit routine' : 'New routine',
          style: AppTypography.h1.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: AppSpacing.x2l),
        _buildNameField(),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Add exercise',
          assetIcon: AppIcons.plus,
          variant: AppButtonVariant.ghost,
          onPressed: _exercises.length >= _maxExercises ? null : _addExercises,
        ),
        if (_exercisesError != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _exercisesError!,
            style: AppTypography.caption.copyWith(color: AppColors.orange),
          ),
        ],
        const SizedBox(height: AppSpacing.x2l),
        Expanded(child: _buildExerciseList()),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Save routine',
          onPressed: _saving ? null : _save,
          isLoading: _saving,
        ),
      ],
    );
  }

  Widget _buildScaffold(Widget child) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2l,
            vertical: AppSpacing.xl,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ExerciseProvider>();
    if (!_loaded) {
      return _buildScaffold(
        Column(
          children: <Widget>[
            AppBackBar(label: 'Routines', onBack: _requestClose),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.lime),
              ),
            ),
          ],
        ),
      );
    }
    if (_notFound) {
      return _buildScaffold(
        Column(
          children: <Widget>[
            AppBackBar(label: 'Routines', onBack: _requestClose),
            Expanded(
              child: AppEmptyState(
                assetIcon: AppIcons.search,
                title: 'Routine not found',
                message: 'This routine is no longer saved on this device.',
                actionLabel: 'Back to routines',
                onAction: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      );
    }
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _requestClose();
      },
      child: _buildScaffold(_buildContent()),
    );
  }
}
