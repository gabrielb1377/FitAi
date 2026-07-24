import 'package:flutter/material.dart';

import '../../../../core/design_system/components/domain/shared/fit_domain_primitives.dart';
import '../../../../design_system/fit_design_system.dart';
import '../../../../models/coach_insight_model.dart';
import '../../../../models/treino_model.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

class HomeTodayWorkoutPage extends StatelessWidget {
  const HomeTodayWorkoutPage({
    super.key,
    required this.workout,
    required this.insight,
    required this.onStart,
    required this.onViewExercises,
    required this.onCreatePlan,
    required this.onOpenSchedule,
    required this.onOpenSuggestedPlans,
  });

  final TreinoModel? workout;
  final CoachInsightModel? insight;
  final VoidCallback onStart;
  final VoidCallback onViewExercises;
  final VoidCallback onCreatePlan;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenSuggestedPlans;

  @override
  Widget build(BuildContext context) {
    final item = workout;
    return HomeDetailScaffold(
      title: 'Treino de hoje',
      subtitle: '',
      actions: [
        FitIconButton(
          icon: FitIcons.calendar,
          tooltip: 'Próximos treinos',
          onPressed: onOpenSchedule,
        ),
      ],
      child: item == null
          ? HomePageBody(
              children: [
                FitEmptyState(
                  icon: FitIcons.workout,
                  title: 'Nenhum treino programado',
                  description:
                      'Crie ou escolha um plano para organizar sua rotina.',
                  actionLabel: 'Criar plano',
                  onAction: onCreatePlan,
                ),
                const SizedBox(height: FitSpacing.s12),
                FitOutlinedButton(
                  label: 'Ver planos sugeridos',
                  icon: FitIcons.plans,
                  fullWidth: true,
                  onPressed: onOpenSuggestedPlans,
                ),
              ],
            )
          : HomePageBody(
              children: [
                _WorkoutHero(workout: item),
                const SizedBox(height: FitSpacing.s12),
                HomeMetricGrid(
                  items: [
                    HomeMetricItem(
                      label: 'Exercícios',
                      value: '${item.exercicios.length}',
                      icon: FitIcons.exercise,
                    ),
                    HomeMetricItem(
                      label: 'Duração',
                      value: '${item.tempoEstimado} min',
                      icon: FitIcons.time,
                    ),
                    HomeMetricItem(
                      label: 'Nível',
                      value: item.nivel,
                      icon: FitIcons.progress,
                    ),
                    HomeMetricItem(
                      label: 'Equipamentos',
                      value: '${item.equipamentos.length}',
                      icon: FitIcons.equipment,
                    ),
                  ],
                ),
                const HomeSectionGap(),
                FitCard(
                  title: 'Objetivo do treino',
                  leading: const Icon(FitIcons.goal, color: FitColors.ai),
                  variant: FitCardVariant.outlined,
                  child: Text(
                    item.descricao.trim().isEmpty
                        ? 'Treino focado em ${item.objetivo.toLowerCase()}.'
                        : item.descricao,
                    style: context.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: FitSpacing.s12),
                FitCard(
                  title: 'O que te espera',
                  variant: FitCardVariant.outlined,
                  child: Column(
                    children: [
                      _Expectation(
                        text:
                            '${item.exercicios.length} exercícios organizados',
                      ),
                      _Expectation(text: 'Foco em ${item.objetivo}'),
                      _Expectation(
                        text: item.equipamentos.isEmpty
                            ? 'Sem equipamento obrigatório'
                            : item.equipamentos.take(3).join(', '),
                      ),
                      const _Expectation(text: 'Progressão inteligente'),
                    ],
                  ),
                ),
                const SizedBox(height: FitSpacing.s16),
                FitPrimaryButton(
                  label: 'Iniciar treino',
                  icon: FitIcons.play,
                  fullWidth: true,
                  onPressed: onStart,
                ),
                const SizedBox(height: FitSpacing.s8),
                FitOutlinedButton(
                  label: 'Ver exercícios',
                  icon: FitIcons.list,
                  fullWidth: true,
                  onPressed: onViewExercises,
                ),
                const SizedBox(height: FitSpacing.s12),
                HomeListAction(
                  title: 'Dica do Coach FitIA',
                  subtitle:
                      insight?.descricao ??
                      'Respeite a técnica e mantenha o descanso planejado.',
                  icon: FitIcons.coach,
                  color: FitColors.ai,
                ),
              ],
            ),
    );
  }
}

class _WorkoutHero extends StatelessWidget {
  const _WorkoutHero({required this.workout});

  final TreinoModel workout;

  @override
  Widget build(BuildContext context) {
    final media = workout.exercicios.firstOrNull?.imagem.trim() ?? '';
    return Stack(
      children: [
        FitDomainMedia(
          aspectRatio: FitLayout.domainCompactMediaAspectRatio,
          fallbackLabel: workout.nome,
          fallbackIcon: FitIcons.workout,
          child: media.isEmpty
              ? null
              : Image.asset(
                  media,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      FitIcons.workout,
                      color: FitColors.primary,
                      size: FitLayout.iconSizeState,
                    ),
                  ),
                ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: FitRadius.mediumBorder,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  FitColors.overlay.withValues(alpha: FitOpacity.transparent),
                  FitColors.overlay,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: FitSpacing.s16,
          right: FitSpacing.s16,
          bottom: FitSpacing.s16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FitBadge(label: workout.objetivo),
              const SizedBox(height: FitSpacing.s8),
              Text(workout.nome, style: context.textTheme.headlineLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _Expectation extends StatelessWidget {
  const _Expectation({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitSpacing.s4),
      child: Row(
        children: [
          const Icon(
            FitIcons.check,
            color: FitColors.primary,
            size: FitLayout.iconSizeSmall,
          ),
          const SizedBox(width: FitSpacing.s8),
          Expanded(child: Text(text, style: context.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
