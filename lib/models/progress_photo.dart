import 'dart:convert';
import 'dart:typed_data';

/// One progress photo stored locally as a compressed base64 thumbnail.
class ProgressPhoto {
  const ProgressPhoto({
    required this.id,
    required this.takenAt,
    required this.dataBase64,
  });

  final String id;
  final DateTime takenAt;
  final String dataBase64;

  Uint8List get bytes => base64Decode(dataBase64);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': 1,
      'id': id,
      'takenAt': takenAt.toIso8601String(),
      'data': dataBase64,
    };
  }

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final data = json['data']?.toString() ?? '';
    final takenAt = DateTime.tryParse(json['takenAt']?.toString() ?? '');
    if (id.isEmpty || data.isEmpty || takenAt == null) {
      throw const FormatException('Invalid progress photo.');
    }
    return ProgressPhoto(id: id, takenAt: takenAt, dataBase64: data);
  }
}
