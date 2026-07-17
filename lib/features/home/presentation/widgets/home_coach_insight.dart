import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/coach_insight_model.dart';

class HomeCoachInsight extends StatelessWidget {
  const HomeCoachInsight({
    super.key,
    required this.insights,
    required this.onOpenCoach,
  });

  final List<CoachInsightModel> insights;
  final VoidCallback onOpenCoach;

  @override
  Widget build(BuildContext context) {
    final insight = insights.isEmpty ? null : insights.first;
    return FitSection(
      title: 'Coach FitIA',
      child: insight == null
          ? FitEmptyState(
              icon: Icons.auto_awesome_outlined,
              title: 'Ainda sem insights',
              description:
                  'Registre atividades para o Coach analisar sua evolucao.',
              actionLabel: 'Abrir Coach',
              onAction: onOpenCoach,
            )
          : FitCoachInsightCard(
              title: insight.titulo,
              insight: insight.descricao,
              actionLabel: 'Ver detalhes',
              onAction: onOpenCoach,
            ),
    );
  }
}
