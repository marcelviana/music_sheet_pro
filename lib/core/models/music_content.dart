enum ContentType {
  lyrics, // Letras simples - index 0
  chordChart, // Cifras/acordes - index 1
  tablature, // Tablaturas - index 2
  sheetMusic // Partituras (PDF/Imagem) - index 3
}

class MusicContent {
  final String id;
  final String musicId;
  final ContentType type;
  final String? contentPath; // Para arquivos (PDF, imagens)
  final String? contentText; // Para texto (letras, cifras)
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  MusicContent({
    required this.id,
    required this.musicId,
    required this.type,
    this.contentPath,
    this.contentText,
    this.version = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'musicId': musicId,
      'type': type.index,
      'contentPath': contentPath,
      'contentText': contentText,
      'version': version,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory MusicContent.fromMap(Map<String, dynamic> map) {
    return MusicContent(
      id: map['id'],
      musicId: map['musicId'],
      type: ContentType.values[map['type']],
      contentPath: map['contentPath'],
      contentText: map['contentText'],
      version: map['version'] ?? 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  MusicContent copyWith({
    String? id,
    String? musicId,
    ContentType? type,
    String? contentPath,
    String? contentText,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MusicContent(
      id: id ?? this.id,
      musicId: musicId ?? this.musicId,
      type: type ?? this.type,
      contentPath: contentPath ?? this.contentPath,
      contentText: contentText ?? this.contentText,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
