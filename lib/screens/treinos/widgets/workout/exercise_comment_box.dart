import 'package:flutter/material.dart';

class ExerciseCommentBox extends StatelessWidget {
  final TextEditingController controller;
  final bool isOpen;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  const ExerciseCommentBox({
    super.key,
    required this.controller,
    required this.isOpen,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: onToggle,
          icon: const Icon(Icons.mode_comment_outlined),
          label: Text(isOpen ? 'Ocultar comentÃ¡rio' : 'Adicionar comentÃ¡rio'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF00E5C3),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: isOpen
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ex: boa execuÃ§Ã£o, subir carga na prÃ³xima...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
                filled: true,
                fillColor: const Color(0xFF111820),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF233241)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF233241)),
                ),
              ),
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
