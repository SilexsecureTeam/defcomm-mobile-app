import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/secure_file_service.dart';

class EncryptionTestScreen extends StatefulWidget {
  const EncryptionTestScreen({super.key});

  @override
  State<EncryptionTestScreen> createState() => _EncryptionTestScreenState();
}

class _EncryptionTestScreenState extends State<EncryptionTestScreen> {
  String? _encryptedFilePath;
  Uint8List? _decryptedBytes;
  bool _isLoading = false;

  Future<void> _pickAndEncrypt() async {
    setState(() => _isLoading = true);

    // 1. Pick Image
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    
    if (picked != null) {
      File original = File(picked.path);
      
      // 2. Encrypt & Save
      String securePath = await SecureFileService().saveEncryptedFile(original);
      
      // 3. Decrypt immediately to prove it works
      Uint8List? bytes = await SecureFileService().getDecryptedFileBytes(securePath);

      setState(() {
        _encryptedFilePath = securePath; // This path is in hidden storage
        _decryptedBytes = bytes;
      });
      
      print("File Saved at: $_encryptedFilePath");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Security Test")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.lock),
              label: const Text("Pick Image & Encrypt"),
              onPressed: _pickAndEncrypt,
            ),
            const SizedBox(height: 20),
            
            if (_isLoading) const CircularProgressIndicator(),

            if (_encryptedFilePath != null) ...[
              const Divider(),
              const Text("✅ 1. Decrypted (What the user sees in Chat):", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // HOW TO DISPLAY IN CHAT:
              _decryptedBytes != null 
                ? Image.memory(_decryptedBytes!, height: 200) // <--- Use Image.memory
                : const Text("Failed to decrypt"),

              const SizedBox(height: 30),
              const Divider(),
              const Text("❌ 2. Raw File (What a hacker sees):", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("(Attempting to render encrypted file as image...)"),
              const SizedBox(height: 10),
              
              // PROVING IT IS GARBAGE:
              // If we try to load the file directly, it should crash or show nothing
              Image.file(
                File(_encryptedFilePath!), 
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: Colors.red.shade100,
                    alignment: Alignment.center,
                    child: const Text("Image Load Failed (Good! It's encrypted)", textAlign: TextAlign.center),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text("Path: $_encryptedFilePath", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }
}