import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mova/providers/progress_photo_provider.dart';
import 'package:mova/screens/progress/progress_photos_screen.dart';
import 'package:mova/services/progress_photo_picker.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

class _FakePicker extends ProgressPhotoPicker {
  _FakePicker(this.bytes);

  final Uint8List bytes;
  int calls = 0;
  ImageSource? lastSource;

  @override
  Future<Uint8List?> pick(ImageSource source) async {
    calls++;
    lastSource = source;
    return bytes;
  }
}

final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
  'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

Widget _wrap(ProgressPhotoProvider provider, ProgressPhotoPicker picker) {
  return ChangeNotifierProvider<ProgressPhotoProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.dark,
      home: ProgressPhotosScreen(picker: picker),
    ),
  );
}

void main() {
  testWidgets('imports a library photo and removes it', (tester) async {
    final storage = StorageService.inMemory();
    final provider = ProgressPhotoProvider(storage);
    final picker = _FakePicker(_pngBytes);

    await tester.pumpWidget(_wrap(provider, picker));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('progress-photos-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('progress-photo-add')));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from library'), findsOneWidget);

    await tester.tap(find.byKey(const Key('progress-photo-source-gallery')));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(picker.lastSource, ImageSource.gallery);
    expect(provider.photos, hasLength(1));
    expect(find.byKey(const Key('progress-photos-grid')), findsOneWidget);
    expect(find.byKey(const Key('progress-photos-empty')), findsNothing);
    final photoId = provider.photos.single.id;
    expect(find.byKey(Key('progress-photo-$photoId')), findsOneWidget);

    await tester.tap(find.byKey(Key('progress-photo-remove-$photoId')));
    await tester.pumpAndSettle();
    expect(find.text('Remove photo?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('progress-photo-remove-confirm')));
    await tester.pumpAndSettle();

    expect(provider.photos, isEmpty);
    expect(find.byKey(const Key('progress-photos-empty')), findsOneWidget);
  });

  testWidgets('camera source is passed to the picker', (tester) async {
    final provider = ProgressPhotoProvider(StorageService.inMemory());
    final picker = _FakePicker(_pngBytes);

    await tester.pumpWidget(_wrap(provider, picker));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('progress-photo-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('progress-photo-source-camera')));
    await tester.pumpAndSettle();

    expect(picker.lastSource, ImageSource.camera);
    expect(provider.photos, hasLength(1));
  });
}
