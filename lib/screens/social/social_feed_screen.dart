import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/formatters.dart';
import '../../models/activity_post.dart';
import '../../models/personal_record.dart';
import '../../navigation/routes.dart';
import '../../providers/history_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/social_provider.dart';
import '../../services/clock.dart';
import '../../services/share_card_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_tag.dart';
import '../../widgets/kudos_button.dart';
import '../../widgets/share_card_sheet.dart';

/// Local-only social feed with sample posts, own workout posts, and kudos.
class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({
    super.key,
    this.clock,
    this.shareCardService = const ShareCardService(),
  });

  final Clock? clock;
  final ShareCardService shareCardService;

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  DateTime get _now => (widget.clock ?? const SystemClock()).now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final settings = context.read<SettingsProvider>();
    await settings.load();
    if (!mounted) {
      return;
    }
    final social = context.read<SocialProvider>();
    social.setSamplesDismissed(settings.settings.sampleFeedDismissed);
    await social.load();
  }

  Future<void> _hideSamples() async {
    final settings = context.read<SettingsProvider>();
    final social = context.read<SocialProvider>();
    await settings.dismissSampleFeed();
    await social.dismissSamples();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Sample posts hidden.')));
  }

  Future<void> _toggleKudos(ActivityPost post) async {
    final saved = await context.read<SocialProvider>().toggleKudos(post.id);
    if (!mounted || saved) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Could not update kudos.')));
  }

  Future<void> _openPost(ActivityPost post) async {
    final sessionId = post.sessionId;
    if (!post.isOwn || sessionId == null) {
      return;
    }
    await Navigator.of(context)
        .pushNamed(Routes.progressHistoryDetail(sessionId));
  }

  Future<void> _sharePost(ActivityPost post) async {
    final sessionId = post.sessionId;
    if (sessionId == null) {
      return;
    }
    final history = context.read<HistoryProvider>();
    if (history.workouts.isEmpty) {
      await history.load();
    }
    final session = history.byId(sessionId);
    if (!mounted) {
      return;
    }
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This workout is no longer available.')),
      );
      return;
    }
    final progress = context.read<ProgressProvider>();
    PersonalRecord? record;
    for (final item in progress.prs.values) {
      if (item.sessionId == sessionId) {
        record = item;
        break;
      }
    }
    await ShareCardSheet.show(
      context,
      session: session,
      record: record,
      service: widget.shareCardService,
    );
  }

  Widget _buildHeader(SocialProvider social) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Feed',
            style: AppTypography.h1.copyWith(color: AppColors.text),
          ),
        ),
        if (social.hasSamples)
          TextButton(
            key: const Key('hide-samples'),
            onPressed: _hideSamples,
            child: Text(
              'Hide samples',
              style: AppTypography.label.copyWith(color: AppColors.lime),
            ),
          ),
      ],
    );
  }

  Widget _buildLocalNotice() {
    return Row(
      children: <Widget>[
        const AppIcon(asset: AppIcons.lock, size: 14, color: AppColors.muted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Posts and kudos stay on this device.',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(ActivityPost post) {
    final initial = post.authorName.trim().isEmpty
        ? '?'
        : post.authorName.trim()[0].toUpperCase();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: post.isOwn ? AppColors.limeSoft : AppColors.surfaceAlt,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppTypography.title.copyWith(
          color: post.isOwn ? AppColors.lime : AppColors.muted,
        ),
      ),
    );
  }

  Widget _buildPost(ActivityPost post) {
    final canOpen = post.isOwn && post.sessionId != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: canOpen ? () => _openPost(post) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildAvatar(post),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              post.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyStrong.copyWith(
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          if (post.isOwn) ...<Widget>[
                            const SizedBox(width: AppSpacing.sm),
                            const AppTag(
                              label: 'You',
                              variant: AppTagVariant.lime,
                            ),
                          ],
                          if (post.isSample) ...<Widget>[
                            const SizedBox(width: AppSpacing.sm),
                            const AppTag(label: 'Sample'),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        formatRelativeTime(post.createdAt, _now),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                KudosButton(
                  key: Key('kudos-${post.id}'),
                  count: post.kudos,
                  given: post.kudosGiven,
                  onPressed: () => _toggleKudos(post),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              post.text,
              style: AppTypography.body.copyWith(color: AppColors.text),
            ),
            if (canOpen) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  const Spacer(),
                  TextButton(
                    onPressed: () => _openPost(post),
                    child: Text(
                      'View workout',
                      style: AppTypography.label.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  IconButton(
                    key: Key('share-post-${post.id}'),
                    tooltip: 'Share card',
                    icon: const AppIcon(
                      asset: AppIcons.share,
                      size: 18,
                      color: AppColors.lime,
                    ),
                    onPressed: () => _sharePost(post),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      assetIcon: AppIcons.navSocial,
      title: 'Your feed is quiet',
      message: 'Finish a workout to share your first post.',
      actionLabel: 'Start a workout',
      onAction: () => Navigator.of(context).pushReplacementNamed(Routes.today),
    );
  }

  Widget _buildBody(SocialProvider social, SettingsProvider settings) {
    final posts = social.visiblePosts(
      includeOwnPosts: settings.settings.postWorkoutsToFeed,
    );
    if (social.isLoading && posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.lime),
      );
    }
    if (posts.isEmpty) {
      return _buildEmptyState();
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
      children: <Widget>[for (final post in posts) _buildPost(post)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final settings = context.watch<SettingsProvider>();
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
              _buildHeader(social),
              const SizedBox(height: AppSpacing.sm),
              _buildLocalNotice(),
              const SizedBox(height: AppSpacing.x2l),
              Expanded(child: _buildBody(social, settings)),
            ],
          ),
        ),
      ),
    );
  }
}
