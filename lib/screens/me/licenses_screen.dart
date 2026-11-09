import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_empty_state.dart';

/// Lists the open-source packages bundled with Mova and their licenses.
class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key, this.licenses});

  /// Optional stream for tests. Defaults to [LicenseRegistry.licenses].
  final Stream<LicenseEntry>? licenses;

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  late final Future<List<LicenseEntry>> _licenses = _collect();

  Future<List<LicenseEntry>> _collect() {
    return (widget.licenses ?? LicenseRegistry.licenses).toList();
  }

  Map<String, List<LicenseEntry>> _group(List<LicenseEntry> entries) {
    final grouped = <String, List<LicenseEntry>>{};
    for (final entry in entries) {
      for (final package in entry.packages) {
        grouped.putIfAbsent(package, () => <LicenseEntry>[]).add(entry);
      }
      if (entry.packages.isEmpty) {
        grouped.putIfAbsent('Mova', () => <LicenseEntry>[]).add(entry);
      }
    }
    final names = grouped.keys.toList()..sort();
    return <String, List<LicenseEntry>>{
      for (final name in names) name: grouped[name]!,
    };
  }

  Widget _buildPackage(String name, List<LicenseEntry> entries) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          0,
          AppSpacing.xs,
          AppSpacing.md,
        ),
        iconColor: AppColors.muted,
        collapsedIconColor: AppColors.muted,
        title: Text(
          name,
          style: AppTypography.body.copyWith(color: AppColors.text),
        ),
        children: <Widget>[
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                entry.paragraphs.map((p) => p.text).join('\n\n'),
                style: AppTypography.caption.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(List<LicenseEntry> entries) {
    final grouped = _group(entries);
    if (grouped.isEmpty) {
      return const AppEmptyState(
        assetIcon: AppIcons.code,
        title: 'No licenses found',
        message: 'Package licenses appear here after a release build.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x2l,
        AppSpacing.md,
        AppSpacing.x2l,
        AppSpacing.x6l,
      ),
      children: <Widget>[
        for (final entry in grouped.entries)
          _buildPackage(entry.key, entry.value),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
              child: AppBackBar(
                label: 'Settings',
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x2l,
                AppSpacing.md,
                AppSpacing.x2l,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Open-source licenses',
                    style: AppTypography.h1.copyWith(color: AppColors.text),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Mova is built with Flutter and the packages below. '
                    'Tap a package to read its license.',
                    style: AppTypography.body.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<LicenseEntry>>(
                future: _licenses,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return _buildList(snapshot.data ?? const <LicenseEntry>[]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
