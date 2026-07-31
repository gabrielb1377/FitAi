import 'package:flutter/widgets.dart';

import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/section_router.dart';
import '../../../core_journey/presentation/core_journey_route_pages.dart';
import '../pages/planos_official_library_page.dart';
import '../pages/planos_official_plan_pages.dart';
import '../pages/planos_official_wizards.dart';

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
  static const history = '/plans/history';
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
        history: (_, _) => const PlanosHistoryPage(),
        importShare: (_, _) => const PlanosImportSharePage(),
        archive: (_, _) => const PlanosArchivePage(),
      },
      declaredRoutes: declared,
    );
  }
}
