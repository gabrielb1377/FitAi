import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final int level;
  final int xp;
  final int xpTarget;
  final VoidCallback onEdit;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.level,
    required this.xp,
    required this.xpTarget,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedName = name.trim();
    final initial = trimmedName.isEmpty ? 'U' : trimmedName[0].toUpperCase();
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FitHeader(
          title: name.trim().isEmpty ? 'Usuario FitIA' : name,
          subtitle: 'Nivel $level  |  $xp XP',
          padding: EdgeInsets.zero,
          avatar: Semantics(
            label: 'Avatar de ${name.trim().isEmpty ? 'Usuario FitIA' : name}',
            child: CircleAvatar(
              radius: 24,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              child: Text(initial),
            ),
          ),
          actions: [
            IconButton.filled(
              tooltip: 'Editar perfil',
              color: colors.onPrimary,
              style: IconButton.styleFrom(backgroundColor: colors.primary),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
        ),
        const SizedBox(height: FitSpacing.s12),
        FitProgress(
          value: xpTarget <= 0 ? 0 : xp / xpTarget,
          label: 'Progresso do nivel',
          trailing: '$xp / $xpTarget',
          height: 8,
        ),
      ],
    );
  }
}
