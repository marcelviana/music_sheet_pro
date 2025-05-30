// lib/core/services/file_service.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:music_sheet_pro/core/utils/logger.dart';
import 'package:music_sheet_pro/core/exceptions/app_exception.dart';

class FileService {
  static const int maxFileSizeMB = 50;
  static const List<String> allowedExtensions = [
    '.pdf',
    '.png',
    '.jpg',
    '.jpeg'
  ];

  /// Import a file to the app's document directory
  Future<String> importFile(String sourcePath, String musicId) async {
    try {
      final sourceFile = File(sourcePath);

      // Validate file exists
      if (!await sourceFile.exists()) {
        throw const FileImportException('Arquivo não encontrado');
      }

      // Validate file size
      final fileStat = await sourceFile.stat();
      final fileSizeMB = fileStat.size / (1024 * 1024);
      if (fileSizeMB > maxFileSizeMB) {
        throw FileImportException(
            'Arquivo muito grande (máximo ${maxFileSizeMB}MB)');
      }

      // Validate file extension
      final extension = path.extension(sourcePath).toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        throw FileImportException('Formato não suportado: $extension');
      }

      // Create target directory
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir =
          Directory(path.join(appDir.path, 'music_files', musicId));
      await musicDir.create(recursive: true);

      // Generate unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final targetPath = path.join(musicDir.path, fileName);

      // Copy file
      await sourceFile.copy(targetPath);

      Logger.info('File imported successfully: $targetPath');
      return targetPath;
    } catch (e, stackTrace) {
      Logger.error('Failed to import file: $sourcePath', e, stackTrace);
      if (e is FileImportException) rethrow;
      throw FileImportException('Erro ao importar arquivo', originalError: e);
    }
  }

  /// Delete all files associated with a music
  Future<void> deleteMusicFiles(String musicId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir =
          Directory(path.join(appDir.path, 'music_files', musicId));

      if (await musicDir.exists()) {
        await musicDir.delete(recursive: true);
        Logger.info('Music files deleted: $musicId');
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to delete music files: $musicId', e, stackTrace);
      // Don't rethrow - this is a cleanup operation
    }
  }

  /// Check if a file exists
  Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file size in MB
  Future<double> getFileSizeMB(String filePath) async {
    try {
      final file = File(filePath);
      final stat = await file.stat();
      return stat.size / (1024 * 1024);
    } catch (e) {
      return 0;
    }
  }

  /// Get app's music files directory
  Future<Directory> getMusicFilesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final musicFilesDir = Directory(path.join(appDir.path, 'music_files'));
    await musicFilesDir.create(recursive: true);
    return musicFilesDir;
  }

  /// Clean up orphaned files (files without corresponding database entries)
  Future<void> cleanupOrphanedFiles(List<String> validMusicIds) async {
    try {
      final musicFilesDir = await getMusicFilesDirectory();

      if (!await musicFilesDir.exists()) return;

      final allMusicDirs = await musicFilesDir
          .list(followLinks: false)
          .where((entity) => entity is Directory)
          .cast<Directory>()
          .toList();

      for (final dir in allMusicDirs) {
        final dirName = path.basename(dir.path);
        if (!validMusicIds.contains(dirName)) {
          await dir.delete(recursive: true);
          Logger.info('Deleted orphaned music directory: $dirName');
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to cleanup orphaned files', e, stackTrace);
    }
  }
}
