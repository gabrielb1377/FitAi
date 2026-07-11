import 'package:flutter/material.dart';

/// Chip de filtro controlado externamente, adaptado ao tema em uso.
class FitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final bool enabled;

  const FitChip({
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
    );
  }
}
