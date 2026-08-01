/// Configuracao de ambiente injetada no build.
///
/// O aplicativo nao define endpoint de desenvolvimento no codigo distribuivel.
/// Cada ambiente que precisa acessar o backend deve informar `API_BASE_URL` com
/// `--dart-define`, por exemplo:
/// `--dart-define=API_BASE_URL=https://api.example.com`.
class EnvironmentConfig {
  EnvironmentConfig._();

  static const _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const appEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// URL do backend configurada para este build, ou `null` em modo local sem
  /// backend. A ausencia preserva o comportamento offline-first do app.
  static String? get apiBaseUrl {
    final value = _rawApiBaseUrl.trim();
    if (value.isEmpty) return null;
    return value.replaceFirst(RegExp(r'/+$'), '');
  }
}
