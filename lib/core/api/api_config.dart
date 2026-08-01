import '../config/environment_config.dart';

class ApiConfigurationException implements Exception {
  const ApiConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'ApiConfigurationException: $message';
}

class ApiConfig {
  ApiConfig._();

  static String? _baseUrl = EnvironmentConfig.apiBaseUrl;
  static Duration _timeout = const Duration(seconds: 20);

  static String? get baseUrl => _baseUrl;
  static bool get isConfigured => _baseUrl != null;
  static Duration get timeout => _timeout;

  static Uri endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final baseUrl = _baseUrl;
    if (baseUrl == null) {
      throw const ApiConfigurationException(
        'API_BASE_URL nao foi configurada para este ambiente.',
      );
    }
    return Uri.parse('$baseUrl$normalizedPath');
  }

  static void configure({String? baseUrl, Duration? timeout}) {
    if (baseUrl != null) _baseUrl = _normalizeBaseUrl(baseUrl);
    if (timeout != null) _timeout = timeout;
  }

  static void reset() {
    _baseUrl = EnvironmentConfig.apiBaseUrl;
    _timeout = const Duration(seconds: 20);
  }

  static String? _normalizeBaseUrl(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    return normalized.isEmpty ? null : normalized;
  }
}
