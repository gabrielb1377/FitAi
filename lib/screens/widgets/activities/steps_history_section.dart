import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../../../models/daily_steps_model.dart';

class StepsHistorySection extends StatelessWidget {
  const StepsHistorySection({
    super.key,
    required this.records,
    required this.periodLabel,
  });

  final List<DailyStepsModel> records;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return FitCard(
        title: 'Histórico',
        subtitle: periodLabel,
        child: const Text('Nenhum resumo diário neste período.'),
      );
    }
    return FitCard(
      title: 'Histórico',
      subtitle: periodLabel,
      child: ListView.separated(
        shrinkWrap: true,
        primary: false,
        itemCount: records.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) => _HistoryRow(record: records[index]),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record});

  final DailyStepsModel record;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(record.date);
    final dateLabel = date == null
        ? record.date
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    return Semantics(
      label:
          '$dateLabel, ${record.steps} passos de ${record.goal}. ${record.goalCompleted ? 'Meta atingida.' : 'Meta não atingida.'} ${record.sourceLabel}.',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          record.goalCompleted
              ? Icons.check_circle_outline_rounded
              : Icons.directions_walk_outlined,
        ),
        title: Text(dateLabel),
        subtitle: Text('${record.sourceLabel} • ${record.goal} na meta'),
        trailing: Text(
          '${record.steps}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
