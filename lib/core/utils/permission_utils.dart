import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> requestFilePermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;

      // Para Android 11+
      final manageStatus = await Permission.manageExternalStorage.request();
      return manageStatus.isGranted;
    }
    return true; // iOS e outras plataformas
  }

  static Future<bool> hasFilePermissions() async {
    if (Platform.isAndroid) {
      return await Permission.storage.isGranted ||
          await Permission.manageExternalStorage.isGranted;
    }
    return true;
  }
}
