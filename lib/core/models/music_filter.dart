// lib/core/models/music_filter.dart
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/core/models/app_settings.dart';

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }
}

class MusicFilter {
  final String? searchQuery;
  final List<ContentType> contentTypes;
  final bool? favoritesOnly;
  final List<String> tags;
  final DateRange? dateRange;
  final SortOrder sortOrder;
  final bool hasContent;

  const MusicFilter({
    this.searchQuery,
    this.contentTypes = const [],
    this.favoritesOnly,
    this.tags = const [],
    this.dateRange,
    this.sortOrder = SortOrder.titleAsc,
    this.hasContent = false,
  });

  MusicFilter copyWith({
    String? searchQuery,
    List<ContentType>? contentTypes,
    bool? favoritesOnly,
    List<String>? tags,
    DateRange? dateRange,
    SortOrder? sortOrder,
    bool? hasContent,
  }) {
    return MusicFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      contentTypes: contentTypes ?? this.contentTypes,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      tags: tags ?? this.tags,
      dateRange: dateRange ?? this.dateRange,
      sortOrder: sortOrder ?? this.sortOrder,
      hasContent: hasContent ?? this.hasContent,
    );
  }

  /// Check if filter is empty (no filters applied)
  bool get isEmpty {
    return (searchQuery?.isEmpty ?? true) &&
        contentTypes.isEmpty &&
        favoritesOnly == null &&
        tags.isEmpty &&
        dateRange == null &&
        !hasContent;
  }

  /// Get active filter count for UI display
  int get activeFilterCount {
    int count = 0;
    if (searchQuery?.isNotEmpty == true) count++;
    if (contentTypes.isNotEmpty) count++;
    if (favoritesOnly == true) count++;
    if (tags.isNotEmpty) count++;
    if (dateRange != null) count++;
    if (hasContent) count++;
    return count;
  }

  /// Get a human-readable description of active filters
  String getFilterDescription() {
    final parts = <String>[];

    if (searchQuery?.isNotEmpty == true) {
      parts.add('Busca: "$searchQuery"');
    }

    if (contentTypes.isNotEmpty) {
      final types =
          contentTypes.map((t) => _getContentTypeDisplayName(t)).join(', ');
      parts.add('Tipos: $types');
    }

    if (favoritesOnly == true) {
      parts.add('Apenas favoritos');
    }

    if (tags.isNotEmpty) {
      parts.add('Tags: ${tags.join(', ')}');
    }

    if (dateRange != null) {
      parts.add('Período personalizado');
    }

    if (hasContent) {
      parts.add('Com conteúdo');
    }

    return parts.isEmpty ? 'Sem filtros' : parts.join(' • ');
  }

  String _getContentTypeDisplayName(ContentType type) {
    switch (type) {
      case ContentType.lyrics:
        return 'Letras';
      case ContentType.chordChart:
        return 'Cifras';
      case ContentType.tablature:
        return 'Tablaturas';
      case ContentType.sheetMusic:
        return 'Partituras';
    }
  }

  /// Clear all filters
  MusicFilter clear() {
    return const MusicFilter();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MusicFilter &&
        other.searchQuery == searchQuery &&
        other.contentTypes.length == contentTypes.length &&
        other.contentTypes.every((element) => contentTypes.contains(element)) &&
        other.favoritesOnly == favoritesOnly &&
        other.tags.length == tags.length &&
        other.tags.every((element) => tags.contains(element)) &&
        other.dateRange?.start == dateRange?.start &&
        other.dateRange?.end == dateRange?.end &&
        other.sortOrder == sortOrder &&
        other.hasContent == hasContent;
  }

  @override
  int get hashCode {
    return Object.hash(
      searchQuery,
      contentTypes,
      favoritesOnly,
      tags,
      dateRange?.start,
      dateRange?.end,
      sortOrder,
      hasContent,
    );
  }
}
