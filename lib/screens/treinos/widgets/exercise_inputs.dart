import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ExerciseInputs extends StatelessWidget {
  final TextEditingController pesoController;
  final TextEditingController repeticoesController;
  final ValueChanged<String>? onRepeticoesChanged;
  final VoidCallback onIncrementRepeticoes;

  const ExerciseInputs({
    super.key,
    required this.pesoController,
    required this.repeticoesController,
    required this.onIncrementRepeticoes,
    this.onRepeticoesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _inputField(
            controller: pesoController,
            label: 'Quilos',
            suffix: 'kg',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _inputField(
            controller: repeticoesController,
            label: 'Repeticoes',
            suffix: 'reps',
            keyboardType: TextInputType.number,
            onChanged: onRepeticoesChanged,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 58,
          height: 58,
          child: ElevatedButton(
            onPressed: onIncrementRepeticoes,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19),
              ),
            ),
            child: const Icon(Icons.add_rounded, size: 32),
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required TextInputType keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withAlpha(16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withAlpha(16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
