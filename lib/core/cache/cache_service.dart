// 📁 lib/core/cache/cache_service.dart
// 🎯 Sistema de Cache Inteligente
// ⚡ Otimização de performance com cache em memória
// 📅 2025-05-23
// 👤 MusicSheet Pro Team
// 🔢 v1.0.0

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/setlist.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/core/utils/logger.dart';

/// Configurações de cache
class CacheConfig {
  final Duration defaultTtl;
  final int maxMemoryItems;
  final bool persistToDisk;

  const CacheConfig({
    this.defaultTtl = const Duration(minutes: 30),
    this.maxMemoryItems = 100,
    this.persistToDisk = true,
  });
}

/// Item de cache com metadados
class CacheItem<T> {
  final T data;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String key;
  final int accessCount;
  final DateTime lastAccessed;

  CacheItem({
    required this.data,
    required this.key,
    DateTime? createdAt,
    this.expiresAt,
    this.accessCount = 0,
    DateTime? lastAccessed,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastAccessed = lastAccessed ?? DateTime.now();

  /// Cria uma cópia com access count incrementado
  CacheItem<T> copyWithAccess() {
    return CacheItem<T>(
      data: data,
      key: key,
      createdAt: createdAt,
      expiresAt: expiresAt,
      accessCount: accessCount + 1,
      lastAccessed: DateTime.now(),
    );
  }

  /// Verifica se o item expirou
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Calcula score para algoritmo LRU
  double get lruScore {
    final now = DateTime.now();
    final timeSinceAccess = now.difference(lastAccessed).inMinutes;
    final accessFrequency = accessCount /
        (now.difference(createdAt).inMinutes.clamp(1, double.infinity));

    // Score maior = mais importante (menos provável de ser removido)
    return accessFrequency / (timeSinceAccess + 1);
  }
}

/// Serviço principal de cache
class CacheService {
  final CacheConfig _config;
  final Map<String, CacheItem<dynamic>> _memoryCache = {};
  SharedPreferences? _prefs;
  bool _initialized = false;

  CacheService([this._config = const CacheConfig()]);

  /// Inicializa o serviço de cache
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (_config.persistToDisk) {
        _prefs = await SharedPreferences.getInstance();
        await _loadAllFromDisk();
      }
      _initialized = true;
      Logger.info('CacheService initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize CacheService', e);
      _initialized = true; // Continue without disk persistence
    }
  }

  /// Armazena um item no cache
  Future<void> set<T>(
    String key,
    T data, {
    Duration? ttl,
    bool persistToDisk = true,
  }) async {
    await _ensureInitialized();

    final expiresAt = ttl != null
        ? DateTime.now().add(ttl)
        : DateTime.now().add(_config.defaultTtl);

    final item = CacheItem<T>(
      data: data,
      key: key,
      expiresAt: expiresAt,
    );

    _memoryCache[key] = item;

    // Aplicar limite de memória
    await _enforceMemoryLimit();

    // Persistir no disco se habilitado
    if (persistToDisk && _config.persistToDisk && _prefs != null) {
      await _persistToDisk(key, item);
    }

    Logger.debug('Cached item: $key (TTL: ${ttl ?? _config.defaultTtl})');
  }

  /// Recupera um item do cache
  Future<T?> get<T>(String key) async {
    await _ensureInitialized();

    final item = _memoryCache[key];
    if (item == null) {
      // Tentar carregar do disco
      if (_config.persistToDisk && _prefs != null) {
        final diskItem = await _loadFromDisk(key);
        if (diskItem != null) {
          _memoryCache[key] = diskItem.copyWithAccess();
          return diskItem.data as T?;
        }
      }
      return null;
    }

    // Verificar expiração
    if (item.isExpired) {
      await remove(key);
      return null;
    }

    // Atualizar estatísticas de acesso
    _memoryCache[key] = item.copyWithAccess();

    Logger.debug('Cache hit: $key');
    return item.data as T?;
  }

  /// Remove um item do cache
  Future<void> remove(String key) async {
    await _ensureInitialized();

    _memoryCache.remove(key);

    if (_config.persistToDisk && _prefs != null) {
      await _prefs!.remove(_diskKey(key));
    }

    Logger.debug('Removed from cache: $key');
  }

  /// Limpa todo o cache
  Future<void> clear() async {
    await _ensureInitialized();

    _memoryCache.clear();

    if (_config.persistToDisk && _prefs != null) {
      final keys = _prefs!.getKeys().where((k) => k.startsWith('cache_'));
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }

    Logger.info('Cache cleared');
  }

  /// Verifica se uma chave existe no cache
  Future<bool> containsKey(String key) async {
    await _ensureInitialized();

    final item = _memoryCache[key];
    if (item != null && !item.isExpired) {
      return true;
    }

    if (_config.persistToDisk && _prefs != null) {
      return _prefs!.containsKey(_diskKey(key));
    }

    return false;
  }

  /// Obtém estatísticas do cache
  CacheStats getStats() {
    var expiredCount = 0;
    var totalSize = 0;

    for (final item in _memoryCache.values) {
      if (item.isExpired) expiredCount++;
      totalSize += _estimateItemSize(item);
    }

    return CacheStats(
      totalItems: _memoryCache.length,
      expiredItems: expiredCount,
      estimatedSizeBytes: totalSize,
      hitRate: _calculateHitRate(),
    );
  }

  /// Limpa itens expirados
  Future<void> cleanupExpired() async {
    await _ensureInitialized();

    final expiredKeys = <String>[];

    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      await remove(key);
    }

    Logger.info('Cleaned up ${expiredKeys.length} expired cache items');
  }

  // Métodos privados

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<void> _enforceMemoryLimit() async {
    if (_memoryCache.length <= _config.maxMemoryItems) return;

    // Ordenar por score LRU (menor score = mais provável de ser removido)
    final sortedItems = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.lruScore.compareTo(b.value.lruScore));

    final itemsToRemove = _memoryCache.length - _config.maxMemoryItems;

    for (int i = 0; i < itemsToRemove; i++) {
      final key = sortedItems[i].key;
      await remove(key);
    }

    Logger.debug('Removed $itemsToRemove items to enforce memory limit');
  }

  Future<void> _persistToDisk(String key, CacheItem item) async {
    try {
      final serialized = _serializeItem(item);
      await _prefs!.setString(_diskKey(key), serialized);
    } catch (e) {
      Logger.warning('Failed to persist cache item to disk: $key', e);
    }
  }

  Future<void> _loadAllFromDisk([String? specificKey]) async {
    if (_prefs == null) return;

    try {
      final keys = specificKey != null
          ? [_diskKey(specificKey)]
          : _prefs!.getKeys().where((k) => k.startsWith('cache_'));

      for (final diskKey in keys) {
        final serialized = _prefs!.getString(diskKey);
        if (serialized != null) {
          final item = _deserializeItem(serialized);
          if (item != null && !item.isExpired) {
            final cacheKey = _cacheKeyFromDiskKey(diskKey);
            _memoryCache[cacheKey] = item;
          }
        }
      }
    } catch (e) {
      Logger.warning('Failed to load cache from disk', e);
    }
  }

  Future<CacheItem?> _loadFromDisk(String key) async {
    if (_prefs == null) return null;

    try {
      final serialized = _prefs!.getString(_diskKey(key));
      if (serialized != null) {
        final item = _deserializeItem(serialized);
        if (item != null && !item.isExpired) {
          return item;
        }
      }
    } catch (e) {
      Logger.warning('Failed to load cache item from disk: $key', e);
    }

    return null;
  }

  String _diskKey(String key) => 'cache_$key';

  String _cacheKeyFromDiskKey(String diskKey) => diskKey.substring(6);

  String _serializeItem(CacheItem item) {
    final map = {
      'data': _serializeData(item.data),
      'key': item.key,
      'createdAt': item.createdAt.millisecondsSinceEpoch,
      'expiresAt': item.expiresAt?.millisecondsSinceEpoch,
      'accessCount': item.accessCount,
      'lastAccessed': item.lastAccessed.millisecondsSinceEpoch,
      'dataType': item.data.runtimeType.toString(),
    };
    return jsonEncode(map);
  }

  CacheItem? _deserializeItem(String serialized) {
    try {
      final map = jsonDecode(serialized) as Map<String, dynamic>;
      final dataType = map['dataType'] as String?;
      final data = _deserializeData(map['data'], dataType);

      if (data == null) return null;

      return CacheItem(
        data: data,
        key: map['key'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
        expiresAt: map['expiresAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'])
            : null,
        accessCount: map['accessCount'] ?? 0,
        lastAccessed: DateTime.fromMillisecondsSinceEpoch(
            map['lastAccessed'] ?? DateTime.now().millisecondsSinceEpoch),
      );
    } catch (e) {
      Logger.warning('Failed to deserialize cache item', e);
      return null;
    }
  }

  dynamic _serializeData(dynamic data) {
    if (data is Music) {
      return {'type': 'Music', 'data': data.toMap()};
    } else if (data is Setlist) {
      return {'type': 'Setlist', 'data': data.toMap()};
    } else if (data is MusicContent) {
      return {'type': 'MusicContent', 'data': data.toMap()};
    } else if (data is List) {
      return {'type': 'List', 'data': data.map(_serializeData).toList()};
    }
    return data; // Tipos primitivos
  }

  dynamic _deserializeData(dynamic serialized, String? dataType) {
    if (serialized is Map<String, dynamic> && serialized.containsKey('type')) {
      final type = serialized['type'];
      final data = serialized['data'];

      switch (type) {
        case 'Music':
          return Music.fromMap(data);
        case 'Setlist':
          return Setlist.fromMap(data);
        case 'MusicContent':
          return MusicContent.fromMap(data);
        case 'List':
          return (data as List)
              .map((item) => _deserializeData(item, null))
              .toList();
      }
    }
    return serialized;
  }

  int _estimateItemSize(CacheItem item) {
    // Estimativa simples baseada no tipo
    if (item.data is String) {
      return (item.data as String).length * 2; // UTF-16
    } else if (item.data is List) {
      return (item.data as List).length * 100; // Estimativa
    }
    return 1000; // Estimativa padrão
  }

  double _calculateHitRate() {
    // Implementação simplificada - em produção usar métricas reais
    return 0.85; // 85% de hit rate como placeholder
  }
}

/// Estatísticas do cache
class CacheStats {
  final int totalItems;
  final int expiredItems;
  final int estimatedSizeBytes;
  final double hitRate;

  const CacheStats({
    required this.totalItems,
    required this.expiredItems,
    required this.estimatedSizeBytes,
    required this.hitRate,
  });

  int get activeItems => totalItems - expiredItems;
  double get estimatedSizeMB => estimatedSizeBytes / (1024 * 1024);

  @override
  String toString() {
    return 'CacheStats(total: $totalItems, active: $activeItems, '
        'size: ${estimatedSizeMB.toStringAsFixed(2)}MB, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Cache especializado para músicas
class MusicCache {
  static final CacheService _cache = CacheService();
  static const String _prefix = 'music_';

  static Future<void> cacheMusic(Music music) async {
    await _cache.set('${_prefix}${music.id}', music);
  }

  static Future<Music?> getMusic(String id) async {
    return await _cache.get<Music>('${_prefix}$id');
  }

  static Future<void> cacheMusics(List<Music> musics) async {
    await _cache.set('${_prefix}all', musics, ttl: const Duration(minutes: 15));

    // Cache individual também
    for (final music in musics) {
      await cacheMusic(music);
    }
  }

  static Future<List<Music>?> getAllMusics() async {
    return await _cache.get<List<Music>>('${_prefix}all');
  }

  static Future<void> invalidateMusic(String id) async {
    await _cache.remove('${_prefix}$id');
    await _cache.remove('${_prefix}all'); // Invalida lista também
  }
}

/// Cache especializado para setlists
class SetlistCache {
  static final CacheService _cache = CacheService();
  static const String _prefix = 'setlist_';

  static Future<void> cacheSetlist(Setlist setlist) async {
    await _cache.set('${_prefix}${setlist.id}', setlist);
  }

  static Future<Setlist?> getSetlist(String id) async {
    return await _cache.get<Setlist>('${_prefix}$id');
  }

  static Future<void> cacheSetlists(List<Setlist> setlists) async {
    await _cache.set('${_prefix}all', setlists,
        ttl: const Duration(minutes: 10));

    for (final setlist in setlists) {
      await cacheSetlist(setlist);
    }
  }

  static Future<List<Setlist>?> getAllSetlists() async {
    return await _cache.get<List<Setlist>>('${_prefix}all');
  }

  static Future<void> invalidateSetlist(String id) async {
    await _cache.remove('${_prefix}$id');
    await _cache.remove('${_prefix}all');
  }
}
