import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

Future<String?> showExerciseNoteEditor(
  BuildContext context, {
  required TextEditingController controller,
  required bool editando,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: _dialogShape(),
      title: Text(
        editando ? 'Editar nota' : 'Adicionar nota',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 4,
        minLines: 2,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: _inputDecoration(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

Future<bool?> showDeleteExerciseNoteConfirm(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: _dialogShape(),
      title: const Text(
        'Apagar nota?',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: const Text(
        'Essa anotacao sera removida apenas deste exercicio.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Apagar'),
        ),
      ],
    ),
  );
}

RoundedRectangleBorder _dialogShape() {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
    side: BorderSide(color: Colors.white.withAlpha(18)),
  );
}

InputDecoration _inputDecoration() {
  return InputDecoration(
    hintText: 'Ex: manter escapulas retraidas',
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.surfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );
}
