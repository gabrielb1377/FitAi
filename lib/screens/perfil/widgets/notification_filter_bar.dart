import 'package:flutter/material.dart';

import '../../../models/fitai_notification_model.dart';

class NotificationFilterBar extends StatelessWidget {
  final FitaiNotificationCategoria? filtro;
  final ValueChanged<FitaiNotificationCategoria?> onChanged;

  const NotificationFilterBar({
    super.key,
    required this.filtro,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Todas',
              selected: filtro == null,
              onTap: () => onChanged(null),
            ),
            for (final categoria in FitaiNotificationCategoria.values)
              _FilterChip(
                label: _label(categoria),
                selected: filtro == categoria,
                onTap: () => onChanged(categoria),
              ),
          ],
        ),
      ),
    );
  }

  String _label(FitaiNotificationCategoria categoria) {
    return FitaiNotificationModel(
      id: '',
      titulo: '',
      descricao: '',
      categoria: categoria,
      icone: '',
      data: DateTime(0),
    ).categoriaLabel;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
