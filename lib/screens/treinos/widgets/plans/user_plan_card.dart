import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/treino_model.dart';

class UserPlanCard extends StatelessWidget {
  final TreinoModel plan;
  final bool isActive;
  final VoidCallback onOpen;

  const UserPlanCard({
    super.key,
    required this.plan,
    required this.isActive,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.clickable,
      elevation: 0,
      title: plan.nome,
      subtitle: plan.objetivo,
      trailing: FitStatusChip(
        label: isActive ? 'Ativo' : 'Salvo',
        tone: isActive ? FitStatusTone.success : FitStatusTone.neutral,
      ),
      onTap: onOpen,
      semanticLabel: 'Abrir plano ${plan.nome}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: FitSpacing.s8,
            runSpacing: FitSpacing.s8,
            children: [
              FitTagChip(label: plan.divisao, icon: Icons.account_tree_rounded),
              FitTagChip(
                label: '${plan.diasPorSemana} dias',
                icon: Icons.calendar_today_rounded,
              ),
              FitTagChip(label: plan.nivel, icon: Icons.trending_up_rounded),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          const FitProgress(value: 0, label: 'Progresso', trailing: '0%'),
          const SizedBox(height: FitSpacing.s12),
          Align(
            alignment: Alignment.centerRight,
            child: FitButton(
              label: 'Abrir',
              icon: Icons.arrow_forward_rounded,
              onPressed: onOpen,
              variant: FitButtonVariant.ghost,
              size: FitButtonSize.compact,
            ),
          ),
        ],
      ),
    );
  }
}
