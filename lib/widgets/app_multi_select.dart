import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_choice_card.dart';
import 'app_tag.dart';

/// One option in an [AppMultiSelect].
class AppMultiSelectOption<T> {
  const AppMultiSelectOption({
    required this.value,
    required this.label,
    this.description,
    this.icon,
  });

  final T value;
  final String label;
  final String? description;
  final IconData? icon;
}

/// Ordered multi-select list. The first selected option is the primary one
/// and is labelled as such.
class AppMultiSelect<T> extends StatelessWidget {
  const AppMultiSelect({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final List<AppMultiSelectOption<T>> options;
  final List<T> selected;
  final ValueChanged<List<T>> onChanged;
  final bool enabled;

  void _toggle(T value) {
    final next = <T>[...selected];
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (var index = 0; index < options.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          AppChoiceCard(
            label: options[index].label,
            description: options[index].description,
            icon: options[index].icon,
            selected: selected.contains(options[index].value),
            onTap: enabled ? () => _toggle(options[index].value) : null,
            trailing:
                selected.isNotEmpty && selected.first == options[index].value
                ? const AppTag(label: 'Primary', variant: AppTagVariant.lime)
                : null,
          ),
        ],
      ],
    );
  }
}
