import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _urlConfigurada = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String _baseUrl = _definirBaseUrlInicial();
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

  static String _definirBaseUrlInicial() {
    if (_urlConfigurada.trim().isNotEmpty) {
      return _normalizeBaseUrl(_urlConfigurada);
    }

    // Flutter Web e Windows executados no próprio computador.
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return 'http://localhost:3001';
    }

    // Android físico na mesma rede Wi-Fi do computador.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.101.12:3001';
    }

    return 'http://localhost:3001';
  }

  static String _normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
