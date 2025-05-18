import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/setlist.dart';
import 'package:music_sheet_pro/core/models/setlist_music.dart';
import 'package:music_sheet_pro/data/datasources/database_helper.dart';
import 'package:music_sheet_pro/domain/repositories/setlist_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

class SetlistRepositoryImpl implements SetlistRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _uuid = const Uuid();

  @override
  Future<List<Setlist>> getAllSetlists() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('setlists', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Setlist.fromMap(maps[i]));
  }

  @override
  Future<Setlist?> getSetlistById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'setlists',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Setlist.fromMap(maps.first);
  }

  @override
  Future<List<Music>> getMusicsInSetlist(String setlistId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT m.* FROM musics m
      INNER JOIN setlist_music sm ON m.id = sm.musicId
      WHERE sm.setlistId = ?
      ORDER BY sm.orderIndex ASC
    ''', [setlistId]);

    return List.generate(maps.length, (i) => Music.fromMap(maps[i]));
  }

  @override
  Future<String> addSetlist(Setlist setlist) async {
    final db = await _databaseHelper.database;
    final String id = setlist.id.isEmpty ? _uuid.v4() : setlist.id;
    final setlistWithId = Setlist(
      id: id,
      name: setlist.name,
      description: setlist.description,
      createdAt: setlist.createdAt,
      updatedAt: setlist.updatedAt,
    );

    await db.insert('setlists', setlistWithId.toMap());
    return id;
  }

  @override
  Future<void> updateSetlist(Setlist setlist) async {
    final db = await _databaseHelper.database;
    await db.update(
      'setlists',
      setlist.toMap(),
      where: 'id = ?',
      whereArgs: [setlist.id],
    );
  }

  @override
  Future<void> deleteSetlist(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'setlists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> addMusicToSetlist(String setlistId, String musicId, int orderIndex) async {
    final db = await _databaseHelper.database;
    final setlistMusic = SetlistMusic(
      setlistId: setlistId,
      musicId: musicId,
      orderIndex: orderIndex,
    );

    await db.insert(
      'setlist_music',
      setlistMusic.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeMusicFromSetlist(String setlistId, String musicId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'setlist_music',
      where: 'setlistId = ? AND musicId = ?',
      whereArgs: [setlistId, musicId],
    );
  }

  @override
  Future<void> reorderSetlistMusics(String setlistId, List<String> musicIds) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      for (int i = 0; i < musicIds.length; i++) {
        await txn.update(
          'setlist_music',
          {'orderIndex': i},
          where: 'setlistId = ? AND musicId = ?',
          whereArgs: [setlistId, musicIds[i]],
        );
      }
    });
  }
}