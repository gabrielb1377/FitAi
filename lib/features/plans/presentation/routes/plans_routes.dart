import 'package:flutter/material.dart';

import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/deep_link.dart';
import '../../../../core/navigation/section_router.dart';
import '../../../../design_system/fit_design_system.dart';
import '../../../../screens/treinos/controllers/plan_progress_snapshot.dart';
import '../../../../screens/treinos/exercicio_detalhe_page.dart';
import '../../../../models/exercicio_model.dart';
import '../../../../models/treino_model.dart';
import '../../../core_journey/presentation/core_journey_route_pages.dart';
import '../../../core_journey/presentation/core_journey_scope.dart';
import '../../domain/workout_history_models.dart';
import '../controllers/plan_workout_history_controller.dart';
import '../pages/planos_official_library_page.dart';
import '../pages/planos_official_plan_pages.dart';
import '../pages/planos_official_wizards.dart';
import '../pages/plan_workout_history_pages.dart';

/// Rotas oficiais e reservadas do módulo Planos.
abstract final class PlansRoutes {
  static const root = '/plans';
  static const create = AppRoutes.plansCreate;
  static const createWithAi = AppRoutes.plansCreateWithAi;
  static const createManual = AppRoutes.plansCreateManual;
  static const detail = AppRoutes.corePlanDetail;
  static const weeks = AppRoutes.plansWeeks;
  static const workoutDay = AppRoutes.plansWorkoutDay;
  static const exercise = AppRoutes.plansExercise;
  static const session = AppRoutes.coreWorkout;
  static const completion = AppRoutes.coreWorkoutSummary;
  static const readyPlans = '/plans/ready';
  static const statistics = AppRoutes.plansStatistics;
  static const calendar = '/plans/calendar';
  static const compare = '/plans/compare';
  static const history = AppRoutes.corePlanHistory;
  static const workoutHistoryCalendar = '/plans/history/calendar';
  static const workoutHistoryDetail = AppRoutes.corePlanWorkoutHistory;
  static const importShare = '/plans/import-share';
  static const archive = '/plans/archive';

  static const declared = <String>{
    root,
    create,
    createWithAi,
    createManual,
    detail,
    weeks,
    workoutDay,
    exercise,
    session,
    completion,
    readyPlans,
    statistics,
    calendar,
    compare,
    history,
    workoutHistoryCalendar,
    workoutHistoryDetail,
    importShare,
    archive,
  };

  static SectionRouter createRouter({required WidgetBuilder rootBuilder}) {
    return SectionRouter(
      section: AppShellSection.plans,
      rootBuilder: rootBuilder,
      routes: {
        detail: (_, settings) =>
            CoreJourneyPlanDetailRoutePage(arguments: settings.arguments),
        session: (_, settings) =>
            CoreJourneyWorkoutRoutePage(arguments: settings.arguments),
        completion: (_, settings) =>
            CoreJourneySummaryRoutePage(arguments: settings.arguments),
        create: (_, _) => const PlanosCreateChoicePage(),
        createWithAi: (_, _) => const PlanosAiGoalPage(),
        createManual: (_, _) => const PlanosManualGoalPage(),
        weeks: (context, settings) => _withPlan(
          context,
          settings.arguments,
          (plan) => PlanosWeekPage(plan: plan, days: buildPlanosPlanDays(plan)),
        ),
        workoutDay: (context, settings) => _withPlanDay(
          context,
          settings.arguments,
          (plan, day) => PlanosWorkoutDetailPage(plan: plan, day: day),
        ),
        exercise: (context, settings) => _withExercise(
          context,
          settings.arguments,
          (exercise) => ExercicioDetalhePage(exercicio: exercise),
        ),
        readyPlans: (_, _) => const PlanosReadyLibraryPage(),
        statistics: (context, settings) => _withPlan(
          context,
          settings.arguments,
          (plan) => PlanosStatisticsPage(
            plan: plan,
            progress: PlanProgressSnapshot.empty(plan),
          ),
        ),
        calendar: (context, settings) =>
            PlanosCalendarPage(plan: _planFor(context, settings.arguments)),
        compare: (_, _) => const PlanosComparePage(),
        history: (context, settings) {
          final filter = _historyFilter(settings.arguments);
          return PlanWorkoutHistoryPage(
            loadHistory: _historyLoader(context),
            source: _historySource(context),
            initialPlanId: filter.planId,
            initialWorkoutId: filter.workoutId,
          );
        },
        workoutHistoryCalendar: (context, _) => PlanWorkoutHistoryCalendarPage(
          loadHistory: _historyLoader(context),
          source: _historySource(context),
        ),
        workoutHistoryDetail: (context, settings) =>
            PlanWorkoutHistoryDetailPage(
              sessionId: _sessionId(settings.arguments),
              loadHistory: _historyLoader(context),
              source: _historySource(context),
            ),
        importShare: (_, _) => const PlanosImportSharePage(),
        archive: (_, _) => const PlanosArchivePage(),
      },
      declaredRoutes: declared,
    );
  }

  static PlanWorkoutHistoryLoader _historyLoader(BuildContext context) {
    final controller = CoreJourneyScope.maybeOf(context)?.notifier;
    return () async {
      if (controller == null || !controller.isReady) {
        return const PlanWorkoutHistorySnapshot.empty();
      }
      return controller.loadPlanWorkoutHistory();
    };
  }

  static Listenable? _historySource(BuildContext context) =>
      CoreJourneyScope.maybeOf(context)?.notifier;

  static Widget _withPlan(
    BuildContext context,
    Object? arguments,
    Widget Function(TreinoModel plan) builder,
  ) {
    final plan = _planFor(context, arguments);
    if (plan == null) return const _PlanRouteUnavailablePage();
    return builder(plan);
  }

  static Widget _withPlanDay(
    BuildContext context,
    Object? arguments,
    Widget Function(TreinoModel plan, PlanosPlanDayView day) builder,
  ) {
    final plan = _planFor(context, arguments);
    if (plan == null) return const _PlanRouteUnavailablePage();
    final requestedDay = _routeArguments(arguments)?.dayCode;
    final day = buildPlanosPlanDays(plan).where((item) {
      return requestedDay == null || item.code == requestedDay;
    }).firstOrNull;
    if (day == null) return const _PlanRouteUnavailablePage();
    return builder(plan, day);
  }

  static Widget _withExercise(
    BuildContext context,
    Object? arguments,
    Widget Function(ExercicioModel exercise) builder,
  ) {
    final plan = _planFor(context, arguments);
    final exerciseId = _routeArguments(arguments)?.exerciseId;
    if (plan == null || exerciseId == null) {
      return const _PlanRouteUnavailablePage();
    }
    final exercise = plan.exercicios.where((item) {
      return item.id == exerciseId || item.nome == exerciseId;
    }).firstOrNull;
    if (exercise == null) return const _PlanRouteUnavailablePage();
    return builder(exercise);
  }

  static TreinoModel? _planFor(BuildContext context, Object? arguments) {
    final scope = CoreJourneyScope.maybeOf(context)?.notifier;
    final planId =
        _routeArguments(arguments)?.planId ?? coreJourneyRouteId(arguments);
    if (scope == null || planId == null || planId.isEmpty) return null;
    return scope.planById(planId);
  }

  static PlanRouteArguments? _routeArguments(Object? arguments) {
    if (arguments is PlanRouteArguments) return arguments;
    if (arguments is AppDeepLinkTarget) {
      final query = arguments.uri.queryParameters;
      final planId = query['id']?.trim();
      return planId == null || planId.isEmpty
          ? null
          : PlanRouteArguments(
              planId: planId,
              dayCode: query['day']?.trim(),
              exerciseId: query['exercise']?.trim(),
            );
    }
    return null;
  }

  static _WorkoutHistoryFilter _historyFilter(Object? arguments) {
    if (arguments is! AppDeepLinkTarget) return const _WorkoutHistoryFilter();
    final segments = arguments.uri.pathSegments;
    if (segments.length >= 3 &&
        segments.first.toLowerCase() == 'plans' &&
        segments[2].toLowerCase() == 'history') {
      return _WorkoutHistoryFilter(planId: segments[1]);
    }
    if (segments.length >= 5 &&
        segments.first.toLowerCase() == 'plans' &&
        segments[2].toLowerCase() == 'workouts' &&
        segments[4].toLowerCase() == 'history') {
      return _WorkoutHistoryFilter(planId: segments[1], workoutId: segments[3]);
    }
    return const _WorkoutHistoryFilter();
  }

  static String _sessionId(Object? arguments) {
    if (arguments is String) return arguments.trim();
    if (arguments is AppDeepLinkTarget) {
      final segments = arguments.uri.pathSegments;
      if (segments.length >= 3 &&
          segments.first.toLowerCase() == 'activities' &&
          segments[1].toLowerCase() == 'workout') {
        return segments[2];
      }
      return arguments.uri.queryParameters['id']?.trim() ?? '';
    }
    return '';
  }
}

/// Argumentos mínimos para rotas secundárias de um plano já pertencente ao
/// usuário autenticado. O destino resolve o plano no repositório canônico.
class PlanRouteArguments {
  const PlanRouteArguments({
    required this.planId,
    this.dayCode,
    this.exerciseId,
  });

  final String planId;
  final String? dayCode;
  final String? exerciseId;
}

class _PlanRouteUnavailablePage extends StatelessWidget {
  const _PlanRouteUnavailablePage();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    body: SafeArea(
      child: Column(
        children: [
          FitHeader(
            title: 'Plano indisponivel',
            showBackButton: true,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: FitEmptyState(
              icon: FitIcons.workout,
              title: 'Plano nao encontrado',
              description: 'Abra seus planos e escolha um item disponivel.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _WorkoutHistoryFilter {
  const _WorkoutHistoryFilter({this.planId, this.workoutId});

  final String? planId;
  final String? workoutId;
}
