import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Alias de compatibilidade para o chip de filtro selecionavel FitIA.
class FitChip extends FitFilterChip {
  const FitChip({
    super.key,
    required super.label,
    super.selected,
    super.onSelected,
    super.icon,
    super.enabled,
    super.variant,
  });
}

/// Chip de filtro controlado externamente.
///
/// Exemplo: `FitFilterChip(label: 'Forca', selected: active, onSelected: setActive)`.
class FitFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final bool enabled;
  final FitChipVariant variant;

  const FitFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.icon,
    this.enabled = true,
    this.variant = FitChipVariant.filter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedColor = switch (variant) {
      FitChipVariant.status => colors.tertiaryContainer,
      FitChipVariant.difficulty => colors.secondaryContainer,
      _ => colors.primaryContainer,
    };
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? onSelected : null,
      avatar: icon == null ? null : Icon(icon, size: 16),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      shape: const RoundedRectangleBorder(borderRadius: FitRadius.pillBorder),
      side: BorderSide(color: colors.outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s8),
      selectedColor: selectedColor,
    );
  }
}

enum FitChipVariant { filter, tag, status, difficulty, selectable }
