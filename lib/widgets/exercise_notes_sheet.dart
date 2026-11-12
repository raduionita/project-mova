import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Shows a keyboard-safe sheet for one exercise note.
Future<String?> showExerciseNotesSheet(
  BuildContext context, {
  required String exerciseName,
  required String initialNotes,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.panel,
    builder: (_) => ExerciseNotesSheet(
      exerciseName: exerciseName,
      initialNotes: initialNotes,
    ),
  );
}

/// Free-text note attached to one exercise in the live workout.
class ExerciseNotesSheet extends StatefulWidget {
  const ExerciseNotesSheet({
    super.key,
    required this.exerciseName,
    required this.initialNotes,
  });

  final String exerciseName;
  final String initialNotes;

  @override
  State<ExerciseNotesSheet> createState() => _ExerciseNotesSheetState();
}

class _ExerciseNotesSheetState extends State<ExerciseNotesSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialNotes,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
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
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Note · ${widget.exerciseName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h2.copyWith(color: AppColors.text),
                  ),
                ),
                if (widget.initialNotes.isNotEmpty)
                  TextButton(
                    key: const Key('exercise-notes-clear'),
                    onPressed: () {
                      _controller.text = '';
                      setState(() {});
                    },
                    child: Text(
                      'Clear',
                      style: AppTypography.label.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Saved with this exercise in the workout history.',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.x2l),
            TextField(
              key: const Key('exercise-notes-field'),
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              style: AppTypography.body.copyWith(color: AppColors.text),
              decoration: const InputDecoration(
                hintText: 'Anything to remember for next time?',
              ),
            ),
            const SizedBox(height: AppSpacing.x2l),
            AppButton(
              key: const Key('exercise-notes-save'),
              label: 'Save note',
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
