import 'package:get_storage/get_storage.dart';
import 'storage_service.dart';

class StorageServiceImpl implements StorageService {
  final GetStorage _box = GetStorage();

  @override
  Future<void> clearAll() async {
    await _box.erase();
  }

  @override
  String? readString(String key) {
    return _box.read<String>(key);
  }

  @override
  Future<void> saveString(String key, String value) async {
    await _box.write(key, value);
  }

  @override
  int? readInt(String key) {
    return _box.read<int>(key);
  }

  @override
  Future<void> saveInt(String key, int value) async {
    await _box.write(key, value);
  }
}