class ApiConfig {
  ApiConfig._();

  static String _baseUrl = 'http://localhost:3001';
  static Duration _timeout = const Duration(seconds: 20);

  static String get baseUrl => _baseUrl;
  static Duration get timeout => _timeout;

  static Uri endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath');
  }

  static void configure({String? baseUrl, Duration? timeout}) {
    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      _baseUrl = _normalizeBaseUrl(baseUrl);
    }

    if (timeout != null) {
      _timeout = timeout;
    }
  }

  static String _normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
