import 'package:flutter/material.dart';

class ExerciseSummary extends StatelessWidget {
  final String nome;
  final String categoria;

  const ExerciseSummary({
    super.key,
    required this.nome,
    required this.categoria,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          nome,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Peso recomendado: mantenha execuÃ§Ã£o controlada e registre cada sÃ©rie.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withAlpha(165),
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
