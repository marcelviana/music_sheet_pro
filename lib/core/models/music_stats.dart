import 'package:music_sheet_pro/core/models/music_content.dart';

class MusicStats {
  final int totalMusics;
  final int totalFavorites;
  final int musicsWithContent;
  final int totalContents;
  final Map<ContentType, int> contentTypeCount;
  final List<String> mostUsedTags;

  const MusicStats({
    required this.totalMusics,
    required this.totalFavorites,
    required this.musicsWithContent,
    required this.totalContents,
    required this.contentTypeCount,
    required this.mostUsedTags,
  });
}
