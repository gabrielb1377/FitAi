import 'package:flutter/material.dart';

import '../../../models/coach_insight_model.dart';
import '../../../theme/app_theme.dart';

class CoachInsightsCard extends StatelessWidget {
  final List<CoachInsightModel> insights;

  const CoachInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (insights.isEmpty)
            Text(
              'Complete mais treinos para o Coach FitIA gerar analises locais.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            )
          else
            ...insights.map((insight) => _CoachInsightRow(insight: insight)),
        ],
      ),
    );
  }
}

class _CoachInsightRow extends StatelessWidget {
  final CoachInsightModel insight;

  const _CoachInsightRow({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(32),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        insight.titulo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      insight.categoriaLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  insight.descricao,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
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

  IconData get _icon {
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
