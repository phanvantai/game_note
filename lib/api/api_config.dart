// coverage:ignore-file — compile-time constants only.

/// Compile-time configuration for the Game Note backend.
///
/// Override per build with `--dart-define=API_BASE_URL=https://…`.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://gamenote-api.taiphanvan.dev',
  );

  /// Temporary escape hatch until the Firestore cutover: build with
  /// `--dart-define=USE_FIRESTORE=true` to keep the legacy repositories.
  static const bool useFirestore = bool.fromEnvironment('USE_FIRESTORE');
}
