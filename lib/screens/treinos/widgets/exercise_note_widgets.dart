import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ExerciseNotesHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const ExerciseNotesHeader({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(24),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Minhas notas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Adicionar'),
        ),
      ],
    );
  }
}

class ExerciseNotesEmptyState extends StatelessWidget {
  const ExerciseNotesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Nenhuma nota ainda.\nEx: manter escapulas retraidas\nEx: testar 32 kg semana que vem',
        style: TextStyle(
          color: AppColors.textSecondary,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ExerciseNoteItem extends StatelessWidget {
  final String texto;
  final VoidCallback onEditar;
  final VoidCallback onApagar;

  const ExerciseNoteItem({
    super.key,
    required this.texto,
    required this.onEditar,
    required this.onApagar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.surface,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
            ),
            onSelected: (value) {
              if (value == 'editar') onEditar();
              if (value == 'apagar') onApagar();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'apagar', child: Text('Apagar')),
            ],
          ),
        ],
      ),
    );
  }
}
