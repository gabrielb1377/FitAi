import 'package:flutter/foundation.dart';

/// Logs estruturados e seguros para diagnosticar o Vertical Slice em debug.
///
/// Valores com nomes sensiveis nunca sao emitidos. O logger nao deve receber
/// payloads, JWTs, senhas ou respostas completas do backend.
abstract final class WorkoutVerticalLog {
  static void event(String name, {Map<String, Object?> fields = const {}}) {
    if (!kDebugMode) return;
    final details = fields.entries
        .map((entry) => '${entry.key}=${_safeValue(entry.key, entry.value)}')
        .join(' ');
    debugPrint(
      details.isEmpty
          ? '[WorkoutVertical] event=$name'
          : '[WorkoutVertical] event=$name $details',
    );
  }

  static void failure(String name, Object error) {
    event(name, fields: {'errorType': error.runtimeType.toString()});
  }

  static String _safeValue(String key, Object? value) {
    final normalized = key.toLowerCase();
    if (normalized.contains('token') ||
        normalized.contains('password') ||
        normalized.contains('authorization') ||
        normalized.contains('payload')) {
      return '[redacted]';
    }
    return value?.toString() ?? 'null';
  }
}
