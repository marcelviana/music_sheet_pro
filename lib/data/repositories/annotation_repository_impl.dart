import 'package:music_sheet_pro/core/models/annotation.dart';
import 'package:music_sheet_pro/domain/repositories/annotation_repository.dart';
import 'package:music_sheet_pro/data/datasources/database_helper.dart';
import 'package:uuid/uuid.dart';

class AnnotationRepositoryImpl implements AnnotationRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _uuid = const Uuid();

  @override
  Future<List<PdfAnnotation>> getAnnotationsForContent(String contentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'annotations',
      where: 'contentId = ?',
      whereArgs: [contentId],
      orderBy: 'pageNumber ASC, createdAt ASC',
    );

    return List.generate(maps.length, (i) => PdfAnnotation.fromMap(maps[i]));
  }

  @override
  Future<String> addAnnotation(PdfAnnotation annotation) async {
    try {
      final db = await _databaseHelper.database;
      final String id = annotation.id.isEmpty ? _uuid.v4() : annotation.id;
      final annotationWithId = PdfAnnotation(
        id: id,
        contentId: annotation.contentId,
        pageNumber: annotation.pageNumber,
        xPosition: annotation.xPosition,
        yPosition: annotation.yPosition,
        text: annotation.text,
        colorValue: annotation.colorValue,
        createdAt: annotation.createdAt,
      );

      await db.insert('annotations', annotationWithId.toMap());
      return id;
    } catch (e) {
      print('Error adding annotation: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateAnnotation(PdfAnnotation annotation) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        'annotations',
        annotation.toMap(),
        where: 'id = ?',
        whereArgs: [annotation.id],
      );
    } catch (e) {
      print('Error updating annotation: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAnnotation(String id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'annotations',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting annotation: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAllForContent(String contentId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'annotations',
        where: 'contentId = ?',
        whereArgs: [contentId],
      );
    } catch (e) {
      print('Error deleting all annotations for content: $e');
      rethrow;
    }
  }
}
