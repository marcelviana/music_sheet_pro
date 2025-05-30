// lib/data/repositories/music_repository_impl.dart
// Replace the cache-related parts with this simpler approach:

import 'package:music_sheet_pro/core/models/app_settings.dart';
import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/core/models/music_stats.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/data/datasources/database_helper.dart';
import 'package:music_sheet_pro/core/exceptions/app_exception.dart';
import 'package:music_sheet_pro/core/validation/validators.dart';
import 'package:music_sheet_pro/core/cache/simple_cache.dart';
import 'package:music_sheet_pro/core/utils/logger.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:music_sheet_pro/core/services/file_service.dart';
import 'package:uuid/uuid.dart';
import 'package:music_sheet_pro/core/models/music_filter.dart';

class MusicRepositoryImpl implements MusicRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _uuid = const Uuid();

  @override
  Future<List<Music>> getAllMusics() async {
    const String cacheKey = 'all_musics';

    try {
      // Try cache first
      final cachedMusics = MusicCache.getAll<Music>();
      if (cachedMusics != null) {
        Logger.debug('Retrieved musics from cache');
        return cachedMusics;
      }

      // Get from database
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps =
          await db.query('musics', orderBy: 'title ASC');

      final musics = List.generate(maps.length, (i) => Music.fromMap(maps[i]));

      // Cache the results
      MusicCache.cacheAll(musics);

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

    try {
      // Try cache first
      final cachedMusic = MusicCache.getMusic<Music>(id);
      if (cachedMusic != null) {
        Logger.debug('Retrieved music from cache: $id');
        return cachedMusic;
      }

      // Get from database
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

      // Cache the result
      MusicCache.cacheMusic(id, music);

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
  Future<List<MusicContent>> getContentsForMusic(String musicId) async {
    if (musicId.trim().isEmpty) {
      throw ValidationException('ID da música não pode estar vazio');
    }

    try {
      // Try cache first
      final cacheKey = 'contents_$musicId';
      final cachedContents = SimpleCache.get<List<MusicContent>>(cacheKey);
      if (cachedContents != null) {
        Logger.debug('Retrieved music contents from cache: $musicId');
        return cachedContents;
      }

      // Get from database
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'music_contents',
        where: 'musicId = ?',
        whereArgs: [musicId],
        orderBy: 'createdAt ASC',
      );

      final contents =
          List.generate(maps.length, (i) => MusicContent.fromMap(maps[i]));

      // Cache the results
      SimpleCache.set(cacheKey, contents, ttl: const Duration(minutes: 30));

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

  // Update the other methods to use SimpleCache as well...
  // I'll show you the pattern for the key methods:

  @override
  Future<String> addMusic(Music music) async {
    // Validation using the centralized system
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
        updatedAt: DateTime.now(),
        isFavorite: music.isFavorite,
      );

      await db.insert('musics', musicWithId.toMap());

      // Clear relevant caches
      MusicCache.invalidate(id);

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
    // Validation
    final validation = MusicValidators.validateMusic(
      title: music.title,
      artist: music.artist,
      tags: music.tags,
    );

    ValidationUtils.throwIfInvalid(validation);

    try {
      final db = await _databaseHelper.database;

      // Check if music exists
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

      // Clear caches
      MusicCache.invalidate(music.id);

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

  // Continue with other methods using SimpleCache pattern...
  // For the remaining methods, follow the same pattern:
  // 1. Remove _ensureCacheInitialized() calls
  // 2. Replace _cache.get/set/remove with SimpleCache.get/set/remove
  // 3. Keep the same error handling logic

  @override
  Future<List<Music>> searchMusics(String query) async {
    if (query.trim().isEmpty) {
      return await getAllMusics();
    }

    try {
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
          '%$trimmedQuery%',
          '%$trimmedQuery%',
          '%$trimmedQuery%',
          '$trimmedQuery%',
          '$trimmedQuery%'
        ],
      );

      final results = List.generate(maps.length, (i) => Music.fromMap(maps[i]));

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
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'musics',
        where: 'isFavorite = ?',
        whereArgs: [1],
        orderBy: 'title ASC',
      );

      final favorites =
          List.generate(maps.length, (i) => Music.fromMap(maps[i]));

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
  Future<void> deleteMusic(String id) async {
    if (id.trim().isEmpty) {
      throw ValidationException('ID da música não pode estar vazio');
    }

    try {
      final db = await _databaseHelper.database;

      // Check if exists
      final existing = await getMusicById(id);
      if (existing == null) {
        Logger.warning('Attempted to delete non-existent music: $id');
        return;
      }

      // Use transaction for integrity
      await db.transaction((txn) async {
        await txn
            .delete('music_contents', where: 'musicId = ?', whereArgs: [id]);
        await txn
            .delete('setlist_music', where: 'musicId = ?', whereArgs: [id]);

        final rowsAffected =
            await txn.delete('musics', where: 'id = ?', whereArgs: [id]);
        if (rowsAffected == 0) {
          throw DatabaseException('Música não encontrada para exclusão');
        }
      });

      // Clean up files
      try {
        final fileService = serviceLocator<FileService>();
        await fileService.deleteMusicFiles(id);
      } catch (e) {
        Logger.warning('Failed to delete music files for: $id', e);
      }

      // Clear caches
      MusicCache.invalidate(id);
      SimpleCache.remove('contents_$id');

      Logger.info('Music deleted successfully: $id');
    } catch (e, stackTrace) {
      Logger.error('Failed to delete music: $id', e, stackTrace);
      throw DatabaseException('Erro ao deletar música', originalError: e);
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

      Logger.info('Music favorite toggled: $id -> ${updatedMusic.isFavorite}');
    } catch (e, stackTrace) {
      Logger.error('Failed to toggle favorite: $id', e, stackTrace);
      if (e is ValidationException || e is DatabaseException) rethrow;
      throw DatabaseException('Erro ao alternar favorito', originalError: e);
    }
  }

  @override
  Future<String> addContent(MusicContent content) async {
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

      // Clear cache
      SimpleCache.remove('contents_${content.musicId}');

      Logger.info(
          'Content added successfully: ${content.type} for music ${content.musicId}');
      return id;
    } catch (e, stackTrace) {
      Logger.error(
          'Failed to add content for music: ${content.musicId}', e, stackTrace);
      throw DatabaseException('Erro ao adicionar conteúdo', originalError: e);
    }
  }

  @override
  Future<void> updateContent(MusicContent content) async {
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

      // Clear cache
      SimpleCache.remove('contents_${content.musicId}');

      Logger.info('Content updated successfully: ${content.id}');
    } catch (e, stackTrace) {
      Logger.error('Failed to update content: ${content.id}', e, stackTrace);
      throw DatabaseException('Erro ao atualizar conteúdo', originalError: e);
    }
  }

  @override
  Future<void> deleteContent(String id) async {
    if (id.trim().isEmpty) {
      throw ValidationException('ID do conteúdo não pode estar vazio');
    }

    try {
      final db = await _databaseHelper.database;

      // Get content to know which music cache to clear
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

      // Clear cache if we know the music
      if (musicId != null) {
        SimpleCache.remove('contents_$musicId');
      }

      Logger.info('Content deleted successfully: $id');
    } catch (e, stackTrace) {
      Logger.error('Failed to delete content: $id', e, stackTrace);
      throw DatabaseException('Erro ao deletar conteúdo', originalError: e);
    }
  }
// Add these methods to your MusicRepositoryImpl class in music_repository_impl.dart

  @override
  Future<List<Music>> getFilteredMusics(MusicFilter filter) async {
    try {
      final db = await _databaseHelper.database;

      // Build the WHERE clause based on filter
      final whereConditions = <String>[];
      final whereArgs = <dynamic>[];

      // Search query
      if (filter.searchQuery?.isNotEmpty == true) {
        whereConditions.add('(title LIKE ? OR artist LIKE ? OR tags LIKE ?)');
        final searchTerm = '%${filter.searchQuery}%';
        whereArgs.addAll([searchTerm, searchTerm, searchTerm]);
      }

      // Favorites only
      if (filter.favoritesOnly == true) {
        whereConditions.add('isFavorite = ?');
        whereArgs.add(1);
      }

      // Tags filter
      if (filter.tags.isNotEmpty) {
        for (final tag in filter.tags) {
          whereConditions.add('tags LIKE ?');
          whereArgs.add('%$tag%');
        }
      }

      // Date range filter
      if (filter.dateRange != null) {
        whereConditions.add('createdAt BETWEEN ? AND ?');
        whereArgs.add(filter.dateRange!.start.millisecondsSinceEpoch);
        whereArgs.add(filter.dateRange!.end.millisecondsSinceEpoch);
      }

      // Build ORDER BY clause
      String orderBy;
      switch (filter.sortOrder) {
        case SortOrder.titleAsc:
          orderBy = 'title ASC';
          break;
        case SortOrder.titleDesc:
          orderBy = 'title DESC';
          break;
        case SortOrder.artistAsc:
          orderBy = 'artist ASC';
          break;
        case SortOrder.artistDesc:
          orderBy = 'artist DESC';
          break;
        case SortOrder.dateCreatedAsc:
          orderBy = 'createdAt ASC';
          break;
        case SortOrder.dateCreatedDesc:
          orderBy = 'createdAt DESC';
          break;
        case SortOrder.favorites:
          orderBy = 'isFavorite DESC, title ASC';
          break;
      }

      // Execute query
      final List<Map<String, dynamic>> maps = await db.query(
        'musics',
        where: whereConditions.isEmpty ? null : whereConditions.join(' AND '),
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: orderBy,
      );

      List<Music> musics =
          List.generate(maps.length, (i) => Music.fromMap(maps[i]));

      // Additional filtering that's easier to do in memory
      if (filter.hasContent) {
        final musicsWithContent = <Music>[];
        for (final music in musics) {
          final contents = await getContentsForMusic(music.id);
          if (contents.isNotEmpty) {
            musicsWithContent.add(music);
          }
        }
        musics = musicsWithContent;
      }

      // Content type filter (requires checking content table)
      if (filter.contentTypes.isNotEmpty) {
        final musicsWithContentType = <Music>[];
        for (final music in musics) {
          final contents = await getContentsForMusic(music.id);
          final hasRequiredType = contents
              .any((content) => filter.contentTypes.contains(content.type));
          if (hasRequiredType) {
            musicsWithContentType.add(music);
          }
        }
        musics = musicsWithContentType;
      }

      Logger.info('Filtered musics: ${musics.length} results');
      return musics;
    } catch (e, stackTrace) {
      Logger.error('Failed to get filtered musics', e, stackTrace);
      throw DatabaseException(
        'Erro ao buscar músicas filtradas',
        originalError: e,
      );
    }
  }

  @override
  Future<List<String>> getAllTags() async {
    try {
      final db = await _databaseHelper.database;

      // Get all non-empty tags from all musics
      final List<Map<String, dynamic>> maps = await db.query(
        'musics',
        columns: ['tags'],
        where: 'tags IS NOT NULL AND tags != ""',
      );

      final Set<String> allTags = {};

      for (final map in maps) {
        final tagsString = map['tags'] as String?;
        if (tagsString?.isNotEmpty == true) {
          final tags = tagsString!
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty);
          allTags.addAll(tags);
        }
      }

      final sortedTags = allTags.toList()..sort();

      Logger.debug('Retrieved ${sortedTags.length} unique tags');
      return sortedTags;
    } catch (e, stackTrace) {
      Logger.error('Failed to get all tags', e, stackTrace);
      throw DatabaseException(
        'Erro ao buscar tags',
        originalError: e,
      );
    }
  }

  @override
  Future<MusicStats> getMusicStats() async {
    try {
      final db = await _databaseHelper.database;

      // Get total musics count
      final totalMusicsResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM musics');
      final totalMusics = totalMusicsResult.first['count'] as int;

      // Get total favorites count
      final totalFavoritesResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM musics WHERE isFavorite = 1');
      final totalFavorites = totalFavoritesResult.first['count'] as int;

      // Get musics with content count
      final musicsWithContentResult = await db.rawQuery(
          'SELECT COUNT(DISTINCT musicId) as count FROM music_contents');
      final musicsWithContent = musicsWithContentResult.first['count'] as int;

      // Get total contents count
      final totalContentsResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM music_contents');
      final totalContents = totalContentsResult.first['count'] as int;

      // Get content type counts
      final contentTypeResults = await db.rawQuery(
          'SELECT type, COUNT(*) as count FROM music_contents GROUP BY type');

      final contentTypeCount = <ContentType, int>{};
      for (final result in contentTypeResults) {
        final typeIndex = result['type'] as int;
        final count = result['count'] as int;
        if (typeIndex >= 0 && typeIndex < ContentType.values.length) {
          contentTypeCount[ContentType.values[typeIndex]] = count;
        }
      }

      // Get most used tags
      final allTags = await getAllTags();
      final tagCounts = <String, int>{};

      // Count occurrences of each tag
      final tagResults = await db.query('musics', columns: ['tags']);
      for (final result in tagResults) {
        final tagsString = result['tags'] as String?;
        if (tagsString?.isNotEmpty == true) {
          final tags = tagsString!
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty);
          for (final tag in tags) {
            tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
          }
        }
      }

      // Get top 10 most used tags
      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final mostUsedTags = sortedTags.take(10).map((e) => e.key).toList();

      final stats = MusicStats(
        totalMusics: totalMusics,
        totalFavorites: totalFavorites,
        musicsWithContent: musicsWithContent,
        totalContents: totalContents,
        contentTypeCount: contentTypeCount,
        mostUsedTags: mostUsedTags,
      );

      Logger.info(
          'Music stats retrieved: $totalMusics musics, $totalContents contents');
      return stats;
    } catch (e, stackTrace) {
      Logger.error('Failed to get music stats', e, stackTrace);
      throw DatabaseException(
        'Erro ao buscar estatísticas',
        originalError: e,
      );
    }
  }
}
