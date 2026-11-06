const Object _noChange = Object();

/// Local social feed post.
class ActivityPost {
  const ActivityPost({
    this.schemaVersion = 1,
    required this.id,
    required this.authorName,
    required this.isOwn,
    this.sessionId,
    required this.text,
    required this.createdAt,
    this.kudos = 0,
    this.kudosGiven = false,
    this.isSample = false,
  });

  final int schemaVersion;
  final String id;
  final String authorName;
  final bool isOwn;
  final String? sessionId;
  final String text;
  final DateTime createdAt;
  final int kudos;
  final bool kudosGiven;
  final bool isSample;

  factory ActivityPost.fromJson(Map<String, dynamic> json) {
    return ActivityPost(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      id: json['id'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      isOwn: json['isOwn'] as bool? ?? false,
      sessionId: json['sessionId'] as String?,
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      kudos: (json['kudos'] as num?)?.toInt() ?? 0,
      kudosGiven: json['kudosGiven'] as bool? ?? false,
      isSample: json['isSample'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'authorName': authorName,
      'isOwn': isOwn,
      'sessionId': sessionId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'kudos': kudos,
      'kudosGiven': kudosGiven,
      'isSample': isSample,
    };
  }

  ActivityPost copyWith({
    int? schemaVersion,
    String? id,
    String? authorName,
    bool? isOwn,
    Object? sessionId = _noChange,
    String? text,
    DateTime? createdAt,
    int? kudos,
    bool? kudosGiven,
    bool? isSample,
  }) {
    return ActivityPost(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      isOwn: isOwn ?? this.isOwn,
      sessionId: identical(sessionId, _noChange)
          ? this.sessionId
          : sessionId as String?,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      kudos: kudos ?? this.kudos,
      kudosGiven: kudosGiven ?? this.kudosGiven,
      isSample: isSample ?? this.isSample,
    );
  }
}
