import 'package:flutter/widgets.dart';

import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/section_router.dart';

/// Rotas nomeadas reservadas para o módulo Home.
abstract final class HomeRoutes {
  static const root = '/home';
  static const overview = '/home/overview';
  static const todayWorkout = '/home/today-workout';
  static const suggestedPlans = '/home/suggested-plans';
  static const upcomingWorkouts = '/home/upcoming-workouts';
  static const coach = '/home/coach';
  static const goals = '/home/goals';
  static const achievements = '/home/achievements';
  static const calendar = '/home/calendar';
  static const progress = '/home/progress';
  static const recentActivity = '/home/recent-activity';
  static const reminders = '/home/reminders';
  static const notifications = '/home/notifications';
  static const records = '/home/records';
  static const weeklyChallenges = '/home/weekly-challenges';
  static const dailySummary = '/home/daily-summary';
  static const customize = '/home/customize';

  static const declared = <String>{
    root,
    overview,
    todayWorkout,
    suggestedPlans,
    upcomingWorkouts,
    coach,
    goals,
    achievements,
    calendar,
    progress,
    recentActivity,
    reminders,
    notifications,
    records,
    weeklyChallenges,
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
