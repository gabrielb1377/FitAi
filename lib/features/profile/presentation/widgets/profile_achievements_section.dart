import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

/// Espaco visual reservado para o catalogo de conquistas do VS9.3.
class ProfileAchievementsSection extends StatelessWidget {
  const ProfileAchievementsSection({
    super.key,
    required this.unlockedCount,
    required this.onViewAll,
  });

  final int unlockedCount;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final useSingleColumn = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return FitSection(
      title: 'Conquistas',
      action: const FitBadge.beta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unlockedCount == 0
                ? 'Seu painel de conquistas sera exibido aqui.'
                : '$unlockedCount conquista(s) local(is) aguardando o painel completo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: FitSpacing.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = useSingleColumn
                  ? 1
                  : FitBreakpoints.isTablet(constraints.maxWidth)
                  ? 4
                  : 2;
              final gap = FitSpacing.s12;
              final width =
                  (constraints.maxWidth - (gap * (count - 1))) / count;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var index = 0; index < 4; index++)
                    SizedBox(
                      width: width,
                      child: FitCard(
                        semanticLabel: 'Conquista em desenvolvimento',
                        child: Column(
                          children: [
                            Icon(
                              FitIcons.lock,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            const SizedBox(height: FitSpacing.s8),
                            Text(
                              'Em breve',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: FitSpacing.s12),
          FitButton(
            label: 'Ver conquistas',
            variant: FitButtonVariant.ghost,
            trailingIcon: FitIcons.forward,
            onPressed: onViewAll,
          ),
        ],
      ),
    );
  }
}
