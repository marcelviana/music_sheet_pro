import 'package:flutter_test/flutter_test.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/data/datasources/database_helper.dart';

void main() {
  group('Validação das Correções Críticas', () {
    test('ContentType enum deve ter 4 valores corretos', () {
      expect(ContentType.values.length, 4);
      expect(ContentType.lyrics.index, 0);
      expect(ContentType.chordChart.index, 1);
      expect(ContentType.tablature.index, 2);
      expect(ContentType.sheetMusic.index, 3);
    });

    test('MusicContent deve serializar/deserializar corretamente', () {
      final now = DateTime.now();
      final content = MusicContent(
        id: 'test-id',
        musicId: 'music-id',
        type: ContentType.lyrics,
        contentPath: 'path/to/file',
        contentText: 'Test lyrics',
        version: 1,
        createdAt: now,
        updatedAt: now,
      );

      final map = content.toMap();
      final restored = MusicContent.fromMap(map);

      expect(restored.id, content.id);
      expect(restored.type, content.type);
      expect(restored.contentText, content.contentText);
      expect(restored.createdAt, content.createdAt);
      expect(restored.updatedAt, content.updatedAt);
    });

    test('Database version deve ser 2', () {
      // Este teste precisa ser ajustado baseado na implementação real
      expect(DatabaseHelper.databaseVersion, 2);
    });
  });
}
