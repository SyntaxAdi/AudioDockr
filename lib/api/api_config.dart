class ApiConfig {
  static const String _baseUrl = String.fromEnvironment(
    'AUDIODOCKR_API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl => _baseUrl.trim();

  static bool get isConfigured => baseUrl.isNotEmpty;
}
