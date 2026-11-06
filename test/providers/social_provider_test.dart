import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/activity_post.dart';
import 'package:mova/providers/social_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);
final FakeClock _clock = FakeClock(_now);

SocialProvider _provider(StorageService storage) {
  return SocialProvider(storage, SeedDataService(), clock: _clock);
}

void main() {
  test('first load seeds three labeled sample posts', () async {
    final storage = StorageService.inMemory();
    final provider = _provider(storage);

    await provider.load();

    expect(provider.posts, hasLength(3));
    expect(provider.posts.every((post) => post.isSample), isTrue);
    expect(provider.posts.every((post) => !post.isOwn), isTrue);
    expect(provider.hasSamples, isTrue);
    expect(provider.error, isNull);
  });

  test('dismissing samples removes them and persists', () async {
    final storage = StorageService.inMemory();
    final provider = _provider(storage);
    await provider.load();

    expect(await provider.dismissSamples(), isTrue);
    expect(provider.posts, isEmpty);
    expect(provider.hasSamples, isFalse);

    final reloaded = _provider(storage);
    await reloaded.load();
    expect(reloaded.posts, isEmpty);
  });

  test('a dismissed feed does not reseed when the flag is set', () async {
    final storage = StorageService.inMemory();
    final provider = _provider(storage);
    provider.setSamplesDismissed(true);

    await provider.load();

    expect(provider.posts, isEmpty);
    expect(provider.hasSamples, isFalse);
  });

  test('kudos toggles locally and survives a reload', () async {
    final storage = StorageService.inMemory();
    final provider = _provider(storage);
    await provider.load();
    final id = provider.posts.first.id;
    final initial = provider.posts.first.kudos;

    expect(await provider.toggleKudos(id), isTrue);
    expect(provider.posts.first.kudos, initial + 1);
    expect(provider.posts.first.kudosGiven, isTrue);

    final reloaded = _provider(storage);
    await reloaded.load();
    expect(reloaded.posts.first.kudos, initial + 1);
    expect(reloaded.posts.first.kudosGiven, isTrue);

    expect(await reloaded.toggleKudos(id), isTrue);
    expect(reloaded.posts.first.kudos, initial);
    expect(reloaded.posts.first.kudosGiven, isFalse);
  });

  test('kudos on a missing post reports an error and keeps the feed', () async {
    final storage = StorageService.inMemory();
    final provider = _provider(storage);
    await provider.load();

    expect(await provider.toggleKudos('missing'), isFalse);
    expect(provider.error, 'Post not found.');
    expect(provider.posts, hasLength(3));
  });

  test('visible posts hide own posts when sharing is off', () async {
    final storage = StorageService.inMemory();
    final provider = _provider(storage);
    await provider.load();
    await provider.addPost(_ownPost(id: 'own-1', sessionId: 'session-1'));

    expect(provider.visiblePosts(), hasLength(4));
    final filtered = provider.visiblePosts(includeOwnPosts: false);

    expect(filtered, hasLength(3));
    expect(filtered.every((post) => !post.isOwn), isTrue);
  });

  test('removing a session removes only its own post', () async {
    final storage = StorageService.inMemory();
    final provider = _provider(storage);
    await provider.load();
    await provider.addPost(_ownPost(id: 'own-1', sessionId: 'session-1'));
    await provider.addPost(_ownPost(id: 'own-2', sessionId: 'session-2'));

    expect(await provider.removePostForSession('session-1'), isTrue);

    expect(provider.hasPostForSession('session-1'), isFalse);
    expect(provider.hasPostForSession('session-2'), isTrue);
    expect(provider.posts.where((post) => post.isOwn), hasLength(1));
  });

  test('the social payload uses the shared storage key', () async {
    final storage = StorageService.inMemory();
    final provider = _provider(storage);
    await provider.load();

    expect(storage.contains(kSocialKey), isTrue);
  });
}

ActivityPost _ownPost({required String id, required String sessionId}) {
  return ActivityPost(
    id: id,
    authorName: 'Athlete',
    isOwn: true,
    sessionId: sessionId,
    text: 'Completed a workout.',
    createdAt: _now,
  );
}
