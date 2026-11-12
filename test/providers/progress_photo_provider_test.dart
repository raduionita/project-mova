import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mova/providers/progress_photo_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/progress_photo_store.dart';
import 'package:mova/services/storage_service.dart';

void main() {
  test('adds, persists, and removes a photo', () async {
    final storage = StorageService.inMemory();
    var nextId = 0;
    final provider = ProgressPhotoProvider(
      storage,
      clock: FakeClock(DateTime(2026, 11, 6, 9)),
      ids: IdService(generator: () => 'photo-${nextId++}'),
    );

    final added = await provider.add(Uint8List.fromList(<int>[1, 2, 3]));
    expect(added, isTrue);
    expect(provider.photos.single.id, 'photo-0');
    expect(provider.photos.single.takenAt, DateTime(2026, 11, 6, 9));

    final reloaded = ProgressPhotoProvider(
      storage,
      clock: FakeClock(DateTime(2026, 11, 6, 9)),
    );
    await reloaded.load();
    expect(reloaded.photos.single.dataBase64, 'AQID');

    final removed = await reloaded.remove('photo-0');
    expect(removed, isTrue);
    expect(reloaded.photos, isEmpty);

    final empty = ProgressPhotoProvider(storage);
    await empty.load();
    expect(empty.photos, isEmpty);
  });

  test('rejects oversized photos and caps the gallery at twelve', () async {
    final provider = ProgressPhotoProvider(
      StorageService.inMemory(),
      clock: FakeClock(DateTime(2026, 11, 6, 9)),
    );

    final tooLarge = await provider.add(
      Uint8List(ProgressPhotoStore.maxBytes + 1),
    );
    expect(tooLarge, isFalse);
    expect(provider.error, 'That photo is too large. Try a smaller image.');

    for (var index = 0; index < ProgressPhotoStore.maxPhotos; index++) {
      final added = await provider.add(
        Uint8List.fromList(<int>[index]),
      );
      expect(added, isTrue);
    }
    expect(provider.isFull, isTrue);
    expect(provider.remaining, 0);

    final overflow = await provider.add(Uint8List.fromList(<int>[99]));
    expect(overflow, isFalse);
    expect(provider.photos, hasLength(ProgressPhotoStore.maxPhotos));
    expect(
      provider.error,
      'You can keep up to ${ProgressPhotoStore.maxPhotos} photos.',
    );
  });
}
