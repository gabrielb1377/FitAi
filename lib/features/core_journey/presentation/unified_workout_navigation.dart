import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../models/treino_model.dart';
import '../../../screens/treinos/treino_em_andamento_page.dart';
import '../../workout_vertical_slice/domain/workout_vertical_models.dart';
import 'core_journey_controller.dart';
import 'core_journey_scope.dart';

/// Única porta de entrada de produção para a execução de musculação.
///
/// A sessão é criada ou recuperada no journal local antes da navegação. O
/// bloqueio por [NavigatorState] também impede duas rotas por toque repetido.
abstract final class UnifiedWorkoutNavigation {
  static final Set<NavigatorState> _openNavigators = <NavigatorState>{};

  static Future<WorkoutSessionLocal?> startAndOpen(
    BuildContext context, {
    required TreinoModel plan,
    TreinoModel? workout,
    String? dayName,
    String? muscleGroup,
    Future<void> Function()? onXpUpdated,
  }) async {
    final controller = CoreJourneyScope.maybeOf(context)?.notifier;
    if (controller == null) {
      _showUnavailable(context);
      return null;
    }
    if (!controller.isReady) await controller.initialize();
    final session = await controller.startWorkout(plan: plan, workout: workout);
    if (!context.mounted || session == null) {
      if (context.mounted) _showControllerError(context, controller);
      return null;
    }
    return _open(
      context,
      controller: controller,
      session: session,
      fallbackWorkout: workout ?? plan,
      dayName: dayName,
      muscleGroup: muscleGroup,
      onXpUpdated: onXpUpdated,
    );
  }

  static Future<WorkoutSessionLocal?> openSession(
    BuildContext context, {
    required String sessionId,
    Future<void> Function()? onXpUpdated,
  }) async {
    final controller = CoreJourneyScope.maybeOf(context)?.notifier;
    if (controller == null) {
      _showUnavailable(context);
      return null;
    }
    if (!controller.isReady) await controller.initialize();
    final session = await controller.recoverWorkout(sessionId);
    final workout = session == null
        ? null
        : controller.workoutForSession(session);
    if (!context.mounted || session == null || workout == null) {
      if (context.mounted) _showControllerError(context, controller);
      return null;
    }
    return _open(
      context,
      controller: controller,
      session: session,
      fallbackWorkout: workout,
      onXpUpdated: onXpUpdated,
    );
  }

  static Future<WorkoutSessionLocal?> _open(
    BuildContext context, {
    required CoreJourneyController controller,
    required WorkoutSessionLocal session,
    required TreinoModel fallbackWorkout,
    String? dayName,
    String? muscleGroup,
    Future<void> Function()? onXpUpdated,
  }) async {
    final navigator = Navigator.of(context);
    if (!_openNavigators.add(navigator)) return session;
    final workout = controller.workoutForSession(session) ?? fallbackWorkout;
    try {
      await navigator.push<void>(
        MaterialPageRoute(
          settings: RouteSettings(
            name: AppRoutes.coreWorkout,
            arguments: session.id,
          ),
          builder: (_) => TreinoEmAndamentoPage(
            treino: workout,
            nomeDia: dayName,
            grupoDia: muscleGroup,
            onXpAtualizado: onXpUpdated,
            sessionController: controller,
            sessionId: session.id,
          ),
        ),
      );
      return controller.sessionById(session.id);
    } finally {
      _openNavigators.remove(navigator);
    }
  }

  static void _showControllerError(
    BuildContext context,
    CoreJourneyController controller,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.errorMessage ??
              'Não foi possível preparar este treino no dispositivo.',
        ),
      ),
    );
  }

  static void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A sessão de treino ainda não está disponível.'),
      ),
    );
  }
}
