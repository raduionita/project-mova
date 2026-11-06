import 'package:uuid/uuid.dart';

typedef IdGenerator = String Function();

/// Generates entity IDs. Tests inject a deterministic generator.
class IdService {
  IdService({IdGenerator? generator}) : _generator = generator ?? _uuidV4;

  static const Uuid _uuid = Uuid();

  static String _uuidV4() => _uuid.v4();

  final IdGenerator _generator;

  String next() => _generator();
}
