import 'package:flutter/widgets.dart';

import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/section_router.dart';

/// Rotas oficiais e reservadas do módulo Planos.
abstract final class PlansRoutes {
  static const root = '/plans';
  static const create = '/plans/create';
  static const createWithAi = '/plans/create/ai';
  static const createManual = '/plans/create/manual';
  static const detail = '/plans/detail';
  static const weeks = '/plans/weeks';
  static const workoutDay = '/plans/workout-day';
  static const exercise = '/plans/exercise';
  static const session = '/plans/session';
  static const completion = '/plans/completion';
  static const readyPlans = '/plans/ready';

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
  };

  static SectionRouter createRouter({required WidgetBuilder rootBuilder}) {
    return SectionRouter(
      section: AppShellSection.plans,
      rootBuilder: rootBuilder,
      declaredRoutes: declared,
    );
  }
}
