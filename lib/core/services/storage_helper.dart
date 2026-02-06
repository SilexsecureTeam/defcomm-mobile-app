import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageHelper {
  
  /// Get the directory where files are hidden from the user/gallery
  static Future<String> getPrivateDirectoryPath() async {
    final Directory directory;
    
    if (Platform.isAndroid) {
      directory = await getApplicationDocumentsDirectory(); 
    } else {
      directory = await getApplicationDocumentsDirectory(); 
    }

    return directory.path;
  }

  static Future<String> saveSecureFile(File originFile, String fileName) async {
    final String securePath = await getPrivateDirectoryPath();
    final String fullPath = '$securePath/$fileName';
    
    final File savedFile = await originFile.copy(fullPath);
    return savedFile.path;
  }
}