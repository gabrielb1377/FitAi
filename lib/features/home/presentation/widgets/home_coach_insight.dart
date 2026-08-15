import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/coach_insight_model.dart';

/// Atalho compacto para o Coach, conforme o bloco de IA do prototipo Home.
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
    return Semantics(
      key: const ValueKey('home-coach-card'),
      button: true,
      label: insight == null
          ? 'Abrir Coach FitIA. Ainda sem insights.'
          : 'Abrir Coach FitIA. ${insight.titulo}. ${insight.descricao}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.fitColors.surfaceRaised,
          border: Border(
            left: BorderSide(color: context.fitColors.ai, width: FitSpacing.s4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s16),
          child: ExcludeSemantics(
            child: FitActionRow(
              icon: FitIcons.coach,
              iconColor: context.fitColors.ai,
              title: insight?.titulo ?? 'Coach FitIA',
              subtitle:
                  insight?.descricao ??
                  'Registre atividades para receber orientacoes.',
              onTap: onOpenCoach,
            ),
          ),
        ),
      ),
    );
  }
}
