import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

/// Aviso discreto de que o resumo tambem pode ser consultado sem conexao.
class ProfileLocalDataNotice extends StatelessWidget {
  const ProfileLocalDataNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Perfil disponivel com dados salvos no dispositivo',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: FitSpacing.s12,
          vertical: FitSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: colors.secondaryContainer.withAlpha(92),
          borderRadius: FitRadius.mediumBorder,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_done_outlined, size: 18, color: colors.secondary),
            const SizedBox(width: FitSpacing.s8),
            Expanded(
              child: Text(
                'Dados salvos tambem ficam disponiveis offline.',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(width: FitSpacing.s8),
            const FitBadge.offline(),
          ],
        ),
      ),
    );
  }
}
