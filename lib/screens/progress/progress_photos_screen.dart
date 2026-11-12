import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../common/formatters.dart';
import '../../models/progress_photo.dart';
import '../../providers/progress_photo_provider.dart';
import '../../services/progress_photo_picker.dart';
import '../../services/progress_photo_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_icon.dart';

/// Local progress photo gallery with camera and library import.
class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({
    super.key,
    this.picker = const DeviceProgressPhotoPicker(),
  });

  final ProgressPhotoPicker picker;

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final photos = context.read<ProgressPhotoProvider>();
    if (photos.photos.isEmpty && !photos.isLoading) {
      await photos.load();
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addPhoto() async {
    final provider = context.read<ProgressPhotoProvider>();
    if (provider.isFull) {
      _showMessage(
        'You can keep up to ${ProgressPhotoStore.maxPhotos} photos.',
      );
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.panel,
      builder: (sheetContext) {
        return SafeArea(
          key: const Key('progress-photo-source-sheet'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x2l,
              AppSpacing.x2l,
              AppSpacing.x2l,
              AppSpacing.x2l,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Add progress photo',
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  key: const Key('progress-photo-source-camera'),
                  label: 'Take photo',
                  assetIcon: AppIcons.plus,
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  key: const Key('progress-photo-source-gallery'),
                  label: 'Choose from library',
                  variant: AppButtonVariant.ghost,
                  assetIcon: AppIcons.document,
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null) {
      return;
    }
    Uint8List? bytes;
    try {
      bytes = await widget.picker.pick(source);
    } catch (_) {
      _showMessage(
        'Could not open the photo picker. Check photo permissions and try again.',
      );
      return;
    }
    if (bytes == null || !mounted) {
      return;
    }
    final added = await provider.add(bytes);
    if (!mounted) {
      return;
    }
    if (!added) {
      _showMessage(provider.error ?? 'Could not add the photo.');
    }
  }

  Future<void> _confirmRemove(ProgressPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: Text(
            'Remove photo?',
            style: AppTypography.h2.copyWith(color: AppColors.text),
          ),
          content: Text(
            'This photo is stored only on this device and cannot be recovered.',
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          actions: <Widget>[
            TextButton(
              key: const Key('progress-photo-remove-cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const Key('progress-photo-remove-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Remove',
                style: const TextStyle(color: AppColors.orange),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final provider = context.read<ProgressPhotoProvider>();
    final removed = await provider.remove(photo.id);
    if (!removed) {
      _showMessage(provider.error ?? 'Could not remove the photo.');
    }
  }

  Future<void> _viewPhoto(ProgressPhoto photo) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.panel,
          insetPadding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Image.memory(photo.bytes, fit: BoxFit.contain),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        formatDetailDate(photo.takenAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoTile(ProgressPhoto photo) {
    return ClipRRect(
      key: Key('progress-photo-${photo.id}'),
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Material(
        color: AppColors.card,
        child: InkWell(
          onTap: () => _viewPhoto(photo),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.memory(
                photo.bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0x99000000),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppSpacing.md),
                    ),
                  ),
                  child: IconButton(
                    key: Key('progress-photo-remove-${photo.id}'),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove photo',
                    onPressed: () => _confirmRemove(photo),
                    icon: const AppIcon(
                      asset: AppIcons.trash,
                      size: 16,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: const Color(0x99000000),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    formatShortDate(photo.takenAt),
                    style: AppTypography.micro.copyWith(color: AppColors.text),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGallery(ProgressPhotoProvider photos) {
    if (photos.isLoading && photos.photos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.lime),
      );
    }
    if (photos.photos.isEmpty) {
      return Center(
        child: AppEmptyState(
          key: const Key('progress-photos-empty'),
          assetIcon: AppIcons.document,
          title: 'No photos yet',
          message:
              'Keep progress photos on this device. Up to '
              '${ProgressPhotoStore.maxPhotos} photos.',
          actionLabel: 'Add photo',
          onAction: _addPhoto,
        ),
      );
    }
    return GridView.builder(
      key: const Key('progress-photos-grid'),
      padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.82,
      ),
      itemCount: photos.photos.length,
      itemBuilder: (context, index) => _buildPhotoTile(photos.photos[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = context.watch<ProgressPhotoProvider>();
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
              const AppBackBar(label: 'Progress'),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Progress photos',
                      style: AppTypography.h1.copyWith(color: AppColors.text),
                    ),
                  ),
                  IconButton(
                    key: const Key('progress-photo-add'),
                    onPressed: _addPhoto,
                    tooltip: 'Add photo',
                    icon: const AppIcon(
                      asset: AppIcons.plus,
                      size: 22,
                      color: AppColors.lime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Stored only on this device. ${photos.remaining} of '
                '${ProgressPhotoStore.maxPhotos} spots left.',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _buildGallery(photos)),
            ],
          ),
        ),
      ),
    );
  }
}
