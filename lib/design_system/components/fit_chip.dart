import 'package:flutter/material.dart';

/// Alias de compatibilidade para o chip de filtro selecionavel FitIA.
class FitChip extends FitFilterChip {
  const FitChip({
    super.key,
    required super.label,
    super.selected,
    super.onSelected,
    super.icon,
    super.enabled,
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

  const FitFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? onSelected : null,
      avatar: icon == null ? null : Icon(icon, size: 16),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
