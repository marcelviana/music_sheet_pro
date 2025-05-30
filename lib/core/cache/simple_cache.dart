import 'dart:collection';

class SimpleCache {
  static final Map<String, _CacheItem> _cache = HashMap();
  static const int _maxItems = 100;

  /// Armazena um item no cache
  static void set(String key, dynamic data, {Duration? ttl}) {
    // Limpar cache se estiver muito cheio
    if (_cache.length >= _maxItems) {
      _cleanOldItems();
    }

    final expiresAt = DateTime.now().add(ttl ?? const Duration(minutes: 10));
    _cache[key] = _CacheItem(data, expiresAt);
  }

  /// Recupera um item do cache
  static T? get<T>(String key) {
    final item = _cache[key];
    if (item == null || item.isExpired) {
      _cache.remove(key);
      return null;
    }
    return item.data as T?;
  }

  /// Remove um item específico
  static void remove(String key) {
    _cache.remove(key);
  }

  /// Limpa todo o cache
  static void clear() {
    _cache.clear();
  }

  /// Verifica se uma chave existe
  static bool containsKey(String key) {
    final item = _cache[key];
    if (item == null || item.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Remove itens expirados e mais antigos
  static void _cleanOldItems() {
    final now = DateTime.now();
    _cache.removeWhere((key, item) => item.isExpired);

    // Se ainda estiver cheio, remover os mais antigos
    if (_cache.length >= _maxItems) {
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

      final toRemove = _cache.length - (_maxItems ~/ 2);
      for (int i = 0; i < toRemove; i++) {
        _cache.remove(sortedEntries[i].key);
      }
    }
  }

  /// Estatísticas simples
  static int get itemCount => _cache.length;
  static void cleanExpired() {
    _cache.removeWhere((key, item) => item.isExpired);
  }
}

class _CacheItem {
  final dynamic data;
  final DateTime expiresAt;
  final DateTime createdAt;

  _CacheItem(this.data, this.expiresAt) : createdAt = DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// Classes auxiliares para facilitar uso
class MusicCache {
  static void cacheMusic(String id, dynamic music) =>
      SimpleCache.set('music_$id', music, ttl: const Duration(hours: 1));

  static T? getMusic<T>(String id) => SimpleCache.get<T>('music_$id');

  static void cacheAll(List<dynamic> musics) =>
      SimpleCache.set('all_musics', musics, ttl: const Duration(minutes: 15));

  static List<T>? getAll<T>() => SimpleCache.get<List<T>>('all_musics');

  static void invalidate(String id) {
    SimpleCache.remove('music_$id');
    SimpleCache.remove('all_musics');
  }
}

class SetlistCache {
  static void cacheSetlist(String id, dynamic setlist) =>
      SimpleCache.set('setlist_$id', setlist, ttl: const Duration(hours: 1));

  static T? getSetlist<T>(String id) => SimpleCache.get<T>('setlist_$id');

  static void cacheAll(List<dynamic> setlists) =>
      SimpleCache.set('all_setlists', setlists,
          ttl: const Duration(minutes: 15));

  static List<T>? getAll<T>() => SimpleCache.get<List<T>>('all_setlists');

  static void invalidate(String id) {
    SimpleCache.remove('setlist_$id');
    SimpleCache.remove('all_setlists');
  }
}
