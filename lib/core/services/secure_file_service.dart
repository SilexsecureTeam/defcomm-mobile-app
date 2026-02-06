import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class SecureFileService {
  // Singleton instance
  static final SecureFileService _instance = SecureFileService._internal();
  factory SecureFileService() => _instance;
  SecureFileService._internal();

  final _storage = const FlutterSecureStorage();
  encrypt.Key? _encryptionKey;
  
  // Initialize this in main.dart
  Future<void> init() async {
    // 1. Check if we already have a saved key
    String? keyString = await _storage.read(key: 'secure_file_key');
    
    if (keyString == null) {
      // 2. If not, generate a new random 32-byte (256-bit) key
      final key = encrypt.Key.fromSecureRandom(32);
      keyString = key.base64;
      await _storage.write(key: 'secure_file_key', value: keyString);
    }
    
    // 3. Load key into memory
    _encryptionKey = encrypt.Key.fromBase64(keyString);
  }

  /// 🔒 ENCRYPT & SAVE
  /// Takes a raw file, encrypts it, saves to internal storage.
  /// Returns the path of the encrypted file.
  Future<String> saveEncryptedFile(File originalFile) async {
    if (_encryptionKey == null) await init();

    // 1. Read bytes
    final fileBytes = await originalFile.readAsBytes();

    // 2. Generate a random IV (Initialization Vector) for this specific file
    // This ensures that encrypting the same image twice produces different results.
    final iv = encrypt.IV.fromSecureRandom(16);
    
    // 3. Encrypt
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

    // 4. Get Hidden Directory
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.enc'; // .enc extension
    final newPath = p.join(dir.path, fileName);
    
    // 5. Write to Disk: IV + Encrypted Data
    // We prepend the 16-byte IV to the file so we can read it back later.
    final outFile = File(newPath);
    
    // Combine IV bytes and Encrypted bytes
    final allBytes = [...iv.bytes, ...encrypted.bytes]; 
    await outFile.writeAsBytes(allBytes);

    return newPath;
  }

  /// 🔓 READ & DECRYPT
  /// Takes the path of an encrypted file, decrypts it in memory.
  /// Returns Uint8List (Bytes) to be used in MemoryImage.
  Future<Uint8List?> getDecryptedFileBytes(String path) async {
    if (_encryptionKey == null) await init();

    final file = File(path);
    if (!await file.exists()) return null;

    try {
      // 1. Read all bytes
      final allBytes = await file.readAsBytes();
      
      // 2. Extract IV (First 16 bytes)
      final ivBytes = allBytes.sublist(0, 16);
      final iv = encrypt.IV(ivBytes);
      
      // 3. Extract CipherText (The rest)
      final encryptedBytes = allBytes.sublist(16);
      
      // 4. Decrypt
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(encryptedBytes), 
        iv: iv
      );
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      print("Decryption failed: $e");
      return null;
    }
  }
}