import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';

/// Renders one bundled legal document from `assets/legal`.
class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key, required this.documentId});

  final String documentId;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  static const Map<String, String> _titles = <String, String>{
    'privacy': 'Privacy policy',
    'terms': 'Terms of use',
    'help': 'Help and support',
  };

  late Future<String> _content;

  String get _title => _titles[widget.documentId] ?? 'Legal';

  @override
  void initState() {
    super.initState();
    _content = _load();
  }

  Future<String> _load() {
    return rootBundle.loadString('assets/legal/${widget.documentId}.md');
  }

  void _reload() {
    setState(() => _content = _load());
  }

  TextSpan _inline(String text, TextStyle style) {
    final cleaned = text.replaceAll('**', '').replaceAll('__', '');
    return TextSpan(text: cleaned, style: style);
  }

  Widget _buildLine(String line) {
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Text(
          line.substring(2),
          style: AppTypography.h1.copyWith(color: AppColors.text),
        ),
      );
    }
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.xl,
          bottom: AppSpacing.sm,
        ),
        child: Text(
          line.substring(3),
          style: AppTypography.h2.copyWith(color: AppColors.text),
        ),
      );
    }
    if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '•',
              style: AppTypography.body.copyWith(color: AppColors.lime),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text.rich(
                _inline(
                  line.substring(2),
                  AppTypography.body.copyWith(color: AppColors.muted),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text.rich(
        _inline(line, AppTypography.body.copyWith(color: AppColors.muted)),
      ),
    );
  }

  Widget _buildDocument(String content) {
    final lines = content.split('\n');
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x2l,
        AppSpacing.md,
        AppSpacing.x2l,
        AppSpacing.x6l,
      ),
      children: <Widget>[
        for (final line in lines)
          if (line.trim().isEmpty)
            const SizedBox(height: AppSpacing.xs)
          else
            _buildLine(line.trim()),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.description_outlined,
              size: 32,
              color: AppColors.muted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This document could not be loaded.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: _reload, child: const Text('Try again')),
          ],
        ),
      ),
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
                label: _title,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: FutureBuilder<String>(
                future: _content,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return _buildError();
                  }
                  return _buildDocument(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
