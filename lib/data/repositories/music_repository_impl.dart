import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/data/datasources/database_helper.dart';
import 'package:music_sheet_pro/core/exceptions/app_exception.dart';
import 'package:uuid/uuid.dart';

class MusicRepositoryImpl implements MusicRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _uuid = const Uuid();

  @override
  Future<List<Music>> getAllMusics() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps =
          await db.query('musics', orderBy: 'title ASC');
      return List.generate(maps.length, (i) => Music.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException(
        'Erro ao buscar músicas',
        originalError: e,
      );
    }
  }

  @override
  Future<Music?> getMusicById(String id) async {
    try {
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
    } catch (e) {
      throw DatabaseException(
        'Erro ao buscar música por ID: $id',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Music>> searchMusics(String query) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'musics',
        where: 'title LIKE ? OR artist LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'title ASC',
      );

      return List.generate(maps.length, (i) => Music.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException(
        'Erro ao pesquisar músicas: $query',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Music>> getFavoriteMusics() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'musics',
        where: 'isFavorite = ?',
        whereArgs: [1],
        orderBy: 'title ASC',
      );

      return List.generate(maps.length, (i) => Music.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException(
        'Erro ao buscar músicas favoritas',
        originalError: e,
      );
    }
  }

  @override
  Future<String> addMusic(Music music) async {
    try {
      // ✅ VALIDAÇÃO BÁSICA
      if (music.title.trim().isEmpty) {
        throw ValidationException('Título não pode estar vazio');
      }
      if (music.artist.trim().isEmpty) {
        throw ValidationException('Artista não pode estar vazio');
      }

      final db = await _databaseHelper.database;
      final String id = music.id.isEmpty ? _uuid.v4() : music.id;
      final musicWithId = Music(
        id: id,
        title: music.title.trim(),
        artist: music.artist.trim(),
        tags: music.tags,
        createdAt: music.createdAt,
        updatedAt: music.updatedAt,
        isFavorite: music.isFavorite,
      );

      await db.insert('musics', musicWithId.toMap());
      return id;
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw DatabaseException(
        'Erro ao adicionar música',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateMusic(Music music) async {
    try {
      // ✅ VALIDAÇÃO BÁSICA
      if (music.title.trim().isEmpty) {
        throw ValidationException('Título não pode estar vazio');
      }
      if (music.artist.trim().isEmpty) {
        throw ValidationException('Artista não pode estar vazio');
      }

      final db = await _databaseHelper.database;
      await db.update(
        'musics',
        music.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [music.id],
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw DatabaseException(
        'Erro ao atualizar música',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteMusic(String id) async {
    try {
      final db = await _databaseHelper.database;

      // Primeiro deletar conteúdos relacionados
      await db.delete(
        'music_contents',
        where: 'musicId = ?',
        whereArgs: [id],
      );

      // Depois deletar a música
      await db.delete(
        'musics',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException(
        'Erro ao deletar música',
        originalError: e,
      );
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    try {
      final db = await _databaseHelper.database;
      final music = await getMusicById(id);

      if (music != null) {
        final updatedMusic = music.copyWith(
          isFavorite: !music.isFavorite,
          updatedAt: DateTime.now(),
        );
        await updateMusic(updatedMusic);
      }
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException(
        'Erro ao alternar favorito',
        originalError: e,
      );
    }
  }

  @override
  Future<List<MusicContent>> getContentsForMusic(String musicId) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'music_contents',
        where: 'musicId = ?',
        whereArgs: [musicId],
      );

      return List.generate(maps.length, (i) => MusicContent.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException(
        'Erro ao buscar conteúdos da música',
        originalError: e,
      );
    }
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
      throw DatabaseException(
        'Erro ao adicionar conteúdo',
        originalError: e,
      );
    }
  }

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
      throw DatabaseException(
        'Erro ao atualizar conteúdo',
        originalError: e,
      );
    }
  }

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
      throw DatabaseException(
        'Erro ao deletar conteúdo',
        originalError: e,
      );
    }
  }
}
