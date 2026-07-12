import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_meta_model.dart';

class ProfileGoals extends StatelessWidget {
  final FitaiMetaModel? goal;
  final VoidCallback onEdit;

  const ProfileGoals({super.key, required this.goal, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    if (goal == null) {
      return FitSection(
        title: 'Metas',
        padding: EdgeInsets.zero,
        child: FitEmptyState(
          icon: Icons.flag_outlined,
          title: 'Nenhuma meta ativa.',
          description: 'Abra suas metas para acompanhar sua evolucao.',
          actionLabel: 'Editar metas',
          onAction: onEdit,
        ),
      );
    }
    return FitSection(
      title: 'Metas',
      subtitle: 'Seu foco atual',
      action: FitButton(
        label: 'Editar',
        icon: Icons.edit_outlined,
        onPressed: onEdit,
        variant: FitButtonVariant.ghost,
        size: FitButtonSize.compact,
      ),
      padding: EdgeInsets.zero,
      child: FitCard(
        variant: FitCardVariant.filled,
        elevation: 1,
        title: goal!.titulo,
        subtitle: goal!.categoriaLabel,
        trailing: FitStatusChip(label: goal!.statusLabel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FitProgress(
              value: goal!.progresso,
              label: 'Progresso',
              trailing: goal!.progressoPercentual,
              height: 8,
            ),
            const SizedBox(height: FitSpacing.s12),
            Text(
              '${_value(goal!.valorAtual)} / ${_value(goal!.valorObjetivo)} ${goal!.unidade}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _value(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);
}
