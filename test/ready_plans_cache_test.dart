import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitai/models/ready_plan_model.dart';
import 'package:fitai/services/ready_plans_service.dart';

void main() {
  test('usa a lista salva quando o backend fica offline', () async {
    SharedPreferences.setMockInitialValues({});
    final payload = {
      'plans': [
        {
          'id': 'plan-1',
          'nome': 'ABC Classico',
          'categoria': 'ABC',
          'objetivo': 'Hipertrofia',
          'nivel': 'Iniciante',
          'divisao': 'ABC',
          'diasPorSemana': 3,
          'tempoEstimado': 55,
        },
      ],
    };

    final online = ReadyPlansService(client: _JsonClient(payload));
    final onlineResult = await online.listPlans();
    expect(onlineResult.source, ReadyPlansSource.backend);

    final offline = ReadyPlansService(client: _JsonClient({}, fail: true));
    final offlineResult = await offline.listPlans();
    expect(offlineResult.source, ReadyPlansSource.cache);
    expect(offlineResult.plans.single.id, 'plan-1');
  });

  test(
    'retorna erro amigavel quando o backend esta offline sem cache',
    () async {
      SharedPreferences.setMockInitialValues({});
      final offline = ReadyPlansService(client: _JsonClient({}, fail: true));

      expect(() => offline.listPlans(), throwsA(isA<ReadyPlansException>()));
    },
  );

  test('salva e recupera somente detalhes completos', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ReadyPlansService(client: _JsonClient({}));
    final plan = ReadyPlanModel.fromJson({
      'id': 'plan-2',
      'nome': 'Plano completo',
      'dias': [
        {
          'id': 'day-1',
          'nome': 'Dia A',
          'exercicios': [
            {'id': 'exercise-1', 'nome': 'Agachamento', 'series': 3},
          ],
        },
      ],
    });

    await service.savePlanDetailCache(plan);
    final loaded = await service.loadPlanDetailCache('plan-2');
    expect(loaded?.days.single.exercises.single.exerciseName, 'Agachamento');
  });

  test('abre detalhe completo salvo quando o backend esta offline', () async {
    SharedPreferences.setMockInitialValues({});
    final cachedPlan = _completePlan('plan-offline');
    final online = ReadyPlansService(client: _JsonClient({}));
    await online.savePlanDetailCache(cachedPlan);

    final offline = ReadyPlansService(client: _JsonClient({}, fail: true));
    final detail = await offline.getPlanDetails('plan-offline');

    expect(detail.id, 'plan-offline');
    expect(detail.days, isNotEmpty);
  });

  test(
    'nao retorna detalhe incompleto quando nao existe cache offline',
    () async {
      SharedPreferences.setMockInitialValues({});
      final offline = ReadyPlansService(client: _JsonClient({}, fail: true));

      expect(
        () => offline.getPlanDetails('plan-missing'),
        throwsA(isA<ReadyPlansException>()),
      );
    },
  );

  test(
    'cache com schema inválido é limpo sem apagar outras preferências',
    () async {
      SharedPreferences.setMockInitialValues({
        'fitai.ready_plans.cache.v1': jsonEncode({'version': 0, 'plans': []}),
        'perfilNome': 'Gabriel',
      });
      final service = ReadyPlansService(client: _JsonClient({}, fail: true));

      expect(await service.loadPlansCache(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('fitai.ready_plans.cache.v1'), isNull);
      expect(prefs.getString('perfilNome'), 'Gabriel');
    },
  );
}

ReadyPlanModel _completePlan(String id) {
  return ReadyPlanModel.fromJson({
    'id': id,
    'nome': 'Plano completo',
    'dias': [
      {
        'id': 'day-1',
        'nome': 'Dia A',
        'exercicios': [
          {'id': 'exercise-1', 'nome': 'Agachamento', 'series': 3},
        ],
      },
    ],
  });
}

class _JsonClient extends http.BaseClient {
  final Map<String, dynamic> body;
  final bool fail;

  _JsonClient(this.body, {this.fail = false});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (fail) throw http.ClientException('offline');

    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      200,
      request: request,
      headers: const {'content-type': 'application/json'},
    );
  }
}
