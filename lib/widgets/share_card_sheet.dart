import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/personal_record.dart';
import '../models/workout_session.dart';
import '../providers/exercise_provider.dart';
import '../providers/settings_provider.dart';
import '../services/share_card_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_icon.dart';

/// Bottom sheet that renders the PR card, previews it, and shares it.
class ShareCardSheet extends StatefulWidget {
  const ShareCardSheet({
    super.key,
    required this.session,
    this.record,
    this.service = const ShareCardService(),
  });

  final WorkoutSession session;
  final PersonalRecord? record;
  final ShareCardService service;

  static Future<void> show(
    BuildContext context, {
    required WorkoutSession session,
    PersonalRecord? record,
    ShareCardService service = const ShareCardService(),
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      builder: (sheetContext) {
        return ShareCardSheet(
          session: session,
          record: record,
          service: service,
        );
      },
    );
  }

  @override
  State<ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<ShareCardSheet> {
  final GlobalKey _shareButtonKey = GlobalKey();

  Uint8List? _bytes;
  String? _error;
  bool _isRendering = true;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _render());
  }

  Future<void> _render() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isRendering = true;
      _error = null;
    });
    final library = context.read<ExerciseProvider>();
    final unit = context
        .read<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;
    try {
      final bytes = await widget.service.render(
        widget.session,
        record: widget.record,
        exerciseName: (exerciseId) => library.byId(exerciseId)?.name ?? '',
        weightUnit: unit,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bytes = bytes;
        _isRendering = false;
        _error = bytes == null ? 'Could not render the card.' : null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRendering = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _share() async {
    final bytes = _bytes;
    if (bytes == null || _isSharing) {
      return;
    }
    setState(() => _isSharing = true);
    final result = await widget.service.share(bytes, origin: _shareOrigin());
    if (!mounted) {
      return;
    }
    setState(() => _isSharing = false);
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share the card: ${result.error}')),
      );
      return;
    }
    if (result.shared) {
      Navigator.of(context).pop();
    }
  }

  /// iPad and macOS anchor the share popover to the button.
  Rect? _shareOrigin() {
    final renderObject = _shareButtonKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }

  Widget _buildPreview() {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.55;
    if (_isRendering) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: const AspectRatio(
          aspectRatio: 9 / 16,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.lime),
          ),
        ),
      );
    }
    if (_error != null || _bytes == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Could not render the share card.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.x2l),
          AppButton(
            label: 'Try again',
            variant: AppButtonVariant.ghost,
            fullWidth: false,
            onPressed: _render,
          ),
        ],
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: AspectRatio(
            aspectRatio:
                ShareCardService.cardWidth / ShareCardService.cardHeight,
            child: Image.memory(
              _bytes!,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              semanticLabel: 'Workout share card preview',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canShare = _bytes != null && !_isRendering && !_isSharing;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x2l,
        AppSpacing.xl,
        AppSpacing.x2l,
        AppSpacing.x2l + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Share card',
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const AppIcon(
                  asset: AppIcons.close,
                  color: AppColors.muted,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPreview(),
          const SizedBox(height: AppSpacing.x2l),
          AppButton(
            key: _shareButtonKey,
            label: 'Share',
            assetIcon: AppIcons.share,
            isLoading: _isSharing,
            onPressed: canShare ? _share : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Done',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
