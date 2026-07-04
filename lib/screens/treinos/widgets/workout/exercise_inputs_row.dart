import 'package:flutter/material.dart';

class ExerciseInputsRow extends StatelessWidget {
  final TextEditingController pesoController;
  final TextEditingController repeticoesController;
  final VoidCallback onAddReps;
  final ValueChanged<String> onChanged;

  const ExerciseInputsRow({
    super.key,
    required this.pesoController,
    required this.repeticoesController,
    required this.onAddReps,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DarkInput(
            controller: pesoController,
            label: 'Quilos',
            suffix: 'kg',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DarkInput(
            controller: repeticoesController,
            label: 'RepetiÃ§Ãµes',
            suffix: 'rep',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onAddReps,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5C3),
              borderRadius: BorderRadius.circular(19),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5C3).withAlpha(70),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.black, size: 32),
          ),
        ),
      ],
    );
  }
}

class _DarkInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final ValueChanged<String> onChanged;

  const _DarkInput({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: const Color(0xFF111820),
        labelStyle: TextStyle(
          color: Colors.white.withAlpha(145),
          fontWeight: FontWeight.w700,
        ),
        suffixStyle: TextStyle(
          color: Colors.white.withAlpha(145),
          fontWeight: FontWeight.w800,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(19),
          borderSide: const BorderSide(color: Color(0xFF233241)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(19),
          borderSide: const BorderSide(color: Color(0xFF00E5C3), width: 1.6),
        ),
      ),
    );
  }
}
