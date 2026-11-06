import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _profileJson({String id = 'profile-1'}) {
  return UserProfile(
    id: id,
    displayName: 'Radu',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  ).toJson();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('persistent mode', () {
    test('write, read, contains, and remove object', () async {
      final storage = await StorageService.create();
      expect(storage.isPersistent, isTrue);
      expect(storage.initializationError, isNull);

      expect(await storage.writeObject('profile', _profileJson()), isTrue);
      expect(storage.contains('profile'), isTrue);

      final profile = storage.readObject('profile', UserProfile.fromJson);
      expect(profile, isNotNull);
      expect(profile!.id, 'profile-1');

      expect(await storage.remove('profile'), isTrue);
      expect(storage.contains('profile'), isFalse);
      expect(storage.readObject('profile', UserProfile.fromJson), isNull);
    });

    test('readList reads every valid entry', () async {
      final storage = await StorageService.create();
      await storage.writeList('profiles', <Map<String, dynamic>>[
        _profileJson(id: 'a'),
        _profileJson(id: 'b'),
      ]);

      final profiles = storage.readList('profiles', UserProfile.fromJson);
      expect(profiles.map((profile) => profile.id), <String>['a', 'b']);
    });

    test('readMap reads every valid entry keyed by storage key', () async {
      final storage = await StorageService.create();
      await storage.writeMap('profiles', <String, Map<String, dynamic>>{
        'a': _profileJson(id: 'a'),
        'b': _profileJson(id: 'b'),
      });

      final profiles = storage.readMap('profiles', UserProfile.fromJson);
      expect(profiles.keys, <String>['a', 'b']);
      expect(profiles['a']!.id, 'a');
    });

    test('corrupt payload returns null and is removed', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('profile', '{not json');

      final storage = await StorageService.create();
      expect(storage.readObject('profile', UserProfile.fromJson), isNull);
      expect(storage.warning, isNotNull);
      await pumpEventQueue();
      expect(storage.contains('profile'), isFalse);
    });

    test('future schema payload returns null and is kept', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'profile',
        jsonEncode(<String, dynamic>{'schemaVersion': 2, 'id': 'future'}),
      );

      final storage = await StorageService.create();
      expect(storage.readObject('profile', UserProfile.fromJson), isNull);
      expect(storage.contains('profile'), isTrue);
    });

    test('migrates a v0 payload to the current schema', () async {
      final storage = StorageService.inMemory(
        migrations: <StorageMigration>[
          (json) {
            final next = Map<String, dynamic>.from(json);
            next['displayName'] = next.remove('name');
            return next;
          },
        ],
      );
      await storage.writeObject('profile', <String, dynamic>{
        'schemaVersion': 0,
        'id': 'legacy-1',
        'name': 'Legacy lifter',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
      });

      final profile = storage.readObject('profile', UserProfile.fromJson);
      expect(profile, isNotNull);
      expect(profile!.id, 'legacy-1');
      expect(profile.displayName, 'Legacy lifter');
    });

    test('a legacy payload without a migration is ignored and kept', () async {
      final storage = StorageService.inMemory();
      await storage.writeObject('profile', <String, dynamic>{
        'schemaVersion': 0,
        'id': 'legacy-1',
      });

      expect(storage.readObject('profile', UserProfile.fromJson), isNull);
      expect(storage.contains('profile'), isTrue);
    });

    test('migrations apply to each list and map entry', () async {
      final storage = StorageService.inMemory(
        migrations: <StorageMigration>[
          (json) {
            final next = Map<String, dynamic>.from(json);
            next['displayName'] = next.remove('name');
            return next;
          },
        ],
      );
      await storage.writeList('profiles', <Map<String, dynamic>>[
        <String, dynamic>{
          'schemaVersion': 0,
          'id': 'legacy-a',
          'name': 'Legacy A',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
        },
        _profileJson(id: 'current-b'),
      ]);
      await storage.writeMap('profileMap', <String, Map<String, dynamic>>{
        'legacy': <String, dynamic>{
          'schemaVersion': 0,
          'id': 'legacy-c',
          'name': 'Legacy C',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
        },
      });

      final profiles = storage.readList('profiles', UserProfile.fromJson);
      expect(profiles.map((profile) => profile.id), <String>[
        'legacy-a',
        'current-b',
      ]);
      expect(profiles.first.displayName, 'Legacy A');

      final profileMap = storage.readMap('profileMap', UserProfile.fromJson);
      expect(profileMap['legacy']!.displayName, 'Legacy C');
    });

    test('clearAll removes every stored key', () async {
      final storage = await StorageService.create();
      await storage.writeObject('profile', _profileJson());
      await storage.writeList('profiles', <Map<String, dynamic>>[
        _profileJson(),
      ]);

      await storage.clearAll();
      expect(storage.storedKeys(), isEmpty);
    });

    test('storedKeys lists persisted keys', () async {
      final storage = await StorageService.create();
      await storage.writeObject('profile', _profileJson());
      await storage.writeList('profiles', <Map<String, dynamic>>[
        _profileJson(),
      ]);

      expect(storage.storedKeys(), <String>{'profile', 'profiles'});
    });
  });

  group('in-memory mode', () {
    test('writes and reads without touching persistent storage', () async {
      final storage = StorageService.inMemory();
      expect(storage.isPersistent, isFalse);

      expect(await storage.writeObject('profile', _profileJson()), isTrue);
      expect(
        storage.readObject('profile', UserProfile.fromJson)!.id,
        'profile-1',
      );
      expect(storage.storedKeys(), <String>{'profile'});

      expect(await storage.remove('profile'), isTrue);
      expect(storage.storedKeys(), isEmpty);
    });

    test('clearAll empties the memory map', () async {
      final storage = StorageService.inMemory();
      await storage.writeList('profiles', <Map<String, dynamic>>[
        _profileJson(),
      ]);

      await storage.clearAll();
      expect(storage.storedKeys(), isEmpty);
      expect(storage.readList('profiles', UserProfile.fromJson), isEmpty);
    });
  });

  test('missing keys return safe empty values', () async {
    final storage = StorageService.inMemory();

    expect(storage.readObject('missing', UserProfile.fromJson), isNull);
    expect(storage.readList('missing', UserProfile.fromJson), isEmpty);
    expect(storage.readMap('missing', UserProfile.fromJson), isEmpty);
    expect(storage.contains('missing'), isFalse);
  });

  test('future-schema list entries are skipped, not dropped', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'profiles',
      jsonEncode(<Map<String, dynamic>>[
        _profileJson(id: 'valid'),
        <String, dynamic>{'schemaVersion': 3, 'id': 'future'},
      ]),
    );

    final persistent = await StorageService.create();
    expect(
      persistent.readList('profiles', UserProfile.fromJson).map((p) => p.id),
      <String>['valid'],
    );
    expect(persistent.contains('profiles'), isTrue);
  });
}
