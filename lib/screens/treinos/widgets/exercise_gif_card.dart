import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ExerciseGifCard extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onTap;

  const ExerciseGifCard({super.key, required this.imagePath, this.onTap});

  @override
  Widget build(BuildContext context) {
    final imagem = imagePath.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: imagem.isEmpty ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          constraints: const BoxConstraints(minHeight: 230, maxHeight: 300),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            border: Border.all(color: Colors.white.withAlpha(12)),
          ),
          child: imagem.isEmpty ? _fallback(60) : _image(imagem),
        ),
      ),
    );
  }

  Widget _image(String imagem) {
    final isNetwork =
        imagem.startsWith('http://') || imagem.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        imagem,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _fallback(60),
      );
    }

    return Image.asset(
      imagem,
      fit: BoxFit.contain,
      cacheHeight: 620,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) => _fallback(60),
    );
  }

  Widget _fallback(double size) {
    return Center(
      child: Icon(
        Icons.fitness_center_rounded,
        color: AppColors.primary,
        size: size,
      ),
    );
  }
}
