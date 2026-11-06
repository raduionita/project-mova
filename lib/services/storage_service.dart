import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Migrates one stored payload from its current version to the next version.
typedef StorageMigration = Map<String, dynamic> Function(
  Map<String, dynamic> json,
);

/// The only class that touches `shared_preferences`.
///
/// Reads never throw. Missing, corrupt, or future-schema payloads return a
/// safe empty value. Corrupt payloads are removed from storage.
class StorageService {
  StorageService._(
    this._preferences, {
    this._migrations = const <StorageMigration>[],
  }) : isPersistent = true;

  StorageService.inMemory({this._migrations = const <StorageMigration>[]})
    : _preferences = null,
      isPersistent = false;

  static Future<StorageService> create({
    List<StorageMigration> migrations = const <StorageMigration>[],
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return StorageService._(preferences, migrations: migrations);
    } catch (error) {
      final storage = StorageService.inMemory(migrations: migrations);
      storage.initializationError = error.toString();
      storage.warning =
          'Local storage could not be opened. Changes may not persist.';
      return storage;
    }
  }

  final SharedPreferences? _preferences;
  final Map<String, String> _memory = <String, String>{};
  final List<StorageMigration> _migrations;

  bool isPersistent;
  String? initializationError;

  /// User-facing warning shown when local data could not be read or written.
  String? warning;

  static const int _supportedSchemaVersion = 1;

  bool contains(String key) => _readRaw(key) != null;

  T? readObject<T>(String key, T Function(Map<String, dynamic> json) fromJson) {
    final raw = _readRaw(key);
    if (raw == null) {
      return null;
    }
    final json = _decodeMap(raw);
    if (json == null) {
      _dropCorrupt(key);
      return null;
    }
    final normalized = _normalizeSchema(json);
    if (normalized == null) {
      return null;
    }
    try {
      return fromJson(normalized);
    } catch (_) {
      _dropCorrupt(key);
      return null;
    }
  }

  List<T> readList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final raw = _readRaw(key);
    if (raw == null) {
      return <T>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _dropCorrupt(key);
        return <T>[];
      }
      final result = <T>[];
      for (final item in decoded) {
        final json = item is Map ? _stringKeyedMap(item) : null;
        final normalized = json == null ? null : _normalizeSchema(json);
        if (normalized == null) {
          continue;
        }
        try {
          result.add(fromJson(normalized));
        } catch (_) {
          continue;
        }
      }
      return result;
    } catch (_) {
      _dropCorrupt(key);
      return <T>[];
    }
  }

  Map<String, T> readMap<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final raw = _readRaw(key);
    if (raw == null) {
      return <String, T>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _dropCorrupt(key);
        return <String, T>{};
      }
      final result = <String, T>{};
      for (final entry in decoded.entries) {
        final json = entry.value is Map ? _stringKeyedMap(entry.value) : null;
        final normalized = json == null ? null : _normalizeSchema(json);
        if (normalized == null) {
          continue;
        }
        try {
          result[entry.key.toString()] = fromJson(normalized);
        } catch (_) {
          continue;
        }
      }
      return result;
    } catch (_) {
      _dropCorrupt(key);
      return <String, T>{};
    }
  }

  Future<bool> writeObject(String key, Map<String, dynamic> value) {
    return _writeRaw(key, jsonEncode(value));
  }

  Future<bool> writeList(String key, List<Map<String, dynamic>> values) {
    return _writeRaw(key, jsonEncode(values));
  }

  Future<bool> writeMap(String key, Map<String, Map<String, dynamic>> values) {
    return _writeRaw(key, jsonEncode(values));
  }

  Future<bool> remove(String key) async {
    try {
      if (_preferences != null) {
        return await _preferences.remove(key);
      }
      _memory.remove(key);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearAll() async {
    try {
      if (_preferences != null) {
        await _preferences.clear();
      } else {
        _memory.clear();
      }
    } catch (_) {
      // Clearing is best effort and must never crash the app.
    }
  }

  Set<String> storedKeys() {
    return _preferences?.getKeys().toSet() ?? _memory.keys.toSet();
  }

  String? _readRaw(String key) {
    return _preferences?.getString(key) ?? _memory[key];
  }

  Future<bool> _writeRaw(String key, String value) async {
    try {
      if (_preferences != null) {
        return await _preferences.setString(key, value);
      }
      _memory[key] = value;
      return true;
    } catch (_) {
      warning = 'Could not save local data.';
      return false;
    }
  }

  void _dropCorrupt(String key) {
    warning = 'Some saved data could not be read and was reset.';
    unawaited(remove(key));
  }

  Map<String, dynamic>? _normalizeSchema(Map<String, dynamic> json) {
    final rawVersion = json['schemaVersion'];
    if (rawVersion == null) {
      return json;
    }
    if (rawVersion is! num) {
      return null;
    }
    var version = rawVersion.toInt();
    if (version < 0 || version > _supportedSchemaVersion) {
      return null;
    }
    var current = Map<String, dynamic>.from(json);
    while (version < _supportedSchemaVersion) {
      if (version >= _migrations.length) {
        return null;
      }
      try {
        current = Map<String, dynamic>.from(_migrations[version](current));
      } catch (_) {
        return null;
      }
      version += 1;
      current['schemaVersion'] = version;
    }
    return current;
  }

  Map<String, dynamic>? _decodeMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return _stringKeyedMap(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> value) {
    return value.map((key, entryValue) => MapEntry(key.toString(), entryValue));
  }
}
