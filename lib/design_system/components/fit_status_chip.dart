import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';
import 'fit_chip.dart';

/// Chip apenas informativo para tags curtas, sem acao associada.
class FitTagChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const FitTagChip({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FitSpacing.s8,
          vertical: FitSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: FitRadius.pillBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: colors.onSecondaryContainer),
              const SizedBox(width: FitSpacing.s4),
            ],
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// Chip de status semantico para estados compactos de uma entidade.
class FitStatusChip extends StatelessWidget {
  final String label;
  final FitStatusTone tone;

  const FitStatusChip({
    super.key,
    required this.label,
    this.tone = FitStatusTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (tone) {
      FitStatusTone.success => colors.primary,
      FitStatusTone.warning => colors.tertiary,
      FitStatusTone.error => colors.error,
      FitStatusTone.neutral => colors.secondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FitSpacing.s8,
        vertical: FitSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: FitRadius.pillBorder,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// Chip de dificuldade baseado nas tres faixas de treino suportadas pelo app.
class FitDifficultyChip extends StatelessWidget {
  final FitDifficulty difficulty;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const FitDifficultyChip({
    super.key,
    required this.difficulty,
    this.selected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FitFilterChip(
      label: difficulty.label,
      selected: selected,
      onSelected: onSelected,
      icon: difficulty.icon,
    );
  }
}

enum FitStatusTone { neutral, success, warning, error }

enum FitDifficulty {
  beginner('Iniciante', Icons.looks_one_rounded),
  intermediate('Intermediario', Icons.looks_two_rounded),
  advanced('Avancado', Icons.looks_3_rounded);

  final String label;
  final IconData icon;

  const FitDifficulty(this.label, this.icon);
}
