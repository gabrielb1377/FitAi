import 'package:flutter/widgets.dart';

import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/section_router.dart';

/// Rotas oficiais e reservadas do hub Atividades.
abstract final class ActivitiesRoutes {
  static const root = '/activities';
  static const weeklySummary = '/activities/weekly-summary';
  static const challenges = '/activities/challenges';
  static const reports = '/activities/reports';
  static const history = '/activities/history';
  static const goals = '/activities/goals';
  static const running = '/activities/running';
  static const steps = '/activities/steps';

  static const declared = <String>{
    root,
    weeklySummary,
    challenges,
    reports,
    history,
    goals,
    running,
    steps,
  };

  static SectionRouter createRouter({required WidgetBuilder rootBuilder}) {
    return SectionRouter(
      section: AppShellSection.activities,
      rootBuilder: rootBuilder,
      declaredRoutes: declared,
    );
  }
}
