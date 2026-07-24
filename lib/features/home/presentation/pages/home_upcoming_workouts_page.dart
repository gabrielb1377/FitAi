import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/treino_model.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

class HomeUpcomingWorkoutsPage extends StatelessWidget {
  const HomeUpcomingWorkoutsPage({
    super.key,
    required this.plans,
    required this.onOpenWorkout,
    required this.onOpenCalendar,
  });

  final List<TreinoModel> plans;
  final ValueChanged<TreinoModel> onOpenWorkout;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final items = _scheduledItems();
    return HomeDetailScaffold(
      title: 'Próximos treinos',
      subtitle: '',
      actions: [
        FitIconButton(
          icon: FitIcons.calendar,
          tooltip: 'Abrir calendário',
          onPressed: onOpenCalendar,
        ),
      ],
      child: HomePageBody(
        children: [
          if (items.isEmpty)
            FitEmptyState(
              icon: FitIcons.calendar,
              title: 'Nenhum treino programado',
              description:
                  'Seus próximos treinos aparecerão aqui quando houver um plano.',
            )
          else ...[
            const FitSectionHeader(title: 'Esta semana'),
            const SizedBox(height: FitSpacing.s12),
            for (final item in items.take(3)) ...[
              _UpcomingWorkoutCard(
                item: item,
                onTap: () => onOpenWorkout(item.workout),
              ),
              const SizedBox(height: FitSpacing.s8),
            ],
            if (items.length > 3) ...[
              const HomeSectionGap(),
              const FitSectionHeader(title: 'Próxima semana'),
              const SizedBox(height: FitSpacing.s12),
              for (final item in items.skip(3).take(3)) ...[
                _UpcomingWorkoutCard(
                  item: item,
                  onTap: () => onOpenWorkout(item.workout),
                ),
                const SizedBox(height: FitSpacing.s8),
              ],
            ],
            const SizedBox(height: FitSpacing.s8),
            FitOutlinedButton(
              label: 'Ver todos os treinos',
              icon: FitIcons.calendarRange,
              fullWidth: true,
              onPressed: onOpenCalendar,
            ),
          ],
        ],
      ),
    );
  }

  List<_ScheduledWorkout> _scheduledItems() {
    final items = <_ScheduledWorkout>[];
    var dayOffset = 0;
    for (final plan in plans) {
      final days =
          plan.planoDias.isEmpty
                ? [
                    TreinoDiaModel(
                      codigo: plan.diaPlano.trim().isEmpty
                          ? 'A'
                          : plan.diaPlano,
                      nome: plan.grupoDia.trim().isEmpty
                          ? plan.nome
                          : plan.grupoDia,
                      ordem: plan.ordemDia <= 0 ? 1 : plan.ordemDia,
                      exercicioIds: plan.exercicios
                          .map((exercise) => exercise.id)
                          .toList(),
                    ),
                  ]
                : [...plan.planoDias]
            ..sort((a, b) => a.ordem.compareTo(b.ordem));
      for (final day in days) {
        final date = DateTime.now().add(Duration(days: dayOffset++));
        items.add(_ScheduledWorkout(date: date, workout: plan.somenteDia(day)));
      }
    }
    return items.take(6).toList();
  }
}

class _ScheduledWorkout {
  const _ScheduledWorkout({required this.date, required this.workout});

  final DateTime date;
  final TreinoModel workout;
}

class _UpcomingWorkoutCard extends StatelessWidget {
  const _UpcomingWorkoutCard({required this.item, required this.onTap});

  final _ScheduledWorkout item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final workout = item.workout;
    final media = workout.exercicios.firstOrNull?.imagem.trim() ?? '';
    return FitCard(
      onTap: onTap,
      variant: FitCardVariant.clickable,
      padding: const EdgeInsets.all(FitSpacing.s8),
      semanticLabel:
          '${_weekday(item.date)}, ${workout.nome}, ${workout.tempoEstimado} minutos',
      child: Row(
        children: [
          SizedBox.square(
            dimension: FitLayout.domainThumbnail,
            child: ClipRRect(
              borderRadius: FitRadius.mediumBorder,
              child: media.isEmpty
                  ? const ColoredBox(
                      color: FitColors.cardInner,
                      child: Icon(FitIcons.workout, color: FitColors.primary),
                    )
                  : Image.asset(
                      media,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: FitColors.cardInner,
                        child: Icon(FitIcons.workout, color: FitColors.primary),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_weekday(item.date)} · 18:00',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: FitColors.primary,
                  ),
                ),
                const SizedBox(height: FitSpacing.s2),
                Text(
                  workout.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall,
                ),
                const SizedBox(height: FitSpacing.s2),
                Text(
                  '${workout.exercicios.length} exercícios · ${workout.tempoEstimado} min',
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            FitIcons.forward,
            color: FitColors.primary,
            size: FitLayout.iconSizeMedium,
          ),
        ],
      ),
    );
  }

  String _weekday(DateTime value) {
    const labels = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    return labels[value.weekday - 1];
  }
}
