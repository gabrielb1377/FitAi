import 'package:flutter/foundation.dart';

import 'app_routes.dart';
import 'app_section.dart';

/// Destino validado de um deep link, ainda sem executar navegação.
@immutable
class AppDeepLinkTarget {
  const AppDeepLinkTarget({
    required this.uri,
    required this.section,
    required this.routeName,
  });

  final Uri uri;
  final AppShellSection section;
  final String routeName;

  bool get opensSectionRoot => routeName == section.rootRoute;
}

/// Parser puro para links `fitia://` e caminhos web.
///
/// A autenticação continua responsável por decidir quando um link pode ser
/// entregue ao shell.
abstract final class AppDeepLinkParser {
  static AppDeepLinkTarget? parse(Uri uri) {
    final segments = <String>[
      if (uri.scheme == 'fitia' && uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ].where((segment) => segment.trim().isNotEmpty).toList();
    if (segments.isEmpty) return null;

    final firstSegment = segments.first.toLowerCase();
    if (firstSegment == 'workout' && segments.length >= 2) {
      final isSummary =
          segments.length >= 3 && segments.last.toLowerCase() == 'summary';
      return AppDeepLinkTarget(
        uri: uri,
        section: AppShellSection.plans,
        routeName: isSummary
            ? AppRoutes.coreWorkoutSummary
            : AppRoutes.coreWorkout,
      );
    }

    final section = AppShellSection.fromSlug(firstSegment);
    if (section == null) return null;

    if (section == AppShellSection.activities &&
        segments.length >= 3 &&
        segments[1].toLowerCase() == 'workout') {
      return AppDeepLinkTarget(
        uri: uri,
        section: AppShellSection.plans,
        routeName: AppRoutes.corePlanWorkoutHistory,
      );
    }

    if (section == AppShellSection.activities &&
        segments.length >= 3 &&
        segments[1].toLowerCase() == 'runs') {
      return AppDeepLinkTarget(
        uri: uri,
        section: section,
        routeName: AppRoutes.activityRunDetail,
      );
    }

    if (section == AppShellSection.activities &&
        segments.length >= 3 &&
        segments[1].toLowerCase() == 'steps') {
      return AppDeepLinkTarget(
        uri: uri,
        section: section,
        routeName: AppRoutes.activityStepsByDate,
      );
    }

    if (section == AppShellSection.plans &&
        segments.length >= 3 &&
        segments[2].toLowerCase() == 'history') {
      return AppDeepLinkTarget(
        uri: uri,
        section: section,
        routeName: AppRoutes.corePlanHistory,
      );
    }

    if (section == AppShellSection.plans &&
        segments.length >= 5 &&
        segments[2].toLowerCase() == 'workouts' &&
        segments[4].toLowerCase() == 'history') {
      return AppDeepLinkTarget(
        uri: uri,
        section: section,
        routeName: AppRoutes.corePlanHistory,
      );
    }

    if (section == AppShellSection.plans &&
        segments.length == 2 &&
        !_knownPlansRoute(segments[1])) {
      return AppDeepLinkTarget(
        uri: uri,
        section: section,
        routeName: AppRoutes.corePlanDetail,
      );
    }

    final suffix = segments.skip(1).map(Uri.decodeComponent).join('/');
    final routeName = suffix.isEmpty
        ? section.rootRoute
        : '${section.rootRoute}/$suffix';
    return AppDeepLinkTarget(uri: uri, section: section, routeName: routeName);
  }

  static bool _knownPlansRoute(String value) {
    const knownRoutes = {
      'create',
      'detail',
      'weeks',
      'workout-day',
      'exercise',
      'session',
      'completion',
      'ready',
      'statistics',
      'calendar',
      'compare',
      'history',
      'import-share',
      'archive',
    };
    return knownRoutes.contains(value.toLowerCase());
  }
}
