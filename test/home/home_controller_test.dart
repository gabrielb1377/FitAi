import 'dart:async';

import 'package:fitai/features/home/presentation/controllers/home_controller.dart';
import 'package:fitai/features/home/presentation/states/home_state.dart';
import 'package:fitai/models/fitai_meta_model.dart';
import 'package:fitai/models/historico_treino_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mantem loading ate os dados locais terminarem de carregar', () async {
    final history = Completer<List<HistoricoTreinoModel>>();
    final controller = _controller(
      historyLoader: () => history.future,
      isOnline: false,
    );
    addTearDown(controller.dispose);

    final load = controller.load(workouts: const [], xp: 0, level: 1);

    expect(controller.state.status, HomeLoadStatus.loading);

    history.complete(const []);
    await load;

    expect(controller.state.status, HomeLoadStatus.ready);
    expect(controller.state.isOffline, isTrue);
    expect(controller.state.selection.treino, isNull);
  });

  test('seleciona treino real e preserva as metricas recebidas', () async {
    final workout = _workout();
    final controller = _controller(isOnline: true);
    addTearDown(controller.dispose);

    await controller.load(workouts: [workout], xp: 180, level: 3);

    expect(controller.state.status, HomeLoadStatus.ready);
    expect(controller.state.isOffline, isFalse);
    expect(controller.state.selection.treino?.id, workout.id);
  });

  test('expone estado de erro amigavel quando nao existe cache', () async {
    final controller = _controller(
      historyLoader: () => Future.error(StateError('storage unavailable')),
      isOnline: false,
    );
    addTearDown(controller.dispose);

    await controller.load(workouts: const [], xp: 0, level: 1);

    expect(controller.state.status, HomeLoadStatus.error);
    expect(controller.state.isOffline, isTrue);
    expect(controller.state.errorMessage, isNotEmpty);
  });
}

HomeController _controller({
  Future<List<HistoricoTreinoModel>> Function()? historyLoader,
  required bool isOnline,
}) {
  return HomeController(
    historyLoader: historyLoader ?? () async => const [],
    coachLoader: () async => const [],
    goalsLoader: () async => const FitaiMetasResumo(metas: []),
    achievementsLoader: () async => const [],
    notificationsLoader: () async => const [],
    networkCheck: () async => isOnline,
  );
}

TreinoModel _workout() => TreinoModel(
  id: 'workout-1',
  nome: 'Upper A',
  descricao: 'Treino superior',
  objetivo: 'Hipertrofia',
  nivel: 'Intermediario',
  divisao: 'Upper/Lower',
  tempoEstimado: 45,
  diasPorSemana: 4,
  criadoPorIA: false,
  exercicios: const [],
  dataCriacao: DateTime(2026).toIso8601String(),
);
