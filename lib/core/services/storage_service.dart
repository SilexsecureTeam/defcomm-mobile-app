abstract interface class StorageService {
  Future<void> saveString(String key, String value);
  String? readString(String key);
  Future<void> saveInt(String key, int value);
  int? readInt(String key);
  Future<void> clearAll();
}