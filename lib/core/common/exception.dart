class DatabaseException implements Exception {}

class ServerException implements Exception {
  final String message;

  ServerException(this.message);
}
