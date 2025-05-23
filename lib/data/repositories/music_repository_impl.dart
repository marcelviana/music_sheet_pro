import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/data/datasources/database_helper.dart';
import 'package:uuid/uuid.dart';

class MusicRepositoryImpl implements MusicRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _uuid = const Uuid();

  @override
  Future<List<Music>> getAllMusics() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('musics', orderBy: 'title ASC');
    return List.generate(maps.length, (i) => Music.fromMap(maps[i]));
  }

  @override
  Future<Music?> getMusicById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'musics',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Music.fromMap(maps.first);
  }

  @override
  Future<List<Music>> searchMusics(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'musics',
      where: 'title LIKE ? OR artist LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'title ASC',
    );

    return List.generate(maps.length, (i) => Music.fromMap(maps[i]));
  }

  @override
  Future<List<Music>> getFavoriteMusics() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'musics',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'title ASC',
    );

    return List.generate(maps.length, (i) => Music.fromMap(maps[i]));
  }

  @override
  Future<String> addMusic(Music music) async {
    try {
      final db = await _databaseHelper.database;
      final String id = music.id.isEmpty ? _uuid.v4() : music.id;
      final musicWithId = Music(
        id: id,
        title: music.title,
        artist: music.artist,
        tags: music.tags,
        createdAt: music.createdAt,
        updatedAt: music.updatedAt,
        isFavorite: music.isFavorite,
      );

      await db.insert('musics', musicWithId.toMap());
      return id;
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateMusic(Music music) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        'musics',
        music.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [music.id],
      );
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMusic(String id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'music_contents',
        where: 'musicId = ?',
        whereArgs: [id],
      );
      await db.delete(
        'musics',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    try {
      final db = await _databaseHelper.database;
      final music = await getMusicById(id);

      if (music != null) {
        final updatedMusic = music.copyWith(isFavorite: !music.isFavorite);
        await updateMusic(updatedMusic);
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  @override
  Future<List<MusicContent>> getContentsForMusic(String musicId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'music_contents',
      where: 'musicId = ?',
      whereArgs: [musicId],
    );

    return List.generate(maps.length, (i) => MusicContent.fromMap(maps[i]));
  }

  @override
  Future<String> addContent(MusicContent content) async {
    try {
      final db = await _databaseHelper.database;
      final String id = content.id.isEmpty ? _uuid.v4() : content.id;
      final now = DateTime.now();

      final contentWithId = MusicContent(
        id: id,
        musicId: content.musicId,
        type: content.type,
        contentPath: content.contentPath,
        contentText: content.contentText,
        version: content.version,
        createdAt: now,
        updatedAt: now,
      );

      await db.insert('music_contents', contentWithId.toMap());
      return id;
    } catch (e) {
      print('Error adding content: $e');
      rethrow;
    }
  } //addContent

  @override
  Future<void> updateContent(MusicContent content) async {
    try {
      final db = await _databaseHelper.database;

      final updatedContent = content.copyWith(updatedAt: DateTime.now());

      await db.update(
        'music_contents',
        updatedContent.toMap(),
        where: 'id = ?',
        whereArgs: [content.id],
      );
    } catch (e) {
      print('Error updating content: $e');
      rethrow;
    }
  } //updateContent

  @override
  Future<void> deleteContent(String id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'music_contents',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}
