import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/treino_model.dart';

class ActivePlanSummary extends StatelessWidget {
  final TreinoModel? plan;
  final VoidCallback onContinue;

  const ActivePlanSummary({
    super.key,
    required this.plan,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    if (plan == null) return _emptyPlan(context);
    final nextWorkout = plan!.planoDias.isEmpty
        ? 'Proximo treino disponivel'
        : plan!.planoDias.first.nome;
    return FitCard(
      variant: FitCardVariant.outlined,
      elevation: 1,
      title: 'Plano ativo',
      subtitle: plan!.nome,
      trailing: const FitStatusChip(
        label: 'Ativo',
        tone: FitStatusTone.success,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: FitSpacing.s8,
            runSpacing: FitSpacing.s8,
            children: [
              FitTagChip(label: plan!.objetivo, icon: Icons.flag_rounded),
              FitTagChip(
                label: plan!.divisao,
                icon: Icons.account_tree_rounded,
              ),
              FitTagChip(
                label: '${plan!.diasPorSemana} dias/semana',
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          FitProgress(value: 0, label: 'Progresso', trailing: '0%'),
          const SizedBox(height: FitSpacing.s12),
          Text(
            'Proximo: $nextWorkout',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: FitSpacing.s16),
          FitButton(
            label: 'Continuar',
            icon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _emptyPlan(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.outlined,
      title: 'Nenhum plano ativo',
      subtitle: 'Escolha ou crie um plano para iniciar sua rotina.',
      child: Align(
        alignment: Alignment.centerLeft,
        child: FitButton(
          label: 'Escolher plano',
          icon: Icons.library_books_rounded,
          onPressed: onContinue,
          variant: FitButtonVariant.outlined,
        ),
      ),
    );
  }
}
