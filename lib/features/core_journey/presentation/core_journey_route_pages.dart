import 'package:flutter/material.dart';

import '../../../core/navigation/deep_link.dart';
import '../../../design_system/design_system.dart';
import 'core_journey_plans_page.dart';
import 'core_journey_scope.dart';
import 'core_journey_summary_page.dart';
import 'core_journey_ui.dart';
import 'core_journey_workout_page.dart';

/// Resolve os IDs das rotas publicas do Core V1 para as paginas que usam o
/// controller compartilhado pelo App Shell. Nenhuma pagina cria repositorio ou
/// armazenamento proprio.
class CoreJourneyPlanDetailRoutePage extends StatelessWidget {
  const CoreJourneyPlanDetailRoutePage({super.key, required this.arguments});

  final Object? arguments;

  @override
  Widget build(BuildContext context) {
    final scope = CoreJourneyScope.maybeOf(context);
    final planId = coreJourneyRouteId(arguments);
    if (scope == null || planId == null) {
      return const _UnavailableCoreJourneyRoutePage(
        title: 'Plano indisponivel',
        description: 'Abra seus planos para selecionar um plano valido.',
      );
    }
    final controller = scope.notifier!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading) return const _CoreJourneyRouteLoading();
        final plan = controller.planById(planId);
        if (plan == null) {
          return const _UnavailableCoreJourneyRoutePage(
            title: 'Plano nao encontrado',
            description: 'Este plano nao esta disponivel neste dispositivo.',
          );
        }
        return CoreJourneyPlanDetailPage(controller: controller, plan: plan);
      },
    );
  }
}

class CoreJourneyWorkoutRoutePage extends StatelessWidget {
  const CoreJourneyWorkoutRoutePage({super.key, required this.arguments});

  final Object? arguments;

  @override
  Widget build(BuildContext context) {
    final scope = CoreJourneyScope.maybeOf(context);
    final sessionId = coreJourneyRouteId(arguments);
    if (scope == null || sessionId == null) {
      return const _UnavailableCoreJourneyRoutePage(
        title: 'Treino indisponivel',
        description: 'Abra seus planos para iniciar ou continuar um treino.',
      );
    }
    final controller = scope.notifier!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading) return const _CoreJourneyRouteLoading();
        final session = controller.sessionById(sessionId);
        final plan = session == null
            ? null
            : controller.planById(session.planId);
        if (session == null || plan == null) {
          return const _UnavailableCoreJourneyRoutePage(
            title: 'Sessao nao encontrada',
            description: 'Esta sessao nao esta disponivel neste dispositivo.',
          );
        }
        return CoreJourneyWorkoutPage(
          controller: controller,
          plan: plan,
          sessionId: session.id,
        );
      },
    );
  }
}

class CoreJourneySummaryRoutePage extends StatelessWidget {
  const CoreJourneySummaryRoutePage({super.key, required this.arguments});

  final Object? arguments;

  @override
  Widget build(BuildContext context) {
    final scope = CoreJourneyScope.maybeOf(context);
    final sessionId = coreJourneyRouteId(arguments);
    if (scope == null || sessionId == null) {
      return const _UnavailableCoreJourneyRoutePage(
        title: 'Resumo indisponivel',
        description: 'Abra o historico para selecionar um treino concluido.',
      );
    }
    return CoreJourneySummaryPage(
      controller: scope.notifier!,
      sessionId: sessionId,
    );
  }
}

String? coreJourneyRouteId(Object? arguments) {
  if (arguments is String && arguments.trim().isNotEmpty) {
    return arguments.trim();
  }
  if (arguments is AppDeepLinkTarget) {
    final queryId = arguments.uri.queryParameters['id'];
    if (queryId != null && queryId.trim().isNotEmpty) return queryId;
    final segments = <String>[
      if (arguments.uri.scheme == 'fitia' && arguments.uri.host.isNotEmpty)
        arguments.uri.host,
      ...arguments.uri.pathSegments,
    ];
    if (segments.isNotEmpty) {
      if (segments.first.toLowerCase() == 'plans' && segments.length >= 2) {
        return segments[1];
      }
      if (segments.first.toLowerCase() == 'workout' && segments.length >= 2) {
        return segments[1];
      }
      if (segments.first.toLowerCase() == 'activities' &&
          segments.length >= 3 &&
          segments[1].toLowerCase() == 'workout') {
        return segments[2];
      }
    }
    return arguments.uri.queryParameters['id'];
  }
  return null;
}

class _CoreJourneyRouteLoading extends StatelessWidget {
  const _CoreJourneyRouteLoading();

  @override
  Widget build(BuildContext context) => const CoreJourneyPageFrame(
    title: 'Carregando',
    child: FitLoading.fullScreen(label: 'Carregando jornada'),
  );
}

class _UnavailableCoreJourneyRoutePage extends StatelessWidget {
  const _UnavailableCoreJourneyRoutePage({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => CoreJourneyPageFrame(
    title: title,
    showBackButton: true,
    onBack: () => Navigator.of(context).maybePop(),
    child: FitEmptyState(
      icon: FitIcons.history,
      title: title,
      description: description,
    ),
  );
}
