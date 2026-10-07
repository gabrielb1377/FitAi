import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/auth/local_account_data_boundary.dart';
import '../../../core/exercises/exercise_plan_integration.dart';
import '../../../core/exercises/plan_mutation_guard.dart';
import '../../../data/exercicios/exercicios.dart';
import '../../../services/backend_ai_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/sync_service.dart';
import '../../../services/treino_service.dart';
import '../../workout_vertical_slice/data/workout_vertical_local_store.dart';
import '../domain/ai_action_models.dart';
import '../domain/ai_chat_models.dart';

abstract interface class AiActionExecutor {
  Future<String> execute(String owner, AiActionProposal action);
}

/// Invokes the R2/R3 commands, preserving local-first storage, history and outbox.
class CanonicalAiActionExecutor implements AiActionExecutor {
  @override
  Future<String> execute(String owner, AiActionProposal action) async {
    final revision = AccountSessionLifecycle.revision.value;
    void assertOwner() {
      if (AccountSessionLifecycle.activeUserId != owner ||
          AccountSessionLifecycle.revision.value != revision) {
        throw const AiChatFailure(
          'unauthorized',
          'A conta mudou. Nenhuma nova alteracao pode ser aplicada.',
        );
      }
    }

    assertOwner();
    if (action.status != 'CONFIRMED') {
      throw const AiChatFailure(
        'confirmation_required',
        'Confirme a sugestao primeiro.',
      );
    }
    final receipt = await StorageService.carregarPlanoComAcao(owner, action.id);
    assertOwner();
    if (receipt != null) {
      unawaited(SyncService.instance.syncWorkouts([receipt.toJson()]));
      return receipt.id;
    }
    final payload = action.payload;
    final guard = PlanMutationGuard(
      actionId: action.id,
      owner: owner,
      before: action.before,
      after: action.after,
      assertOwner: assertOwner,
    );
    try {
      if (action.type == 'USE_GENERATED_WORKOUT') {
        final mapper = BackendAIService();
        final plan = (() {
          try {
            return mapper.mapValidatedWorkout(
              Map<String, dynamic>.from(payload['workout'] as Map),
            );
          } finally {
            mapper.dispose();
          }
        })();
        await TreinoService.instance.adicionarTreinoComPersistencia(
          plan,
          mutationGuard: guard,
        );
        assertOwner();
        return plan.id;
      }
      final plans = await StorageService.carregarTreinos();
      assertOwner();
      final plan = plans.where((p) => p.id == payload['planId']).firstOrNull;
      if (plan == null) {
        throw const AiChatFailure(
          'stale_action',
          'Esta ficha nao esta disponivel neste dispositivo.',
        );
      }
      final prefs = await SharedPreferences.getInstance();
      final journal = await SharedPreferencesWorkoutVerticalLocalStore(
        prefs,
        userScope: owner,
      ).read();
      assertOwner();
      if (journal.sessions.any((s) => s.isOpen && s.planId == plan.id)) {
        throw const AiChatFailure(
          'active_session',
          'Conclua a sessao atual antes de alterar a ficha.',
        );
      }
      final candidate = bancoExercicios
          .where((e) => e.id == payload['canonicalExerciseId'])
          .firstOrNull;
      if (candidate == null) {
        throw const AiChatFailure(
          'invalid_exercise',
          'Este exercicio nao esta no catalogo canonico.',
        );
      }
      final integration = ExercisePlanIntegration(mutationGuard: guard);
      if (action.type == 'REPLACE_EXERCISE') {
        final previous = plan.exercicios
            .where((e) => e.id == payload['previousExerciseId'])
            .firstOrNull;
        if (previous == null) {
          throw const AiChatFailure(
            'stale_action',
            'O exercicio original ja mudou.',
          );
        }
        await integration.replaceInPlan(
          plan: plan,
          previousExerciseId: previous.id,
          replacement: candidate.copyWith(
            series: previous.series,
            repeticoes: previous.repeticoes,
            descansoSegundos: previous.descansoSegundos,
            rir: previous.rir,
            cadencia: previous.cadencia,
            observacoesTreino: previous.observacoesTreino,
          ),
        );
      } else if (action.type == 'ADD_EXERCISE_TO_PLAN') {
        final day = plan.planoDias.indexWhere(
          (d) => d.ordem == payload['dayOrder'],
        );
        if (day < 0) {
          throw const AiChatFailure('stale_action', 'O dia do plano ja mudou.');
        }
        await integration.addToPlan(
          ExercisePlanInsertion(
            plan: plan,
            exercise: candidate,
            dayIndex: day,
            sets: payload['sets'] as int,
            repetitions: payload['repetitions'] as String,
            restSeconds: payload['restSeconds'] as int,
          ),
        );
      } else {
        throw const AiChatFailure(
          'unsupported_action',
          'Esta sugestao ainda nao pode ser aplicada.',
        );
      }
      assertOwner();
      return plan.id;
    } on PlanActionAlreadyApplied catch (receipt) {
      assertOwner();
      return receipt.plan.id;
    } on AiChatFailure {
      rethrow;
    } on Object {
      throw const AiChatFailure(
        'stale_action',
        'A ficha mudou ou nao pode ser salva. Nenhuma nova alteracao foi confirmada.',
      );
    }
  }
}
