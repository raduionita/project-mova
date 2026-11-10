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
    this.assetIcon,
  });

  final T value;
  final String label;
  final String? description;
  final IconData? icon;
  final String? assetIcon;
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
    this.showPrimaryTag = true,
    this.labelStyle,
    this.descriptionStyle,
    this.iconSize = 17,
    this.iconBoxSize = 32,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl + AppSpacing.xxs,
      vertical: AppSpacing.xl,
    ),
    this.spacing = AppSpacing.md,
  });

  final List<AppMultiSelectOption<T>> options;
  final List<T> selected;
  final ValueChanged<List<T>> onChanged;
  final bool enabled;
  final bool showPrimaryTag;
  final TextStyle? labelStyle;
  final TextStyle? descriptionStyle;
  final double iconSize;
  final double iconBoxSize;
  final EdgeInsetsGeometry contentPadding;
  final double spacing;

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
          if (index > 0) SizedBox(height: spacing),
          AppChoiceCard(
            label: options[index].label,
            description: options[index].description,
            icon: options[index].icon,
            assetIcon: options[index].assetIcon,
            selected: selected.contains(options[index].value),
            onTap: enabled ? () => _toggle(options[index].value) : null,
            labelStyle: labelStyle,
            descriptionStyle: descriptionStyle,
            iconSize: iconSize,
            iconBoxSize: iconBoxSize,
            contentPadding: contentPadding,
            trailing:
                showPrimaryTag &&
                    selected.isNotEmpty &&
                    selected.first == options[index].value
                ? const AppTag(label: 'Primary', variant: AppTagVariant.lime)
                : null,
          ),
        ],
      ],
    );
  }
}
