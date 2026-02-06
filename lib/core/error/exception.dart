class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'ServerException']);

  @override
  String toString() => message;
}
