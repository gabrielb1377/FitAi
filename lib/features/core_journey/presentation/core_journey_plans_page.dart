import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../design_system/design_system.dart';
import '../../../models/treino_model.dart';
import '../../workout_vertical_slice/domain/workout_vertical_models.dart';
import 'core_journey_controller.dart';
import 'core_journey_scope.dart';
import 'core_journey_ui.dart';
import 'core_journey_workout_page.dart';

class CoreJourneyPlansPage extends StatelessWidget {
  const CoreJourneyPlansPage({super.key, required this.controller});

  final CoreJourneyController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (controller.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return CoreJourneyPageFrame(
        title: 'Meus Planos',
        subtitle:
            '${controller.plans.length} plano${controller.plans.length == 1 ? '' : 's'} disponivel${controller.plans.length == 1 ? '' : 'is'}',
        child: controller.plans.isEmpty
            ? FitEmptyState(
                icon: FitIcons.plans,
                title: 'Nenhum plano disponivel',
                description:
                    'Crie ou adicione um plano antes de iniciar um treino.',
                actionLabel: 'Atualizar',
                onAction: controller.initialize,
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  FitSpacing.s16,
                  FitSpacing.s4,
                  FitSpacing.s16,
                  FitSpacing.s32,
                ),
                itemCount: controller.plans.length + 1,
                separatorBuilder: (_, index) => SizedBox(
                  height: index == 0 ? FitSpacing.s16 : FitSpacing.s12,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return CoreJourneySyncBanner(controller: controller);
                  }
                  final plan = controller.plans[index - 1];
                  return _PlanRow(
                    plan: plan,
                    active: controller.activeSession?.planId == plan.id,
                    onTap: () => _openDetail(context, plan),
                  );
                },
              ),
      );
    },
  );

  void _openDetail(BuildContext context, TreinoModel plan) {
    if (CoreJourneyScope.maybeOf(context) != null) {
      Navigator.of(
        context,
      ).pushNamed<void>(AppRoutes.corePlanDetail, arguments: plan.id);
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            CoreJourneyPlanDetailPage(controller: controller, plan: plan),
      ),
    );
  }
}

class CoreJourneyPlanDetailPage extends StatelessWidget {
  const CoreJourneyPlanDetailPage({
    super.key,
    required this.controller,
    required this.plan,
  });

  final CoreJourneyController controller;
  final TreinoModel plan;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final active = controller.activeSession;
      final isCurrentPlan = active?.planId == plan.id;
      return CoreJourneyPageFrame(
        title: plan.nome,
        subtitle: '${plan.objetivo}  |  ${plan.divisao}',
        showBackButton: true,
        onBack: () => Navigator.of(context).maybePop(),
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
            FitCard(
              variant: FitCardVariant.elevated,
              title: isCurrentPlan ? 'Treino em andamento' : 'Proximo treino',
              subtitle:
                  '${plan.tempoEstimado} min  |  ${plan.diasPorSemana} dias por semana',
              semanticLabel: isCurrentPlan
                  ? 'Treino em andamento no plano ${plan.nome}. Continuar treino.'
                  : 'Proximo treino do plano ${plan.nome}. Iniciar treino.',
              leading: Icon(isCurrentPlan ? FitIcons.timer : FitIcons.calendar),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.descricao.isEmpty
                        ? 'Rotina pronta para seu proximo treino.'
                        : plan.descricao,
                  ),
                  const SizedBox(height: FitSpacing.s16),
                  FitPrimaryButton(
                    label: isCurrentPlan
                        ? 'Continuar treino'
                        : 'Iniciar treino',
                    icon: isCurrentPlan ? FitIcons.play : FitIcons.add,
                    fullWidth: true,
                    onPressed: () => _startOrContinue(context, active),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            Text('Exercicios', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: FitSpacing.s12),
            if (plan.exercicios.isEmpty)
              const FitEmptyState(
                icon: FitIcons.exercise,
                title: 'Plano sem exercicios',
                description:
                    'Este plano ainda nao possui exercicios para iniciar.',
              )
            else
              for (final exercise in plan.exercicios) ...[
                FitCard(
                  title: exercise.nome,
                  subtitle: exercise.musculos.join(', '),
                  leading: const Icon(FitIcons.exercise),
                  child: Text(
                    '${exercise.series} series  |  ${exercise.repeticoes} reps  |  ${exercise.descansoSegundos}s descanso',
                  ),
                ),
                const SizedBox(height: FitSpacing.s8),
              ],
          ],
        ),
      );
    },
  );

  Future<void> _startOrContinue(
    BuildContext context,
    WorkoutSessionLocal? active,
  ) async {
    if (active != null && active.planId != plan.id) {
      final previousFocus = FocusManager.instance.primaryFocus;
      final continueExisting = await showDialog<bool>(
        context: context,
        traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
        requestFocus: true,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Ha um treino em andamento'),
          content: const Text(
            'Continue a sessao atual antes de iniciar outro treino.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continuar treino'),
            ),
          ],
        ),
      );
      if (continueExisting != true) {
        if (context.mounted && (previousFocus?.canRequestFocus ?? false)) {
          previousFocus!.requestFocus();
        }
        return;
      }
      if (!context.mounted) return;
      final existingPlan = controller.planById(active.planId);
      if (existingPlan == null) return;
      _openWorkout(context, existingPlan, active.id);
      return;
    }

    final session = active ?? await controller.startPlan(plan);
    if (!context.mounted || session == null) return;
    _openWorkout(context, plan, session.id);
  }

  void _openWorkout(BuildContext context, TreinoModel plan, String sessionId) {
    if (CoreJourneyScope.maybeOf(context) != null) {
      Navigator.of(
        context,
      ).pushNamed<void>(AppRoutes.coreWorkout, arguments: sessionId);
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CoreJourneyWorkoutPage(
          controller: controller,
          plan: plan,
          sessionId: sessionId,
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.active,
    required this.onTap,
  });

  final TreinoModel plan;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FitCard(
    variant: FitCardVariant.clickable,
    selected: active,
    title: plan.nome,
    subtitle: '${plan.objetivo}  |  ${plan.divisao}',
    semanticLabel:
        '${plan.nome}. ${plan.objetivo}. ${plan.divisao}. ${plan.exercicios.length} exercicios. ${active ? 'Treino em andamento.' : 'Abrir detalhes do plano.'}',
    leading: Icon(active ? FitIcons.play : FitIcons.plans),
    trailing: active
        ? const FitChip(label: 'Em andamento', selected: true)
        : const Icon(FitIcons.forward),
    onTap: onTap,
    child: Text(
      '${plan.diasPorSemana} dias por semana  |  ${plan.exercicios.length} exercicios',
    ),
  );
}
