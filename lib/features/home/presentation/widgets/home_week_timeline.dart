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
        Semantics(
          key: const ValueKey('home-week-timeline-card'),
          button: true,
          label: 'Abrir historico dos ultimos sete dias',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenHistory,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: FitSpacing.s16),
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: context.colors.outlineVariant,
                    ),
                  ),
                ),
                child: ExcludeSemantics(
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
              ),
            ),
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
    final colors = Theme.of(context).colorScheme;
    final label = _weekdayLabel(date.weekday);
    final status = completed
        ? 'treino registrado'
        : isToday
        ? 'hoje'
        : 'sem treino registrado';
    final fill = completed
        ? colors.primary
        : isToday
        ? colors.primaryContainer
        : context.fitColors.surfaceSubtle;
    final border = isToday ? colors.primary : colors.outlineVariant;
    final foreground = completed ? colors.onPrimary : colors.onSurfaceVariant;

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
                  ? Icon(
                      FitIcons.check,
                      color: colors.onPrimary,
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
