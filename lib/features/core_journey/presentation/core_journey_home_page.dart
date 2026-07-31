import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../design_system/design_system.dart';
import '../../workout_vertical_slice/domain/workout_vertical_models.dart';
import 'core_journey_controller.dart';
import 'core_journey_summary_page.dart';
import 'core_journey_scope.dart';
import 'core_journey_ui.dart';
import 'core_journey_workout_page.dart';

class CoreJourneyHomePage extends StatelessWidget {
  const CoreJourneyHomePage({
    super.key,
    required this.controller,
    required this.onOpenPlans,
  });

  final CoreJourneyController controller;
  final VoidCallback onOpenPlans;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (controller.isLoading) {
        return const FitLoading.fullScreen(label: 'Carregando Home');
      }
      if (!controller.isReady || controller.hasInitializationError) {
        return CoreJourneyPageFrame(
          title: 'Home',
          child: FitErrorState(
            title: 'Sessao necessaria',
            error:
                controller.initializationErrorMessage ??
                controller.errorMessage ??
                'Entre para acessar seus treinos.',
            onRetry: controller.initialize,
          ),
        );
      }
      return CoreJourneyPageFrame(
        title: 'Ola, ${controller.identity!.name}',
        subtitle: 'Seu proximo passo esta aqui.',
        child: RefreshIndicator(
          onRefresh: controller.initialize,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              FitSpacing.s16,
              FitSpacing.s4,
              FitSpacing.s16,
              FitSpacing.s32,
            ),
            children: [
              CoreJourneySyncBanner(controller: controller),
              if (controller.hasPendingSync ||
                  controller.hasSyncIssue ||
                  controller.isOffline)
                const SizedBox(height: FitSpacing.s16),
              _PrimaryWorkoutCard(
                controller: controller,
                onOpenPlans: onOpenPlans,
                onOpenWorkout: (session) => _openWorkout(context, session),
              ),
              const SizedBox(height: FitSpacing.s24),
              _RecentActivityCard(
                controller: controller,
                onOpenSummary: (session) => _openSummary(context, session),
              ),
            ],
          ),
        ),
      );
    },
  );

  void _openWorkout(BuildContext context, WorkoutSessionLocal session) {
    if (CoreJourneyScope.maybeOf(context) != null) {
      Navigator.of(
        context,
      ).pushNamed<void>(AppRoutes.coreWorkout, arguments: session.id);
      return;
    }
    final plan = controller.planById(session.planId);
    if (plan == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CoreJourneyWorkoutPage(
          controller: controller,
          plan: plan,
          sessionId: session.id,
        ),
      ),
    );
  }

  void _openSummary(BuildContext context, WorkoutSessionLocal session) {
    final scope = CoreJourneyScope.maybeOf(context);
    if (scope != null) {
      scope.onOpenWorkoutHistory(session.id);
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CoreJourneySummaryPage(
          controller: controller,
          sessionId: session.id,
        ),
      ),
    );
  }
}

class _PrimaryWorkoutCard extends StatelessWidget {
  const _PrimaryWorkoutCard({
    required this.controller,
    required this.onOpenPlans,
    required this.onOpenWorkout,
  });

  final CoreJourneyController controller;
  final VoidCallback onOpenPlans;
  final ValueChanged<WorkoutSessionLocal> onOpenWorkout;

  @override
  Widget build(BuildContext context) {
    final active = controller.activeSession;
    final plan = active == null
        ? controller.plans.firstOrNull
        : controller.planById(active.planId);
    if (plan == null) {
      return FitEmptyState(
        icon: FitIcons.plans,
        title: 'Nenhum plano ativo',
        description: 'Escolha um plano para iniciar seu primeiro treino.',
        actionLabel: 'Ver planos',
        onAction: onOpenPlans,
      );
    }
    return FitCard(
      variant: FitCardVariant.elevated,
      title: active == null ? 'Treino de hoje' : 'Treino em andamento',
      subtitle: plan.nome,
      semanticLabel: active == null
          ? 'Treino de hoje: ${plan.nome}. Abrir plano.'
          : 'Treino em andamento: ${plan.nome}. Continuar treino.',
      leading: Icon(active == null ? FitIcons.workout : FitIcons.timer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active == null
                ? '${plan.divisao}  |  ${plan.tempoEstimado} min estimados'
                : '${controller.setsFor(active.id).length} series registradas nesta sessao',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: FitSpacing.s16),
          FitPrimaryButton(
            label: active == null ? 'Abrir plano' : 'Continuar treino',
            icon: active == null ? FitIcons.plans : FitIcons.play,
            fullWidth: true,
            onPressed: active == null
                ? onOpenPlans
                : () => onOpenWorkout(active),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.controller,
    required this.onOpenSummary,
  });

  final CoreJourneyController controller;
  final ValueChanged<WorkoutSessionLocal> onOpenSummary;

  @override
  Widget build(BuildContext context) {
    final latest = controller.completedSessions.firstOrNull;
    return FitCard(
      title: 'Atividade recente',
      subtitle: latest == null ? 'Seu primeiro treino aparecera aqui.' : null,
      semanticLabel: latest == null
          ? 'Atividade recente. Nenhum treino concluido.'
          : 'Atividade recente: ${controller.planById(latest.planId)?.nome ?? 'Treino'}, ${controller.setsFor(latest.id).length} series. Abrir resumo.',
      trailing: latest == null ? null : const Icon(FitIcons.forward),
      onTap: latest == null ? null : () => onOpenSummary(latest),
      variant: latest == null
          ? FitCardVariant.standard
          : FitCardVariant.clickable,
      child: latest == null
          ? const Text(
              'Registre suas series mesmo offline; o historico fica no dispositivo.',
            )
          : Text(
              '${controller.planById(latest.planId)?.nome ?? 'Treino'}  |  ${controller.setsFor(latest.id).length} series  |  ${formatCoreDuration(controller.durationFor(latest))}',
            ),
    );
  }
}
