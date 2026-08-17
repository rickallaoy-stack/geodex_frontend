/// Configuration centrale de l'API Backend.
///
/// L'URL est fournie via `--dart-define` pour éviter d'enregistrer
/// des URLs de backend hardcodées dans les widgets.
class ApiConfig {
  static const String baseUrl =
      String.fromEnvironment('GEODEX_API_BASE_URL', defaultValue: 'https://dgn6gddt-3000.uks1.devtunnels.ms');

  static const int timeoutSeconds =
      int.fromEnvironment('GEODEX_API_TIMEOUT', defaultValue: 15);

  static const String environment =
      String.fromEnvironment('GEODEX_ENV', defaultValue: 'development');

  static bool get isProduction => environment == 'production';
}
