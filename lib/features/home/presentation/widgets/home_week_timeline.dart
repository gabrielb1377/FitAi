import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/historico_treino_model.dart';

/// Linha semanal compacta baseada somente no historico de musculacao recebido.
/// Corridas e passos continuam pertencendo ao destino Atividades.
class HomeWeekTimeline extends StatelessWidget {
  const HomeWeekTimeline({
    super.key,
    required this.history,
    required this.onOpenHistory,
    required this.now,
  });

  final List<HistoricoTreinoModel> history;
  final VoidCallback onOpenHistory;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final current = now().toLocal();
    final today = DateTime(current.year, current.month, current.day);
    final dates = List<DateTime>.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ultimos 7 dias',
                style: context.textTheme.titleLarge,
              ),
            ),
            TextButton(onPressed: onOpenHistory, child: const Text('Ver tudo')),
          ],
        ),
        const SizedBox(height: FitSpacing.s8),
        FitCard(
          key: const ValueKey('home-week-timeline-card'),
          onTap: onOpenHistory,
          variant: FitCardVariant.clickable,
          padding: const EdgeInsets.all(FitSpacing.s16),
          semanticLabel: 'Abrir historico dos ultimos sete dias',
          child: Row(
            children: [
              for (final date in dates)
                Expanded(
                  child: _TimelineDay(
                    date: date,
                    isToday: DateUtils.isSameDay(date, today),
                    completed: _hasWorkoutOn(date),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasWorkoutOn(DateTime date) {
    return history.any(
      (item) => DateUtils.isSameDay(item.dataHora.toLocal(), date),
    );
  }
}

class _TimelineDay extends StatelessWidget {
  const _TimelineDay({
    required this.date,
    required this.isToday,
    required this.completed,
  });

  final DateTime date;
  final bool isToday;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final label = _weekdayLabel(date.weekday);
    final status = completed
        ? 'treino registrado'
        : isToday
        ? 'hoje'
        : 'sem treino registrado';
    final fill = completed
        ? FitColors.primary
        : isToday
        ? FitColors.primaryContainer
        : FitColors.cardInner;
    final border = isToday ? FitColors.primary : FitColors.borderSubtle;
    final foreground = completed ? FitColors.onPrimary : FitColors.textTertiary;

    return Semantics(
      label: '$label, $status',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: FitLayout.avatarSmall,
              height: FitLayout.avatarSmall,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: FitLayout.borderThin),
              ),
              child: completed
                  ? const Icon(
                      FitIcons.check,
                      color: FitColors.onPrimary,
                      size: FitLayout.iconSizeSmall,
                    )
                  : Text(
                      '${date.day}',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: foreground,
                      ),
                    ),
            ),
            const SizedBox(height: FitSpacing.s8),
            Text(label, style: context.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = <String>['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    return labels[weekday - 1];
  }
}
