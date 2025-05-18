import 'package:music_sheet_pro/core/models/annotation.dart';

abstract class AnnotationRepository {
  Future<List<PdfAnnotation>> getAnnotationsForContent(String contentId);
  Future<String> addAnnotation(PdfAnnotation annotation);
  Future<void> updateAnnotation(PdfAnnotation annotation);
  Future<void> deleteAnnotation(String id);
  Future<void> deleteAllForContent(String contentId);
}
