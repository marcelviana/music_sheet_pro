import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/core/models/music_filter.dart';
import 'package:music_sheet_pro/core/models/music_stats.dart';

abstract class MusicRepository {
  Future<List<Music>> getAllMusics();
  Future<Music?> getMusicById(String id);
  Future<List<Music>> searchMusics(String query);
  Future<List<Music>> getFavoriteMusics();
  Future<String> addMusic(Music music);
  Future<void> updateMusic(Music music);
  Future<void> deleteMusic(String id);
  Future<void> toggleFavorite(String id);

  Future<List<MusicContent>> getContentsForMusic(String musicId);
  Future<String> addContent(MusicContent content);
  Future<void> updateContent(MusicContent content);
  Future<void> deleteContent(String id);

  /// Get filtered and sorted musics
  Future<List<Music>> getFilteredMusics(MusicFilter filter);

  /// Get all unique tags from all musics
  Future<List<String>> getAllTags();

  /// Get music statistics
  Future<MusicStats> getMusicStats();
}
