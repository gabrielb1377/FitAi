import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/features/auth/data/auth_session_store.dart';
import 'package:fitai/services/backend_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = String.fromEnvironment('R1_6_BASE_URL');
const _runId = String.fromEnvironment('R1_6_RUN_ID');

void main() {
  test(
    'R1.6: Flutter autenticado usa a fronteira privada de IA',
    () async {
      if (_baseUrl.isEmpty || _runId.isEmpty) return;

      SharedPreferences.setMockInitialValues({});
      ApiConfig.configure(baseUrl: _baseUrl);
      final client = http.Client();
      addTearDown(client.close);
      final auth = AuthService(
        client: client,
        sessionStore: _MemoryAuthSessionStore(),
      );
      final session = await auth.register(
        name: 'R1.6 Flutter',
        email: 'r16-flutter-$_runId@fitia.test',
        password: 'r1-6-flutter-password',
      );
      expect(session.token, isNotEmpty);

      final generated =
          await BackendAIService(
            client: client,
            authService: auth,
          ).generateWorkout(
            objetivo: 'hipertrofia',
            divisao: 'ABC',
            nivel: 'iniciante',
            diasPorSemana: 3,
            tempoPorTreino: 45,
            minExerciciosPorDia: 6,
            local: 'academia',
            equipamentos: const ['halteres'],
            restricoes: const [],
            prioridades: const [],
          );
      expect(generated.criadoPorIA, isTrue);
      expect(generated.planoDias, isNotEmpty);
    },
    skip: _baseUrl.isEmpty || _runId.isEmpty
        ? 'R1.6 E2E requer runner backend.'
        : false,
  );
}

class _MemoryAuthSessionStore implements AuthSessionStore {
  String? _value;

  @override
  Future<void> delete() async => _value = null;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;
}
