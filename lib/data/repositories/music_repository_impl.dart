// 📁 lib/data/repositories/music_repository_impl.dart
// 🎯 Repositório de Música Refatorado
// ✅ Com validações, cache e tratamento de erros robusto
// 📅 2025-05-23
// 👤 MusicSheet Pro Team
// 🔢 v2.0.0

import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/data/datasources/database_helper.dart';
import 'package:music_sheet_pro/core/exceptions/app_exception.dart';
import 'package:music_sheet_pro/core/validation/validators.dart';
import 'package:music_sheet_pro/core/cache/cache_service.dart';
import 'package:music_sheet_pro/core/utils/logger.dart';
import 'package:uuid/uuid.dart';

class MusicRepositoryImpl implements MusicRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _uuid = const Uuid();

  // Cache instances
  static final CacheService _cache = CacheService();
  static bool _cacheInitialized = false;

  /// Inicializa o cache se necessário
  Future<void> _ensureCacheInitialized() async {
    if (!_cacheInitialized) {
      await _cache.initialize();
      _cacheInitialized = true;
    }
  }

  @override
  Future<List<Music>> getAllMusics() async {
    const String cacheKey = 'all_musics';

    try {
      await _ensureCacheInitialized();

      // Tentar buscar do cache primeiro
      final cachedMusics = await _cache.get<List<Music>>(cacheKey);
      if (cachedMusics != null) {
        Logger.debug('Retrieved musics from cache');
        return cachedMusics;
      }

      // Buscar do banco de dados
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps =
          await db.query('musics', orderBy: 'title ASC');

      final musics = List.generate(maps.length, (i) => Music.fromMap(maps[i]));

      // Armazenar no cache
      await _cache.set(cacheKey, musics, ttl: const Duration(minutes: 15));

      Logger.info('Retrieved ${musics.length} musics from database');
      return musics;
    } catch (e, stackTrace) {
      Logger.error('Failed to get all musics', e, stackTrace);
      throw DatabaseException(
        'Erro ao buscar músicas',
        originalError: e,
      );
    }
  }

  @override
  Future<Music?> getMusicById(String id) async {
    if (id.trim().isEmpty) {
      throw ValidationException('ID da música não pode estar vazio');
    }

    final String cacheKey = 'music_$id';

    try {
      await _ensureCacheInitialized();

      // Tentar buscar do cache primeiro
      final cachedMusic = await _cache.get<Music>(cacheKey);
      if (cachedMusic != null) {
        Logger.debug('Retrieved music from cache: $id');
        return cachedMusic;
      }

      // Buscar do banco
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'musics',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        Logger.debug('Music not found: $id');
        return null;
      }

      final music = Music.fromMap(maps.first);

      // Armazenar no cache
      await _cache.set(cacheKey, music, ttl: const Duration(hours: 1));

      Logger.debug('Retrieved music from database: $id');
      return music;
    } catch (e, stackTrace) {
      Logger.error('Failed to get music by ID: $id', e, stackTrace);
      throw DatabaseException(
        'Erro ao buscar música por ID: $id',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Music>> searchMusics(String query) async {
    if (query.trim().isEmpty) {
      return await getAllMusics();
    }

    final String cacheKey = 'search_${query.toLowerCase().trim()}';

    try {
      await _ensureCacheInitialized();

      // Tentar buscar do cache primeiro (cache mais curto para buscas)
      final cachedResults = await _cache.get<List<Music>>(cacheKey);
      if (cachedResults != null) {
        Logger.debug('Retrieved search results from cache: $query');
        return cachedResults;
      }

      final db = await _databaseHelper.database;
      final trimmedQuery = query.trim();

      final List<Map<String, dynamic>> maps = await db.query(
        'musics',
        where: 'title LIKE ? OR artist LIKE ? OR tags LIKE ?',
        orderBy: '''
          CASE 
            WHEN title LIKE ? THEN 1
            WHEN artist LIKE ? THEN 2
            ELSE 3
          END,
          title ASC
        ''',
        whereArgs: [
          '%$trimmedQuery%', '%$trimmedQuery%', '%$trimmedQuery%',
          '$trimmedQuery%', '$trimmedQuery%' // Para ordenação por relevância
        ],
      );

      final results = List.generate(maps.length, (i) => Music.fromMap(maps[i]));

      // Cache por menos tempo (buscas mudam mais frequentemente)
      await _cache.set(cacheKey, results, ttl: const Duration(minutes: 5));

      Logger.info('Search completed: "$query" -> ${results.length} results');
      return results;
    } catch (e, stackTrace) {
      Logger.error('Failed to search musics: $query', e, stackTrace);
      throw DatabaseException(
        'Erro ao pesquisar músicas: $query',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Music>> getFavoriteMusics() async {
    const String cacheKey = 'favorite_musics';

    try {
      await _ensureCacheInitialized();

      final cachedFavorites = await _cache.get<List<Music>>(cacheKey);
      if (cachedFavorites != null) {
        Logger.debug('Retrieved favorite musics from cache');
        return cachedFavorites;
      }

      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'musics',
        where: 'isFavorite = ?',
        whereArgs: [1],
        orderBy: 'title ASC',
      );

      final favorites =
          List.generate(maps.length, (i) => Music.fromMap(maps[i]));

      await _cache.set(cacheKey, favorites, ttl: const Duration(minutes: 10));

      Logger.info('Retrieved ${favorites.length} favorite musics');
      return favorites;
    } catch (e, stackTrace) {
      Logger.error('Failed to get favorite musics', e, stackTrace);
      throw DatabaseException(
        'Erro ao buscar músicas favoritas',
        originalError: e,
      );
    }
  }

  @override
  Future<String> addMusic(Music music) async {
    // Validação usando o sistema centralizado
    final validation = MusicValidators.validateMusic(
      title: music.title,
      artist: music.artist,
      tags: music.tags,
    );

    ValidationUtils.throwIfInvalid(validation);

    try {
      final db = await _databaseHelper.database;
      final String id = music.id.isEmpty ? _uuid.v4() : music.id;

      final musicWithId = Music(
        id: id,
        title: music.title.trim(),
        artist: music.artist.trim(),
        tags: music.tags,
        createdAt: music.createdAt,
        updatedAt: DateTime.now(), // Sempre atualizar timestamp
        isFavorite: music.isFavorite,
      );

      await db.insert('musics', musicWithId.toMap());

      // Invalidar caches relacionados
      await _invalidateRelevantCaches();

      Logger.info('Music added successfully: ${musicWithId.title} (ID: $id)');
      return id;
    } catch (e, stackTrace) {
      Logger.error('Failed to add music: ${music.title}', e, stackTrace);
      if (e is ValidationException) rethrow;
      throw DatabaseException(
        'Erro ao adicionar música',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateMusic(Music music) async {
    // Validação
    final validation = MusicValidators.validateMusic(
      title: music.title,
      artist: music.artist,
      tags: music.tags,
    );

    ValidationUtils.throwIfInvalid(validation);

    try {
      final db = await _databaseHelper.database;

      // Verificar se a música existe
      final existing = await getMusicById(music.id);
      if (existing == null) {
        throw ValidationException('Música não encontrada para atualização');
      }

      final updatedMusic = music.copyWith(updatedAt: DateTime.now());

      final rowsAffected = await db.update(
        'musics',
        updatedMusic.toMap(),
        where: 'id = ?',
        whereArgs: [music.id],
      );

      if (rowsAffected == 0) {
        throw DatabaseException('Nenhuma música foi atualizada');
      }

      // Invalidar caches
      await _invalidateRelevantCaches();
      await _cache.remove('music_${music.id}');

      Logger.info(
          'Music updated successfully: ${music.title} (ID: ${music.id})');
    } catch (e, stackTrace) {
      Logger.error('Failed to update music: ${music.id}', e, stackTrace);
      if (e is ValidationException) rethrow;
      throw DatabaseException(
        'Erro ao atualizar música',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteMusic(String id) async {
    if (id.trim().isEmpty) {
      throw ValidationException('ID da música não pode estar vazio');
    }

    try {
      final db = await _databaseHelper.database;

      // Verificar se existe
      final existing = await getMusicById(id);
      if (existing == null) {
        Logger.warning('Attempted to delete non-existent music: $id');
        return; // Silently return instead of throwing
      }

      // Usar transação para garantir integridade
      await db.transaction((txn) async {
        // Primeiro deletar conteúdos relacionados
        await txn.delete(
          'music_contents',
          where: 'musicId = ?',
          whereArgs: [id],
        );

        // Depois deletar da tabela setlist_music
        await txn.delete(
          'setlist_music',
          where: 'musicId = ?',
          whereArgs: [id],
        );

        // Por último, deletar a música
        final rowsAffected = await txn.delete(
          'musics',
          where: 'id = ?',
          whereArgs: [id],
        );

        if (rowsAffected == 0) {
          throw DatabaseException('Música não encontrada para exclusão');
        }
      });

      // Invalidar todos os caches relacionados
      await _invalidateRelevantCaches();
      await _cache.remove('music_$id');

      Logger.info('Music deleted successfully: $id');
    } catch (e, stackTrace) {
      Logger.error('Failed to delete music: $id', e, stackTrace);
      throw DatabaseException(
        'Erro ao deletar música',
        originalError: e,
      );
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    if (id.trim().isEmpty) {
      throw ValidationException('ID da música não pode estar vazio');
    }

    try {
      final music = await getMusicById(id);
      if (music == null) {
        throw ValidationException('Música não encontrada');
      }

      final updatedMusic = music.copyWith(
        isFavorite: !music.isFavorite,
        updatedAt: DateTime.now(),
      );

      await updateMusic(updatedMusic);

      // Invalidar cache específico de favoritos
      await _cache.remove('favorite_musics');

      Logger.info('Music favorite toggled: $id -> ${updatedMusic.isFavorite}');
    } catch (e, stackTrace) {
      Logger.error('Failed to toggle favorite: $id', e, stackTrace);
      if (e is ValidationException || e is DatabaseException) rethrow;
      throw DatabaseException(
        'Erro ao alternar favorito',
        originalError: e,
      );
    }
  }

  @override
  Future<List<MusicContent>> getContentsForMusic(String musicId) async {
    if (musicId.trim().isEmpty) {
      throw ValidationException('ID da música não pode estar vazio');
    }

    final String cacheKey = 'contents_$musicId';

    try {
      await _ensureCacheInitialized();

      final cachedContents = await _cache.get<List<MusicContent>>(cacheKey);
      if (cachedContents != null) {
        Logger.debug('Retrieved music contents from cache: $musicId');
        return cachedContents;
      }

      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'music_contents',
        where: 'musicId = ?',
        whereArgs: [musicId],
        orderBy: 'createdAt ASC',
      );

      final contents =
          List.generate(maps.length, (i) => MusicContent.fromMap(maps[i]));

      await _cache.set(cacheKey, contents, ttl: const Duration(minutes: 30));

      Logger.debug('Retrieved ${contents.length} contents for music: $musicId');
      return contents;
    } catch (e, stackTrace) {
      Logger.error('Failed to get music contents: $musicId', e, stackTrace);
      throw DatabaseException(
        'Erro ao buscar conteúdos da música',
        originalError: e,
      );
    }
  }

  @override
  Future<String> addContent(MusicContent content) async {
    // Validar conteúdo baseado no tipo
    ValidationResult validation;
    if (content.contentText != null && content.contentText!.isNotEmpty) {
      validation = ContentValidators.validateContentText(content.contentText);
    } else if (content.contentPath.isNotEmpty) {
      validation = ContentValidators.validateFilePath(content.contentPath);
    } else {
      validation =
          const ValidationResult.error('Conteúdo deve ter texto ou arquivo');
    }

    ValidationUtils.throwIfInvalid(validation);

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

      // Invalidar cache de conteúdos
      await _cache.remove('contents_${content.musicId}');

      Logger.info(
          'Content added successfully: ${content.type} for music ${content.musicId}');
      return id;
    } catch (e, stackTrace) {
      Logger.error(
          'Failed to add content for music: ${content.musicId}', e, stackTrace);
      throw DatabaseException(
        'Erro ao adicionar conteúdo',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateContent(MusicContent content) async {
    // Mesmo processo de validação
    ValidationResult validation;
    if (content.contentText != null && content.contentText!.isNotEmpty) {
      validation = ContentValidators.validateContentText(content.contentText);
    } else if (content.contentPath.isNotEmpty) {
      validation = ContentValidators.validateFilePath(content.contentPath);
    } else {
      validation =
          const ValidationResult.error('Conteúdo deve ter texto ou arquivo');
    }

    ValidationUtils.throwIfInvalid(validation);

    try {
      final db = await _databaseHelper.database;
      final updatedContent = content.copyWith(updatedAt: DateTime.now());

      final rowsAffected = await db.update(
        'music_contents',
        updatedContent.toMap(),
        where: 'id = ?',
        whereArgs: [content.id],
      );

      if (rowsAffected == 0) {
        throw DatabaseException('Conteúdo não encontrado para atualização');
      }

      // Invalidar cache
      await _cache.remove('contents_${content.musicId}');

      Logger.info('Content updated successfully: ${content.id}');
    } catch (e, stackTrace) {
      Logger.error('Failed to update content: ${content.id}', e, stackTrace);
      throw DatabaseException(
        'Erro ao atualizar conteúdo',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteContent(String id) async {
    if (id.trim().isEmpty) {
      throw ValidationException('ID do conteúdo não pode estar vazio');
    }

    try {
      final db = await _databaseHelper.database;

      // Buscar o conteúdo para saber qual música invalidar no cache
      final List<Map<String, dynamic>> contentMaps = await db.query(
        'music_contents',
        where: 'id = ?',
        whereArgs: [id],
      );

      String? musicId;
      if (contentMaps.isNotEmpty) {
        musicId = contentMaps.first['musicId'] as String?;
      }

      final rowsAffected = await db.delete(
        'music_contents',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        Logger.warning('Attempted to delete non-existent content: $id');
        return;
      }

      // Invalidar cache se soubermos qual música
      if (musicId != null) {
        await _cache.remove('contents_$musicId');
      }

      Logger.info('Content deleted successfully: $id');
    } catch (e, stackTrace) {
      Logger.error('Failed to delete content: $id', e, stackTrace);
      throw DatabaseException(
        'Erro ao deletar conteúdo',
        originalError: e,
      );
    }
  }

  /// Invalida caches relacionados a listas de músicas
  Future<void> _invalidateRelevantCaches() async {
    await _cache.remove('all_musics');
    await _cache.remove('favorite_musics');

    // Invalidar também caches de busca (começam com 'search_')
    // Em uma implementação mais sofisticada, poderíamos manter uma lista de chaves
    await _cache.cleanupExpired(); // Por enquanto, limpa expirados
  }
}
