import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../../../models/daily_steps_model.dart';

/// Calendário mensal compacto. Um dia contém no máximo o resumo diário de
/// passos, preservando espaço visual para corridas na timeline geral.
class StepsCalendarCard extends StatelessWidget {
  const StepsCalendarCard({
    super.key,
    required this.month,
    required this.records,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  final DateTime month;
  final List<DailyStepsModel> records;
  final DateTime selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final startOffset = first.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;
    final byDate = {for (final record in records) record.date: record};
    final selectedRecord =
        byDate[DailyStepsModel.normalizeDateKey(
          selectedDate.toIso8601String(),
        )];

    return FitCard(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calendário', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: FitSpacing.s4),
          Text(
            'Meta atingida é indicada com um marcador.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: FitSpacing.s8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _monthLabel(first),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FitIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Mês anterior',
                onPressed: onPreviousMonth,
              ),
              FitIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Próximo mês',
                onPressed: onNextMonth,
              ),
            ],
          ),
        ],
      ),
      child: Column(
        children: [
          const _WeekDaysHeader(),
          const SizedBox(height: FitSpacing.s8),
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: FitSpacing.s4,
              crossAxisSpacing: FitSpacing.s4,
            ),
            itemBuilder: (context, index) {
              final day = index - startOffset + 1;
              if (day <= 0 || day > daysInMonth) return const SizedBox.shrink();
              final date = DateTime(month.year, month.month, day);
              final record =
                  byDate[DailyStepsModel.normalizeDateKey(
                    date.toIso8601String(),
                  )];
              final selected = _sameDay(date, selectedDate);
              return _CalendarCell(
                date: date,
                record: record,
                selected: selected,
                onTap: () => onSelectDate(date),
              );
            },
          ),
          const SizedBox(height: FitSpacing.s12),
          _SelectedDaySummary(date: selectedDate, record: selectedRecord),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _SelectedDaySummary extends StatelessWidget {
  const _SelectedDaySummary({required this.date, required this.record});

  final DateTime date;
  final DailyStepsModel? record;

  @override
  Widget build(BuildContext context) {
    final title =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    final value = record == null
        ? 'Sem dados de passos neste dia.'
        : '${record!.steps} passos de ${record!.goal}. ${record!.goalCompleted ? 'Meta atingida.' : 'Meta não atingida.'}';
    return Semantics(
      liveRegion: true,
      label: '$title. $value',
      child: Text(
        '$title • $value',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _WeekDaysHeader extends StatelessWidget {
  const _WeekDaysHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.date,
    required this.record,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final DailyStepsModel? record;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reached = record?.goalCompleted ?? false;
    final label =
        '${date.day}, ${record == null ? 'sem dados' : '${record!.steps} passos'}${reached ? ', meta atingida' : ''}';
    final color = reached
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outlineVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: FitRadius.mediumBorder,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: FitRadius.mediumBorder,
            border: Border.all(color: selected ? color : Colors.transparent),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (record != null)
                  Positioned(
                    bottom: FitSpacing.s2,
                    child: Icon(
                      reached ? Icons.check_circle_rounded : Icons.circle,
                      color: color,
                      size: FitLayout.iconSizeBadge,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
