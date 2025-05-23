import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<String> copyToAppDirectory(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(sourcePath);
    final targetPath = path.join(appDir.path, 'music_files', fileName);

    // Criar diretório se não existir
    await Directory(path.dirname(targetPath)).create(recursive: true);

    // Copiar arquivo
    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
