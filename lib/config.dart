class AppConfig {
  const AppConfig._();

  static const String apiKey = String.fromEnvironment('WEATHERAPI_KEY');
  static const String baseUrl = 'https://api.weatherapi.com/v1';

  static bool get hasKey => apiKey.isNotEmpty;
}
