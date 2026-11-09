import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

enum AppButtonVariant { primary, ghost, destructive }

/// Full-width action button with primary, ghost, destructive, loading and
/// disabled states from DESIGN.md section 8.1.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.assetIcon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  /// SVG asset alternative to [icon], used after the icon migration.
  final String? assetIcon;
  final bool fullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  Color get _background {
    if (!_enabled && widget.variant == AppButtonVariant.primary) {
      return AppColors.limeDisabled30;
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.lime;
      case AppButtonVariant.ghost:
      case AppButtonVariant.destructive:
        return Colors.transparent;
    }
  }

  Color get _foreground {
    if (!_enabled && widget.variant == AppButtonVariant.primary) {
      return AppColors.limeInkDisabled50;
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.limeInk;
      case AppButtonVariant.ghost:
        return AppColors.text;
      case AppButtonVariant.destructive:
        return AppColors.orange;
    }
  }

  BorderSide? get _border {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return null;
      case AppButtonVariant.ghost:
        return const BorderSide(color: AppColors.line);
      case AppButtonVariant.destructive:
        return BorderSide(color: AppColors.orangeBorder50);
    }
  }

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: _foreground),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.assetIcon != null) ...<Widget>[
          AppIcon(asset: widget.assetIcon!, size: 18, color: _foreground),
          const SizedBox(width: AppSpacing.md),
        ] else if (widget.icon != null) ...<Widget>[
          Icon(widget.icon, size: 18, color: _foreground),
          const SizedBox(width: AppSpacing.md),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              color: _foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadii.xl);
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      onTap: _enabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedOpacity(
            opacity: _pressed ? 0.9 : 1,
            duration: const Duration(milliseconds: 120),
            child: Material(
              color: _background,
              shape: RoundedRectangleBorder(
                borderRadius: borderRadius,
                side: _border ?? BorderSide.none,
              ),
              child: InkWell(
                borderRadius: borderRadius,
                onTap: _enabled ? widget.onPressed : null,
                onTapDown: _enabled ? (_) => _setPressed(true) : null,
                onTapUp: _enabled ? (_) => _setPressed(false) : null,
                onTapCancel: _enabled ? () => _setPressed(false) : null,
                child: SizedBox(
                  height: 48,
                  width: widget.fullWidth ? double.infinity : null,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
