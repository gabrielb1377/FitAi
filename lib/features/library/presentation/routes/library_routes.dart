import 'package:flutter/widgets.dart';

import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/section_router.dart';

/// Rotas oficiais e reservadas da Biblioteca.
abstract final class LibraryRoutes {
  static const root = '/library';
  static const search = '/library/search';
  static const exercise = '/library/exercise';
  static const execution = '/library/exercise/execution';
  static const muscles = '/library/muscles';
  static const favorites = '/library/favorites';
  static const filters = '/library/filters';
  static const history = '/library/history';
  static const nutrition = '/library/nutrition';

  static const declared = <String>{
    root,
    search,
    exercise,
    execution,
    muscles,
    favorites,
    filters,
    history,
    nutrition,
  };

  static SectionRouter createRouter({required WidgetBuilder rootBuilder}) {
    return SectionRouter(
      section: AppShellSection.library,
      rootBuilder: rootBuilder,
      declaredRoutes: declared,
    );
  }
}
