import 'package:fitai/core/exercises/exercise_catalog_binding.dart';
import 'package:fitai/core/exercises/exercise_catalog_identity.dart';
import 'package:fitai/data/exercicios/exercicios.dart';
import 'package:fitai/features/plans/data/workout_history_repository.dart';
import 'package:fitai/features/plans/domain/manual_plan_draft.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/ready_plan_model.dart';
import 'package:fitai/services/ready_plan_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binder = ExerciseCatalogBinder(bancoExercicios);

  test('LIB-CONTRACT-01: Remada com mochila resolve editorialmente', () {
    final binding = _template(binder, 'Remada com mochila');
    expect(binding.canonicalExerciseId, 'costas_031');
    expect(binding.method, ExerciseCatalogBindingMethod.exactName);
  });

  test('LIB-CONTRACT-02: Barra fixa assistida resolve editorialmente', () {
    final binding = _template(binder, 'Barra fixa assistida');
    expect(binding.canonicalExerciseId, 'costas_032');
    expect(binding.method, ExerciseCatalogBindingMethod.exactName);
  });

  test('LIB-CONTRACT-03: todas as 27 referências de template resolvem', () {
    expect(_templateBindings(binder).every((item) => item.isResolved), isTrue);
  });

  test('LIB-CONTRACT-04: template não deixa referência unresolved', () {
    expect(
      _templateBindings(
        binder,
      ).where((item) => item.status == ExerciseCatalogBindingStatus.unresolved),
      isEmpty,
    );
  });

  test('LIB-CONTRACT-05: template não deixa referência ambígua', () {
    expect(
      _templateBindings(
        binder,
      ).where((item) => item.status == ExerciseCatalogBindingStatus.ambiguous),
      isEmpty,
    );
  });

  test('LIB-CONTRACT-06: Manual Builder materializa identidade canônica', () {
    final catalogExercise = bancoExercicios.firstWhere(
      (item) => item.id == 'costas_031',
    );
    final draft = ManualPlanDraft(id: 'manual-contract', goal: 'Força');
    expect(
      draft.addExercise(dayId: draft.days.single.id, exercise: catalogExercise),
      ManualPlanDraftSelectionResult.added,
    );
    draft.updatePrescription(
      dayId: draft.days.single.id,
      exerciseId: catalogExercise.id,
      sets: 3,
      reps: '8-12',
      restSeconds: 90,
    );
    final plan = draft.toPlan(name: 'Manual', level: 'Iniciante');
    expect(plan.exercicios.single.canonicalExerciseId, 'costas_031');
  });

  test('LIB-CONTRACT-07: template materializa identidade canônica', () {
    final plan = ReadyPlanMapper.toTreino(
      _readyPlan('Remada com mochila'),
      workoutId: 'template-contract',
      source: 'ready_plan',
    );
    expect(plan.exercicios.single.canonicalExerciseId, 'costas_031');
  });

  test('LIB-CONTRACT-08: IA resolve ID e alias canônicos', () {
    final canonical = binder.bindAi(
      templateItemId: 'ai-1',
      remoteExerciseId: 'remote-1',
      canonicalExerciseId: 'costas_032',
      exerciseName: 'qualquer',
    );
    final alias = binder.bindAi(
      templateItemId: 'ai-2',
      remoteExerciseId: 'remote-2',
      exerciseName: 'Puxada frontal',
    );
    expect(canonical.canonicalExerciseId, 'costas_032');
    expect(alias.canonicalExerciseId, 'costas_001');
  });

  test('LIB-CONTRACT-09: três origens alcançam mediaKey', () {
    final identity = ExerciseCatalogIdentity(bancoExercicios);
    final manual = identity.resolve(exerciseId: 'costas_031');
    final template = _template(binder, 'Barra fixa assistida');
    final ai = binder.bindAi(
      templateItemId: 'ai-media',
      remoteExerciseId: '',
      exerciseName: 'Puxada frontal',
    );
    expect(manual?.entry.mediaKey, 'exercise/costas_031');
    expect(template.mediaKey, 'exercise/costas_032');
    expect(ai.mediaKey, 'exercise/costas_001');
  });

  test('LIB-CONTRACT-10: contrato possui versão explícita', () {
    expect(ExerciseCatalogBindingContract.version, 1);
    expect(
      ExerciseCatalogBindingContract.identifier,
      'ExerciseCatalogBindingContract/v1',
    );
  });

  test('LIB-CONTRACT-11: mesma entrada e versão são determinísticas', () {
    final first = _template(binder, 'Remada com mochila');
    final second = _template(binder, 'Remada com mochila');
    expect(first.canonicalExerciseId, second.canonicalExerciseId);
    expect(first.mediaKey, second.mediaKey);
  });

  test('LIB-CONTRACT-12: alias ambíguo falha fechado', () {
    final synthetic = ExerciseCatalogBinder([
      _exercise('one', 'Movimento repetido'),
      _exercise('two', 'Movimento repetido'),
    ]);
    expect(
      synthetic
          .bindAi(
            templateItemId: 'ambiguous',
            remoteExerciseId: '',
            exerciseName: 'Movimento repetido',
          )
          .status,
      ExerciseCatalogBindingStatus.ambiguous,
    );
  });

  test('LIB-CONTRACT-13: IA desconhecida falha fechado', () {
    expect(
      binder
          .bindAi(
            templateItemId: 'unknown',
            remoteExerciseId: '',
            exerciseName: 'Movimento impossível',
          )
          .status,
      ExerciseCatalogBindingStatus.unresolved,
    );
  });

  test('LIB-CONTRACT-14: redirects legados aprovados continuam válidos', () {
    expect(
      binder
          .bindAi(
            templateItemId: 'legacy',
            remoteExerciseId: '',
            canonicalExerciseId: 'remada-curvada',
            exerciseName: '',
          )
          .canonicalExerciseId,
      'costas_002',
    );
  });

  test('LIB-CONTRACT-15: agachamento-livre não auto-resolve na IA', () {
    expect(
      binder
          .bindAi(
            templateItemId: 'unsafe-legacy',
            remoteExerciseId: '',
            canonicalExerciseId: 'agachamento-livre',
            exerciseName: 'Agachamento livre',
          )
          .isResolved,
      isFalse,
    );
  });

  test('LIB-CONTRACT-16: histórico agrupa ocorrência pelo ID canônico', () {
    final now = DateTime.utc(2026, 8, 31, 12);
    final history = WorkoutHistoryRepository(localStore: _UnusedWorkoutStore())
        .project(
          WorkoutSliceSnapshot(
            schemaVersion: 1,
            outbox: const [],
            sessions: [
              WorkoutSessionLocal(
                id: 'session-contract',
                planId: 'plan-contract',
                workoutId: 'workout-contract',
                startedAt: now.subtract(const Duration(minutes: 30)),
                finishedAt: now,
                status: WorkoutSessionStatus.completed,
                currentExerciseIndex: 0,
                currentSetIndex: 0,
                updatedAt: now,
                syncStatus: WorkoutSyncStatus.synced,
                version: 1,
              ),
            ],
            sets: [
              WorkoutSetLocal(
                id: 'set-contract',
                sessionId: 'session-contract',
                exerciseId: 'template-occurrence-1',
                canonicalExerciseId: 'costas_031',
                setIndex: 0,
                weight: 18,
                reps: 12,
                completedAt: now,
                updatedAt: now,
                syncStatus: WorkoutSyncStatus.synced,
                version: 1,
              ),
            ],
          ),
        );
    expect(history.exercisePrs.single.exerciseId, 'costas_031');
  });
}

List<ExerciseCatalogBinding> _templateBindings(ExerciseCatalogBinder binder) =>
    _seedNames.map((name) => _template(binder, name)).toList(growable: false);

ExerciseCatalogBinding _template(ExerciseCatalogBinder binder, String name) =>
    binder.bindTemplate(
      templateItemId: 'template-$name',
      remoteExerciseId: 'remote-$name',
      exerciseName: name,
    );

ReadyPlanModel _readyPlan(String name) => ReadyPlanModel.fromJson({
  'id': 'ready-contract',
  'nome': 'Plano pronto',
  'dias': [
    {
      'id': 'day-contract',
      'nome': 'Dia A',
      'titulo': 'Costas',
      'exercicios': [
        {
          'id': 'item-contract',
          'nome': name,
          'series': 3,
          'repeticoes': '8-12',
          'descanso': 90,
        },
      ],
    },
  ],
});

ExercicioModel _exercise(String id, String name) => ExercicioModel(
  id: id,
  nome: name,
  categoria: 'Teste',
  descricao: '',
  comoExecutar: '',
  cuidados: '',
  musculos: const [],
  equipamentos: const [],
  locais: const [],
  dificuldade: '',
  objetivo: '',
  imagem: '',
  video: '',
  tags: const [],
  caloriasHora: 0,
);

const _seedNames = [
  'Supino reto com barra',
  'Supino inclinado com halteres',
  'Crucifixo no cabo',
  'Tríceps na polia',
  'Puxada frontal',
  'Remada baixa',
  'Remada unilateral com halter',
  'Rosca direta',
  'Agachamento livre',
  'Leg press',
  'Mesa flexora',
  'Panturrilha em pé',
  'Supino reto com halteres',
  'Desenvolvimento com halteres',
  'Rosca alternada',
  'Agachamento goblet',
  'Levantamento terra romeno',
  'Cadeira extensora',
  'Prancha',
  'Levantamento terra',
  'Remada curvada',
  'Agachamento com peso corporal',
  'Flexão de braços',
  'Remada com mochila',
  'Barra fixa assistida',
  'Afundo alternado',
  'Elevação de pernas',
];

class _UnusedWorkoutStore implements WorkoutVerticalLocalStore {
  @override
  Future<WorkoutSliceSnapshot> read() async =>
      const WorkoutSliceSnapshot.empty();

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async {}
}
