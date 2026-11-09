import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/routes.dart';
import '../../providers/routine_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/routine_row.dart';

/// Saves and opens user routines from DESIGN.md section 10.9.
class RoutineListScreen extends StatefulWidget {
  const RoutineListScreen({super.key});

  @override
  State<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final provider = context.read<RoutineProvider>();
    if (provider.routines.isEmpty && !provider.isLoading) {
      await provider.load();
    }
  }

  Widget _buildHeader(int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Routines',
                style: AppTypography.h1.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                count == 1 ? '1 saved routine' : '$count saved routines',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed(Routes.routineNew),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.lime,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, AppSpacing.x5l),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'New routine',
            style: AppTypography.label.copyWith(color: AppColors.lime),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(RoutineProvider provider) {
    if (provider.isLoading && provider.routines.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.lime),
      );
    }
    if (provider.error != null && provider.routines.isEmpty) {
      return AppEmptyState(
        assetIcon: AppIcons.alert,
        title: 'Could not load routines',
        message: 'Your saved routines could not be read.',
        actionLabel: 'Try again',
        onAction: provider.load,
      );
    }
    if (provider.routines.isEmpty) {
      return AppEmptyState(
        assetIcon: AppIcons.repeat,
        title: 'No routines yet',
        message: 'Saved routines will appear here for one-tap starts.',
        actionLabel: 'Create routine',
        onAction: () => Navigator.of(context).pushNamed(Routes.routineNew),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
      itemCount: provider.routines.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final routine = provider.routines[index];
        return RoutineRow(
          routine: routine,
          onTap: () =>
              Navigator.of(context).pushNamed(Routes.routineDetail(routine.id)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2l,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppBackBar(label: 'Train'),
              const SizedBox(height: AppSpacing.sm),
              _buildHeader(provider.routines.length),
              const SizedBox(height: AppSpacing.x2l),
              Expanded(child: _buildBody(provider)),
            ],
          ),
        ),
      ),
    );
  }
}
