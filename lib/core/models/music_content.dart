enum ContentType { lyrics, tablature, chordChart, sheetMusic }

class MusicContent {
  final String id;
  final String musicId;
  final ContentType type;
  final String contentPath;
  final int version;

  MusicContent({
    required this.id,
    required this.musicId,
    required this.type,
    required this.contentPath,
    this.version = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'musicId': musicId,
      'type': type.index,
      'contentPath': contentPath,
      'version': version,
    };
  }

  factory MusicContent.fromMap(Map<String, dynamic> map) {
    return MusicContent(
      id: map['id'],
      musicId: map['musicId'],
      type: ContentType.values[map['type']],
      contentPath: map['contentPath'],
      version: map['version'],
    );
  }
}