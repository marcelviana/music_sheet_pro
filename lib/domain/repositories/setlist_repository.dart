import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/setlist.dart';

abstract class SetlistRepository {
  Future<List<Setlist>> getAllSetlists();
  Future<Setlist?> getSetlistById(String id);
  Future<List<Music>> getMusicsInSetlist(String setlistId);
  Future<String> addSetlist(Setlist setlist);
  Future<void> updateSetlist(Setlist setlist);
  Future<void> deleteSetlist(String id);
  Future<void> addMusicToSetlist(String setlistId, String musicId, int orderIndex);
  Future<void> removeMusicFromSetlist(String setlistId, String musicId);
  Future<void> reorderSetlistMusics(String setlistId, List<String> musicIds);
}