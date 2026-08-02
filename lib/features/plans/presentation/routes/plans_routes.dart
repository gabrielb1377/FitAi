import 'package:flutter/widgets.dart';

import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/deep_link.dart';
import '../../../../core/navigation/section_router.dart';
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
  static const create = '/plans/create';
  static const createWithAi = '/plans/create/ai';
  static const createManual = '/plans/create/manual';
  static const detail = AppRoutes.corePlanDetail;
  static const weeks = '/plans/weeks';
  static const workoutDay = '/plans/workout-day';
  static const exercise = '/plans/exercise';
  static const session = AppRoutes.coreWorkout;
  static const completion = AppRoutes.coreWorkoutSummary;
  static const readyPlans = '/plans/ready';
  static const statistics = '/plans/statistics';
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
        createWithAi: (_, _) => const PlanosAiGoalPage(),
        createManual: (_, _) => const PlanosManualGoalPage(),
        readyPlans: (_, _) => const PlanosReadyLibraryPage(),
        calendar: (_, _) => const PlanosCalendarPage(),
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

class _WorkoutHistoryFilter {
  const _WorkoutHistoryFilter({this.planId, this.workoutId});

  final String? planId;
  final String? workoutId;
}
