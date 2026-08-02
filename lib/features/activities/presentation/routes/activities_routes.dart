import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/deep_link.dart';
import '../../../../core/navigation/section_router.dart';
import '../../../../screens/corridas/corrida_detalhe_page.dart';
import '../../../../screens/corridas/corridas_page.dart';
import '../../../core_journey/presentation/core_journey_route_pages.dart';
import '../../../core_journey/presentation/core_journey_scope.dart';

/// Rotas de movimento. Treinos de musculacao pertencem ao modulo Planos.
abstract final class ActivitiesRoutes {
  static const root = AppRoutes.activities;
  static const runs = AppRoutes.activitiesRuns;
  static const runDetail = AppRoutes.activityRunDetail;
  static const steps = AppRoutes.activitiesSteps;
  static const stepsByDate = AppRoutes.activityStepsByDate;

  /// Mantida para links antigos. O destino final e o historico em Planos.
  static const legacyWorkoutHistory = AppRoutes.legacyActivitiesWorkoutHistory;
  static const legacyRunning = '/activities/running';

  static const declared = <String>{
    root,
    runs,
    runDetail,
    steps,
    stepsByDate,
    legacyWorkoutHistory,
    legacyRunning,
  };

  static SectionRouter createRouter({required WidgetBuilder rootBuilder}) {
    return SectionRouter(
      section: AppShellSection.activities,
      rootBuilder: rootBuilder,
      routes: {
        runs: (_, _) => const CorridasPage(),
        runDetail: (_, settings) =>
            CorridaDetalhePorIdPage(runId: _runId(settings.arguments)),
        legacyWorkoutHistory: (_, settings) =>
            _LegacyWorkoutHistoryRedirectPage(arguments: settings.arguments),
      },
      declaredRoutes: declared,
    );
  }

  static String _runId(Object? arguments) {
    if (arguments is String) return arguments.trim();
    if (arguments is AppDeepLinkTarget) {
      final segments = <String>[
        if (arguments.uri.scheme == 'fitia' && arguments.uri.host.isNotEmpty)
          arguments.uri.host,
        ...arguments.uri.pathSegments,
      ];
      if (segments.length >= 3 && segments[1].toLowerCase() == 'runs') {
        return segments[2];
      }
      return arguments.uri.queryParameters['id']?.trim() ?? '';
    }
    return '';
  }
}

class _LegacyWorkoutHistoryRedirectPage extends StatefulWidget {
  const _LegacyWorkoutHistoryRedirectPage({required this.arguments});

  final Object? arguments;

  @override
  State<_LegacyWorkoutHistoryRedirectPage> createState() =>
      _LegacyWorkoutHistoryRedirectPageState();
}

class _LegacyWorkoutHistoryRedirectPageState
    extends State<_LegacyWorkoutHistoryRedirectPage> {
  var _redirected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_redirected) return;
    _redirected = true;
    final sessionId = coreJourneyRouteId(widget.arguments);
    final scope = CoreJourneyScope.maybeOf(context);
    if (sessionId == null || scope == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) scope.onOpenPlanWorkoutHistory(sessionId);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(child: Center(child: CircularProgressIndicator())),
  );
}
