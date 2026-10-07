import 'dart:async';
import 'dart:convert';
import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/core/exercises/plan_mutation_guard.dart';
import 'package:fitai/data/exercicios/exercicios.dart';
import 'package:fitai/features/ai_chat/application/ai_action_controller.dart';
import 'package:fitai/features/ai_chat/application/ai_action_executor.dart';
import 'package:fitai/features/ai_chat/data/ai_action_gateway.dart';
import 'package:fitai/features/ai_chat/domain/ai_action_models.dart';
import 'package:fitai/features/ai_chat/domain/ai_chat_models.dart';
import 'package:fitai/features/ai_chat/presentation/ai_action_card.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/services/backend_ai_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const actionId = '00000000-0000-4000-8000-000000000016';
TreinoModel plan() => TreinoModel(
  id: 'plan-a',
  nome: 'Upper A',
  descricao: '',
  objetivo: 'strength',
  nivel: 'intermediate',
  divisao: 'AB',
  tempoEstimado: 45,
  diasPorSemana: 2,
  criadoPorIA: false,
  dataCriacao: '2026-10-07',
  exercicios: [
    bancoExercicios
        .firstWhere((e) => e.id == 'ombros_003')
        .copyWith(
          series: 3,
          repeticoes: '8-12',
          descansoSegundos: 90,
          rir: '2',
          cadencia: '3010',
          observacoesTreino: 'Controlar movimento.',
        ),
  ],
  planoDias: const [
    TreinoDiaModel(
      codigo: 'A',
      nome: 'Upper',
      ordem: 1,
      exercicioIds: ['ombros_003'],
    ),
  ],
);

AiActionProposal proposal({
  String status = 'VALIDATED',
  String type = 'REPLACE_EXERCISE',
}) {
  final before = PlanMutationGuard.snapshot(plan());
  final after = jsonDecode(jsonEncode(before)) as Map<String, dynamic>;
  final exercises = after['exercicios'] as List;
  if (type == 'REPLACE_EXERCISE') {
    (exercises.single as Map)['id'] = 'ombros_004';
    (after['planoDias'] as List).single['exercicioIds'] = ['ombros_004'];
  } else {
    exercises.add({
      'id': 'ombros_004',
      'series': 3,
      'repeticoes': '10',
      'descansoSegundos': 60,
      'rir': '',
      'cadencia': '',
      'observacoesTreino': '',
    });
    (after['planoDias'] as List).single['exercicioIds'] = [
      'ombros_003',
      'ombros_004',
    ];
  }
  return AiActionProposal.fromJson({
    'contractVersion': AiActionProposal.version,
    'actionId': actionId,
    'actionType': type,
    'status': status,
    'explanation': 'Equipamento disponivel.',
    'payload': {
      'type': type,
      'planId': 'plan-a',
      'previousExerciseId': 'ombros_003',
      'canonicalExerciseId': 'ombros_004',
      'dayOrder': 1,
      'sets': 3,
      'repetitions': '10',
      'restSeconds': 60,
    },
    'preview': {
      'before': 'ombros_003',
      'after': 'ombros_004',
      'details': ['Altera somente a ficha.'],
    },
    'expectedBefore': before,
    'expectedAfter': after,
  });
}

AiActionProposal state(AiActionProposal p, String status) =>
    AiActionProposal.fromJson({...p.json, 'status': status});

class FakeActions implements AiActionGateway {
  FakeActions(this.p);
  final AiActionProposal p;
  int confirms = 0, cancels = 0, completes = 0;
  Completer<AiActionProposal>? delayed;
  AiChatFailure? failure;
  bool pendingAck = false;
  @override
  Future<AiActionProposal> confirm(
    String owner,
    String id,
    String device,
  ) async {
    confirms++;
    if (failure != null) throw failure!;
    return delayed?.future ?? state(p, 'CONFIRMED');
  }

  @override
  Future<AiActionProposal> cancel(String owner, String id) async {
    cancels++;
    return state(p, 'CANCELLED');
  }

  @override
  Future<AiActionProposal> complete(String owner, String id) async {
    completes++;
    if (pendingAck) throw const AiChatFailure('offline', 'Sem conexao.');
    return state(p, 'EXECUTED');
  }
}

class FakeExecutor implements AiActionExecutor {
  int calls = 0;
  AiChatFailure? failure;
  @override
  Future<String> execute(String owner, AiActionProposal action) async {
    calls++;
    if (failure != null) throw failure!;
    return 'plan-a';
  }
}

class FakeAuth extends AuthService {
  @override
  Future<AuthSession?> restoreSession() async => const AuthSession(
    userId: 'a',
    name: 'A',
    email: 'a@fitia.test',
    token: 'fixture',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountSessionLifecycle.setActiveUser('a');
  });
  tearDown(() {
    AccountSessionLifecycle.setActiveUser(null);
    ApiConfig.reset();
  });
  Future<AiActionController> host(
    WidgetTester tester,
    FakeActions gateway,
    FakeExecutor executor, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = AiActionController(gateway: gateway, executor: executor);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1200),
              textScaler: TextScaler.linear(scale),
            ),
            child: SingleChildScrollView(
              child: AnimatedBuilder(
                animation: c,
                builder: (_, child) =>
                    AiActionCard(proposal: gateway.p, controller: c),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets(
    'AI-UI-ACT-01/02 action and canonical before/after preview visible without mutation',
    (t) async {
      final e = FakeExecutor();
      await host(t, FakeActions(proposal()), e);
      expect(find.text('Substituir exercicio'), findsOneWidget);
      expect(find.textContaining('Antes:'), findsOneWidget);
      expect(find.textContaining('Depois:'), findsOneWidget);
      expect(find.text('Equipamento disponivel.'), findsOneWidget);
      expect(e.calls, 0);
    },
  );
  testWidgets('AI-UI-ACT-03 explicit double confirm executes once', (t) async {
    final g = FakeActions(proposal()), e = FakeExecutor();
    final c = await host(t, g, e);
    await Future.wait([c.confirm(g.p), c.confirm(g.p)]);
    await t.pumpAndSettle();
    expect(g.confirms, 1);
    expect(e.calls, 1);
    expect(c.current(g.p).status, 'EXECUTED');
    expect(find.text('Alteracao sincronizada e verificada'), findsOneWidget);
  });
  testWidgets(
    'AI-UI-ACT-04 cancel prevents subsequent confirmation/execution',
    (t) async {
      final g = FakeActions(proposal()), e = FakeExecutor();
      final c = await host(t, g, e);
      await t.tap(find.text('Cancelar sugestao'));
      await t.pumpAndSettle();
      await c.confirm(g.p);
      expect(g.cancels, 1);
      expect(g.confirms, 0);
      expect(e.calls, 0);
      expect(find.text('Sugestao cancelada'), findsOneWidget);
    },
  );
  testWidgets('AI-UI-ACT-05 loading prevents repeated consent', (t) async {
    final g = FakeActions(proposal())..delayed = Completer(),
        e = FakeExecutor();
    final c = await host(t, g, e);
    final waiting = c.confirm(g.p);
    await t.pump();
    expect(c.isBusy(actionId), true);
    expect(e.calls, 0);
    g.delayed!.complete(state(g.p, 'CONFIRMED'));
    await waiting;
    await t.pumpAndSettle();
    expect(e.calls, 1);
  });
  testWidgets('AI-UI-ACT-06 failed domain does not claim execution', (t) async {
    final g = FakeActions(proposal()),
        e = FakeExecutor()
          ..failure = const AiChatFailure('storage', 'Nao foi salvo.');
    final c = await host(t, g, e);
    await c.confirm(g.p);
    await t.pumpAndSettle();
    expect(find.text('Nao foi salvo.'), findsOneWidget);
    expect(g.completes, 0);
    expect(c.saved(actionId), false);
    expect(find.text('Alteracao sincronizada e verificada'), findsNothing);
  });
  testWidgets('AI-UI-ACT-07 stale action has useful error', (t) async {
    final g = FakeActions(proposal())
          ..failure = const AiChatFailure('stale_action', 'A ficha mudou.'),
        e = FakeExecutor();
    final c = await host(t, g, e);
    await c.confirm(g.p);
    await t.pumpAndSettle();
    expect(find.text('A ficha mudou.'), findsOneWidget);
    expect(e.calls, 0);
  });
  testWidgets('AI actions narrow 320 with 200 percent text have no overflow', (
    t,
  ) async {
    await host(
      t,
      FakeActions(proposal()),
      FakeExecutor(),
      width: 320,
      scale: 2,
    );
    expect(t.takeException(), isNull);
    expect(find.text('Confirmar alteracao'), findsOneWidget);
  });
  test('Missing remote ACK keeps durable local result honest', () async {
    final g = FakeActions(proposal())..pendingAck = true, e = FakeExecutor();
    final c = AiActionController(gateway: g, executor: e);
    addTearDown(c.dispose);
    await c.confirm(g.p);
    expect(c.saved(actionId), true);
    expect(c.current(g.p).status, 'CONFIRMED');
  });
  test(
    'Account change during confirm rejects delayed action before command',
    () async {
      final g = FakeActions(proposal())..delayed = Completer(),
          e = FakeExecutor();
      final c = AiActionController(gateway: g, executor: e);
      addTearDown(c.dispose);
      final waiting = c.confirm(g.p);
      await Future<void>.delayed(Duration.zero);
      AccountSessionLifecycle.setActiveUser('b');
      g.delayed!.complete(state(g.p, 'CONFIRMED'));
      await waiting;
      expect(e.calls, 0);
      expect(c.saved(actionId), false);
    },
  );
  test(
    'Canonical R2 replace preserves all prescription and history keys',
    () async {
      await StorageService.salvarTreino(plan());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('historyFixture', 'immutable completed sets');
      await CanonicalAiActionExecutor().execute(
        'a',
        proposal(status: 'CONFIRMED'),
      );
      final saved = (await StorageService.carregarTreinos()).single;
      expect(saved.exercicios.single.id, 'ombros_004');
      expect(saved.exercicios.single.rir, '2');
      expect(saved.exercicios.single.cadencia, '3010');
      expect(saved.exercicios.single.observacoesTreino, 'Controlar movimento.');
      expect(saved.exercicios.single.series, 3);
      expect(saved.exercicios.single.repeticoes, '8-12');
      expect(prefs.getString('historyFixture'), 'immutable completed sets');
    },
  );
  test(
    'Canonical R2 add is atomic and receipt replay survives executor restart',
    () async {
      await StorageService.salvarTreino(plan());
      final p = proposal(status: 'CONFIRMED', type: 'ADD_EXERCISE_TO_PLAN');
      await Future.wait([
        CanonicalAiActionExecutor().execute('a', p),
        CanonicalAiActionExecutor().execute('a', p),
      ]);
      await CanonicalAiActionExecutor().execute('a', p);
      final saved = (await StorageService.carregarTreinos()).single;
      expect(saved.exercicios.length, 2);
      expect(saved.planoDias.single.exercicioIds, ['ombros_003', 'ombros_004']);
      expect(
        (await StorageService.carregarPlanoComAcao('a', actionId))!.id,
        'plan-a',
      );
    },
  );
  test('Local stale prescription fails closed without a receipt', () async {
    final initial = plan().toJson();
    (initial['exercicios'] as List).single['rir'] = '0';
    await StorageService.salvarTreino(TreinoModel.fromJson(initial));
    await expectLater(
      CanonicalAiActionExecutor().execute('a', proposal(status: 'CONFIRMED')),
      throwsA(isA<AiChatFailure>()),
    );
    expect(
      (await StorageService.carregarTreinos()).single.exercicios.single.id,
      'ombros_003',
    );
    expect(await StorageService.carregarPlanoComAcao('a', actionId), isNull);
  });
  test(
    'Cached VALIDATED action cannot execute without remote authorization',
    () async {
      await StorageService.salvarTreino(plan());
      await expectLater(
        CanonicalAiActionExecutor().execute('a', proposal()),
        throwsA(isA<AiChatFailure>()),
      );
    },
  );
  test('Owner B cannot execute or reuse local receipt owned by A', () async {
    final boundary = LocalAccountDataBoundary();
    await boundary.activate('a');
    await StorageService.salvarTreino(plan());
    final p = proposal(status: 'CONFIRMED');
    await CanonicalAiActionExecutor().execute('a', p);
    await boundary.activate('b');
    AccountSessionLifecycle.setActiveUser('b');
    expect(await StorageService.carregarPlanoComAcao('b', actionId), isNull);
    expect(await StorageService.carregarTreinos(), isEmpty);
    await expectLater(
      CanonicalAiActionExecutor().execute('a', p),
      throwsA(isA<AiChatFailure>()),
    );
    await boundary.activate('a');
    AccountSessionLifecycle.setActiveUser('a');
    expect(
      (await StorageService.carregarPlanoComAcao('a', actionId))!.id,
      'plan-a',
    );
  });
  test(
    'Validated generated artifact uses existing binder and creates one stable plan',
    () async {
      final workout = {
        'id': 'ai-action-$actionId',
        'nome': 'Gerado',
        'descricao': 'fixture',
        'objetivo': 'Hipertrofia',
        'nivel': 'Iniciante',
        'tempoEstimado': 45,
        'dataCriacao': '2026-10-07',
        'dias': [
          {
            'nome': 'A',
            'titulo': 'Full Body',
            'exercicios': [
              {
                'id': 'occurrence-1',
                'nome': 'Elevacao lateral',
                'series': 3,
                'repeticoes': '10',
                'descanso': 60,
              },
            ],
          },
        ],
      };
      final mapper = BackendAIService();
      final mapped = mapper.mapValidatedWorkout(workout);
      mapper.dispose();
      final p = AiActionProposal.fromJson({
        ...proposal().json,
        'actionType': 'USE_GENERATED_WORKOUT',
        'status': 'CONFIRMED',
        'payload': {'workout': workout},
        'expectedBefore': null,
        'expectedAfter': PlanMutationGuard.snapshot(mapped),
      });
      await CanonicalAiActionExecutor().execute('a', p);
      await CanonicalAiActionExecutor().execute('a', p);
      final saved = (await StorageService.carregarTreinos()).single;
      expect(saved.id, 'ai-action-$actionId');
      expect(saved.exercicios.single.canonicalExerciseId, 'ombros_003');
      expect(saved.exercicios.single.id, 'occurrence-1');
    },
  );
  test(
    'Action HTTP confirmation contains only consent/device/version and JWT',
    () async {
      ApiConfig.configure(baseUrl: 'https://fitia.test');
      final g = HttpAiActionGateway(
        auth: FakeAuth(),
        client: MockClient((req) async {
          expect(req.url.path, '/ai/actions/$actionId/confirm');
          expect(req.headers['Authorization'], 'Bearer fixture');
          expect(jsonDecode(req.body), {
            'contractVersion': AiActionProposal.version,
            'confirmed': true,
            'deviceId': 'device-a',
          });
          return http.Response(
            jsonEncode(proposal(status: 'CONFIRMED').json),
            200,
          );
        }),
      );
      addTearDown(g.dispose);
      expect((await g.confirm('a', actionId, 'device-a')).status, 'CONFIRMED');
    },
  );
  test('Malformed action contract is rejected, not rendered as validated', () {
    expect(
      () => AiActionProposal.fromJson({
        ...proposal().json,
        'actionType': 'UPDATE_HEALTH',
      }),
      throwsFormatException,
    );
  });
}
