import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ExerciseCommentField extends StatelessWidget {
  final bool isOpen;
  final TextEditingController controller;
  final VoidCallback onToggle;

  const ExerciseCommentField({
    super.key,
    required this.isOpen,
    required this.controller,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onToggle,
            icon: Icon(
              isOpen ? Icons.close_rounded : Icons.add_comment_rounded,
              size: 18,
            ),
            label: Text(isOpen ? 'Ocultar comentario' : 'Adicionar comentario'),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: !isOpen
              ? const SizedBox.shrink()
              : TextField(
                  key: const ValueKey('comentario'),
                  controller: controller,
                  minLines: 2,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Como foi a serie?',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: _border(),
                    enabledBorder: _border(),
                    focusedBorder: _border(AppColors.primary),
                  ),
                ),
        ),
      ],
    );
  }

  OutlineInputBorder _border([Color? color]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: color ?? Colors.white.withAlpha(16)),
    );
  }
}
