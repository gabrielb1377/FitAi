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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FitHeader(
          title: name.trim().isEmpty ? 'Usuario FitIA' : name,
          subtitle: 'Nivel $level',
          padding: EdgeInsets.zero,
          avatar: CircleAvatar(child: Text(initial)),
          actions: [
            IconButton.filled(
              tooltip: 'Editar perfil',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
        ),
        const SizedBox(height: FitSpacing.s12),
        FitProgress(
          value: xpTarget <= 0 ? 0 : xp / xpTarget,
          label: 'XP do nivel',
          trailing: '$xp / $xpTarget',
        ),
      ],
    );
  }
}
