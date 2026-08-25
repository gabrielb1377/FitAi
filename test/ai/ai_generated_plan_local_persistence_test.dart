import 'dart:async';
import 'dart:convert';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/features/auth/data/auth_session_store.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/services/backend_ai_service.dart';
import 'package:fitai/services/network_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:fitai/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfig.configure(baseUrl: 'https://offline-plan.fitia.test');
  });

  tearDown(ApiConfig.reset);

  test(
    'AIPERSIST-01: geracao valida salva localmente quando o backend cai',
    () async {
      final plan = await _generatePlan('user-a');
      final offline = _syncFor('user-a', _OfflineClient());

      await StorageService.salvarTreino(plan, syncService: offline);
      await _waitFor(() async => (await offline.pendingCount()) == 1);

      final persisted = await StorageService.carregarTreinos();
      expect(persisted.single.id, plan.id);
      expect(persisted.single.criadoPorIA, isTrue);
    },
  );

  test(
    'AIPERSIST-02: plano IA salvo offline sobrevive ao reinicio local',
    () async {
      final plan = await _generatePlan('user-a');
      final offline = _syncFor('user-a', _OfflineClient());
      await StorageService.salvarTreino(plan, syncService: offline);
      await _waitFor(() async => (await offline.pendingCount()) == 1);

      final afterRestart = await StorageService.carregarTreinos();
      expect(afterRestart.map((item) => item.id), contains(plan.id));
    },
  );

  test(
    'AIPERSIST-03: retorno do backend envia uma vez e preserva o ID',
    () async {
      final plan = await _generatePlan('user-a');
      final offline = _syncFor('user-a', _OfflineClient());
      await StorageService.salvarTreino(plan, syncService: offline);
      await _waitFor(() async => (await offline.pendingCount()) == 1);

      final client = _OnlineCaptureClient();
      final online = _syncFor('user-a', client);
      await online.flushPending();

      expect(await online.pendingCount(), 0);
      expect(client.workoutPayloads, hasLength(1));
      final item =
          (client.workoutPayloads.single['items'] as List).single as Map;
      expect(item['id'], plan.id);
      expect(
        (await StorageService.carregarTreinos()).where(
          (item) => item.id == plan.id,
        ),
        hasLength(1),
      );
    },
  );

  test(
    'AIPERSIST-04: plano de A nao aparece para B apos troca de conta',
    () async {
      final boundary = LocalAccountDataBoundary();
      await boundary.activate('user-a', claimUnownedData: true);
      final plan = await _generatePlan('user-a');
      await StorageService.salvarTreino(
        plan,
        syncService: _syncFor('user-a', _OfflineClient()),
      );

      await boundary.activate('user-b');
      expect(await StorageService.carregarTreinos(), isEmpty);

      await boundary.activate('user-a');
      expect(
        (await StorageService.carregarTreinos()).map((item) => item.id),
        contains(plan.id),
      );
    },
  );

  test(
    'AIPERSIST-05: backend offline antes da geracao nao cria plano fantasma',
    () async {
      final auth = _authFor('user-a');
      final service = BackendAIService(
        client: _OfflineClient(),
        authService: auth,
      );

      await expectLater(
        _requestGeneration(service),
        throwsA(isA<BackendAIException>()),
      );
      expect(await StorageService.carregarTreinos(), isEmpty);
    },
  );
}

Future<TreinoModel> _generatePlan(String userId) async {
  final service = BackendAIService(
    client: _GenerationClient(),
    authService: _authFor(userId),
  );
  return _requestGeneration(service);
}

Future<TreinoModel> _requestGeneration(BackendAIService service) =>
    service.generateWorkout(
      objetivo: 'hipertrofia',
      divisao: 'ABC',
      nivel: 'iniciante',
      diasPorSemana: 1,
      tempoPorTreino: 45,
      minExerciciosPorDia: 6,
      local: 'academia',
      equipamentos: const ['halteres'],
      restricoes: const [],
      prioridades: const [],
    );

SyncService _syncFor(String userId, http.Client client) =>
    SyncService.forTesting(
      networkService: NetworkService(client: client),
      authService: _authFor(userId),
    );

AuthService _authFor(String userId) {
  final store = InMemoryAuthSessionStore();
  unawaited(
    store.write(
      jsonEncode(
        AuthSession(
          userId: userId,
          name: userId,
          email: '$userId@fitia.test',
          token: _token(),
        ).toJson(),
      ),
    ),
  );
  return AuthService(sessionStore: store);
}

Future<void> _waitFor(Future<bool> Function() predicate) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    if (await predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('A fila local nao atingiu o estado esperado.');
}

String _token() {
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'exp':
                DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          }),
        ),
      )
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

class _OfflineClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      throw http.ClientException('offline');
}

class _GenerationClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode(jsonEncode(_generationResponse))),
        200,
        headers: const {'content-type': 'application/json'},
      );
}

class _OnlineCaptureClient extends http.BaseClient {
  final List<Map<String, dynamic>> workoutPayloads = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'POST' && request.url.path == '/sync/workouts') {
      workoutPayloads.add(
        jsonDecode((request as http.Request).body) as Map<String, dynamic>,
      );
    }
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{}')),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}

final _generationResponse = {
  'id': 'ai-plan-stable-001',
  'nome': 'Plano IA',
  'dias': [
    {
      'nome': 'A',
      'titulo': 'Peito',
      'exercicios': List.generate(
        6,
        (index) => {
          'id': 'exercise-$index',
          'nome': 'Exercicio $index',
          'categoria': 'Peito',
          'series': 3,
          'repeticoes': '8-12',
          'descanso': 90,
        },
      ),
    },
  ],
};
