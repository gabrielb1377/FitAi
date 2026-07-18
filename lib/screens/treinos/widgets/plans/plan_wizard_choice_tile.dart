import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

/// Linha de escolha usada pelos assistentes oficiais de criacao de planos.
class PlanWizardChoiceTile extends StatelessWidget {
  const PlanWizardChoiceTile({
    super.key,
    required this.index,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
  });

  final int index;
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.clickable,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: FitSpacing.s16,
        vertical: FitSpacing.s16,
      ),
      semanticLabel: '$label: $value',
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: FitColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              index.toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: FitColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: FitSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: FitSpacing.s12),
          Icon(icon ?? Icons.chevron_right_rounded, color: FitColors.primary),
        ],
      ),
    );
  }
}
