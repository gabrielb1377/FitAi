import 'package:flutter/widgets.dart';

import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/section_router.dart';

/// Rotas nomeadas reservadas para o módulo Home.
abstract final class HomeRoutes {
  static const root = '/home';
  static const coach = '/home/coach';
  static const goals = '/home/goals';
  static const achievements = '/home/achievements';
  static const notifications = '/home/notifications';
  static const dailySummary = '/home/daily-summary';
  static const customize = '/home/customize';

  static const declared = <String>{
    root,
    coach,
    goals,
    achievements,
    notifications,
    dailySummary,
    customize,
  };

  static SectionRouter createRouter({required WidgetBuilder rootBuilder}) {
    return SectionRouter(
      section: AppShellSection.home,
      rootBuilder: rootBuilder,
      declaredRoutes: declared,
    );
  }
}
