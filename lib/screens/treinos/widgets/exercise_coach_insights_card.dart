import 'package:flutter/material.dart';

import '../../../models/coach_insight_model.dart';
import '../../../theme/app_theme.dart';

class ExerciseCoachInsightsCard extends StatelessWidget {
  final Future<List<CoachInsightModel>> future;

  const ExerciseCoachInsightsCard({super.key, required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CoachInsightModel>>(
      future: future,
      builder: (context, snapshot) {
        final insights = snapshot.data ?? const <CoachInsightModel>[];

        return AppGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.psychology_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Coach FitIA',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData)
                const LinearProgressIndicator(minHeight: 3)
              else if (insights.isEmpty)
                Text(
                  'Registre mais execucoes para receber insights deste exercicio.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                )
              else
                ...insights.map((insight) => _InsightTile(insight: insight)),
            ],
          ),
        );
      },
    );
  }
}

class _InsightTile extends StatelessWidget {
  final CoachInsightModel insight;

  const _InsightTile({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _cor(insight);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withAlpha(32),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icone(insight), color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.titulo,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  insight.descricao,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _cor(CoachInsightModel insight) {
    switch (insight.categoria) {
      case CoachInsightCategoria.evolucao:
      case CoachInsightCategoria.progressao:
        return Colors.greenAccent;
      case CoachInsightCategoria.recuperacao:
        return Colors.orangeAccent;
      case CoachInsightCategoria.frequencia:
        return Colors.cyanAccent;
      case CoachInsightCategoria.recordes:
        return Colors.amberAccent;
      case CoachInsightCategoria.sugestoes:
        return AppColors.primary;
    }
  }

  IconData _icone(CoachInsightModel insight) {
    switch (insight.categoria) {
      case CoachInsightCategoria.evolucao:
        return Icons.trending_up_rounded;
      case CoachInsightCategoria.progressao:
        return Icons.fitness_center_rounded;
      case CoachInsightCategoria.recuperacao:
        return Icons.warning_amber_rounded;
      case CoachInsightCategoria.frequencia:
        return Icons.local_fire_department_rounded;
      case CoachInsightCategoria.recordes:
        return Icons.emoji_events_rounded;
      case CoachInsightCategoria.sugestoes:
        return Icons.lightbulb_rounded;
    }
  }
}
