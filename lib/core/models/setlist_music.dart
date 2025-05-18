class SetlistMusic {
  final String setlistId;
  final String musicId;
  final int orderIndex;

  SetlistMusic({
    required this.setlistId,
    required this.musicId,
    required this.orderIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'setlistId': setlistId,
      'musicId': musicId,
      'orderIndex': orderIndex,
    };
  }

  factory SetlistMusic.fromMap(Map<String, dynamic> map) {
    return SetlistMusic(
      setlistId: map['setlistId'],
      musicId: map['musicId'],
      orderIndex: map['orderIndex'],
    );
  }
}