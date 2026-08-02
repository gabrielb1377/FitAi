import 'package:flutter/widgets.dart';

import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/section_router.dart';
import '../../../core_journey/presentation/core_journey_route_pages.dart';
import '../../../core_journey/presentation/core_journey_scope.dart';
import '../../domain/activity_history_models.dart';
import '../controllers/activities_history_controller.dart';
import '../pages/activity_history_pages.dart';

/// Rotas oficiais e reservadas do hub Atividades.
abstract final class ActivitiesRoutes {
  static const root = '/activities';
  static const weeklySummary = '/activities/weekly-summary';
  static const challenges = '/activities/challenges';
  static const reports = '/activities/reports';
  static const history = '/activities/history';
  static const calendar = '/activities/calendar';
  static const search = '/activities/search';
  static const detail = '/activities/history/detail';
  static const goals = '/activities/goals';
  static const running = '/activities/running';
  static const steps = '/activities/steps';
  static const workout = AppRoutes.coreWorkoutHistory;

  static const declared = <String>{
    root,
    weeklySummary,
    challenges,
    reports,
    history,
    calendar,
    search,
    detail,
    goals,
    running,
    steps,
    workout,
  };

  static SectionRouter createRouter({required WidgetBuilder rootBuilder}) {
    return SectionRouter(
      section: AppShellSection.activities,
      rootBuilder: rootBuilder,
      routes: {
        workout: (_, settings) =>
            CoreJourneySummaryRoutePage(arguments: settings.arguments),
        history: (context, _) => ActivitiesTimelinePage(
          loadHistory: _historyLoader(context),
          source: _historySource(context),
        ),
        calendar: (context, _) => ActivitiesCalendarPage(
          loadHistory: _historyLoader(context),
          source: _historySource(context),
        ),
        search: (context, _) => ActivitiesSearchPage(
          loadHistory: _historyLoader(context),
          source: _historySource(context),
        ),
        detail: (context, settings) => ActivityWorkoutDetailPage(
          sessionId: settings.arguments is String
              ? settings.arguments! as String
              : '',
          loadHistory: _historyLoader(context),
          source: _historySource(context),
        ),
      },
      declaredRoutes: declared,
    );
  }

  static ActivitiesHistoryLoader _historyLoader(BuildContext context) {
    final controller = CoreJourneyScope.maybeOf(context)?.notifier;
    return () async {
      if (controller == null || !controller.isReady) {
        return const WorkoutActivityHistorySnapshot.empty();
      }
      return controller.loadActivityHistory();
    };
  }

  static Listenable? _historySource(BuildContext context) =>
      CoreJourneyScope.maybeOf(context)?.notifier;
}
