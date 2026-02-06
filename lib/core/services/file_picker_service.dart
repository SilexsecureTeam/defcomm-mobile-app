import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';


class FilePickerService {
  final ImagePicker _imagePicker = ImagePicker();
  final FilePicker _filePicker = FilePicker.platform;

  // Pick an Image from the gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
    return null;
  }

  // Pick a Video from the gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
    }
    return null;
  }

  // Pick an Audio file
  Future<File?> pickAudio() async {
    try {
      final FilePickerResult? result = await _filePicker.pickFiles(
        type: FileType.audio,
      );
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      debugPrint("Error picking audio: $e");
    }
    return null;
  }
  
  // Pick a Document (any file type)
  Future<File?> pickDocument() async {
    try {
      final FilePickerResult? result = await _filePicker.pickFiles(
        type: FileType.any, // Or specify allowed extensions: allowedExtensions: ['pdf', 'doc']
      );
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      debugPrint("Error picking document: $e");
    }
    return null;
  }
}