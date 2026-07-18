import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/treino_model.dart';
import '../../controllers/plan_progress_snapshot.dart';
import 'plan_media.dart';

class OfficialPlanCard extends StatelessWidget {
  const OfficialPlanCard({
    super.key,
    required this.plan,
    required this.progress,
    required this.isActive,
    required this.onTap,
  });

  final TreinoModel plan;
  final PlanProgressSnapshot progress;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.weeklyProgress * 100).round();
    return FitCard(
      variant: FitCardVariant.clickable,
      padding: const EdgeInsets.all(FitSpacing.s12),
      onTap: onTap,
      semanticLabel:
          '${isActive ? 'Plano ativo' : 'Plano salvo'} ${plan.nome}, $percent por cento concluido nesta semana',
      child: Row(
        children: [
          PlanMedia(plan: plan, width: 88, height: 104),
          const SizedBox(width: FitSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: FitSpacing.s8),
                Text(
                  '${_days(plan)} dias por semana',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FitColors.textSecondary,
                  ),
                ),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  '$percent% concluido',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FitColors.textSecondary,
                  ),
                ),
                const SizedBox(height: FitSpacing.s8),
                FitProgress(value: progress.weeklyProgress, animate: true),
              ],
            ),
          ),
          const SizedBox(width: FitSpacing.s8),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  int _days(TreinoModel value) {
    if (value.planoDias.isNotEmpty) return value.planoDias.length;
    return value.diasPorSemana <= 0 ? 1 : value.diasPorSemana;
  }
}
