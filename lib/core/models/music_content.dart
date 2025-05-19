enum ContentType { lyrics, tablature, chordChart, sheetMusic }

class MusicContent {
  final String id;
  final String musicId;
  final ContentType type;
  final String contentPath;
  final String? contentText;
  final int version;

  MusicContent({
    required this.id,
    required this.musicId,
    required this.type,
    required this.contentPath,
    this.contentText,
    this.version = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'musicId': musicId,
      'type': type.index,
      'contentPath': contentPath,
      'contentText': contentText, 
      'version': version,
    };
  }

  factory MusicContent.fromMap(Map<String, dynamic> map) {
    return MusicContent(
      id: map['id'],
      musicId: map['musicId'],
      type: ContentType.values[map['type']],
      contentPath: map['contentPath'],
      contentText: map['contentText'],
      version: map['version'],
    );
  }

  MusicContent copyWith({
    String? id,
    String? musicId,
    ContentType? type,
    String? contentPath,
    String? contentText,
    int? version,
  }) {
    return MusicContent(
      id: id ?? this.id,
      musicId: musicId ?? this.musicId,
      type: type ?? this.type,
      contentPath: contentPath ?? this.contentPath,
      contentText: contentText ?? this.contentText,
      version: version ?? this.version,
    );
  }

}