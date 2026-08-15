import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../../../models/coach_insight_model.dart';

/// Bloco compacto de insights do Coach, sem competir com a acao principal.
class CoachInsightsCard extends StatelessWidget {
  const CoachInsightsCard({super.key, required this.insights});

  final List<CoachInsightModel> insights;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).fitSemanticColors;
    return Semantics(
      container: true,
      label: 'Insights do Coach FitIA',
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          FitSpacing.s16,
          FitSpacing.s12,
          FitSpacing.s16,
          FitSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: semantic.surfaceSubtle,
          border: Border(left: BorderSide(color: semantic.ai, width: 4)),
          borderRadius: FitRadius.mediumBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FitIcons.ai, color: semantic.ai),
                const SizedBox(width: FitSpacing.s8),
                Text(
                  'COACH FITIA',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: semantic.ai),
                ),
              ],
            ),
            const SizedBox(height: FitSpacing.s12),
            if (insights.isEmpty)
              Text(
                'Complete mais atividades para receber uma analise util.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              for (var index = 0; index < insights.length; index++) ...[
                _CoachInsightRow(insight: insights[index]),
                if (index < insights.length - 1)
                  Divider(color: colors.outlineVariant),
              ],
          ],
        ),
      ),
    );
  }
}

class _CoachInsightRow extends StatelessWidget {
  const _CoachInsightRow({required this.insight});

  final CoachInsightModel insight;

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: color, size: FitLayout.iconSizeButton),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.titulo,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (insight.descricao.trim().isNotEmpty) ...[
                  const SizedBox(height: FitSpacing.s4),
                  Text(
                    insight.descricao,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (insight.acao.trim().isNotEmpty) ...[
                  const SizedBox(height: FitSpacing.s4),
                  Text(
                    insight.acao,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: color),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _color(BuildContext context) {
    final semantic = Theme.of(context).fitSemanticColors;
    return switch (insight.categoria) {
      CoachInsightCategoria.evolucao ||
      CoachInsightCategoria.progressao => Theme.of(context).colorScheme.primary,
      CoachInsightCategoria.recuperacao => semantic.energy,
      CoachInsightCategoria.frequencia => semantic.steps,
      CoachInsightCategoria.recordes => semantic.achievement,
      CoachInsightCategoria.sugestoes => semantic.ai,
    };
  }

  IconData get _icon => switch (insight.categoria) {
    CoachInsightCategoria.evolucao => Icons.trending_up_rounded,
    CoachInsightCategoria.progressao => Icons.fitness_center_rounded,
    CoachInsightCategoria.recuperacao => Icons.warning_amber_rounded,
    CoachInsightCategoria.frequencia => Icons.local_fire_department_rounded,
    CoachInsightCategoria.recordes => Icons.emoji_events_rounded,
    CoachInsightCategoria.sugestoes => Icons.lightbulb_rounded,
  };
}
