import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazenamento de sessao separado para impedir que o bearer token seja salvo
/// junto de preferencias de interface e cache comum.
abstract interface class AuthSessionStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> delete();
}

class SecureAuthSessionStore implements AuthSessionStore {
  SecureAuthSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const storageKey = 'fitai.auth.session.secure.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: storageKey);

  @override
  Future<void> write(String value) =>
      _storage.write(key: storageKey, value: value);

  @override
  Future<void> delete() => _storage.delete(key: storageKey);
}

/// Store deterministico para testes unitarios e de widget.
class InMemoryAuthSessionStore implements AuthSessionStore {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async {
    _value = value;
  }

  @override
  Future<void> delete() async {
    _value = null;
  }
}
