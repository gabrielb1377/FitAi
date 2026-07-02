import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

void mostrarGifExercicioTelaCheia(
  BuildContext context, {
  required String imagem,
  required String titulo,
  String? subtitulo,
}) {
  showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (_) => _ExercicioGifDialog(
      imagem: imagem.trim(),
      titulo: titulo,
      subtitulo: subtitulo,
    ),
  );
}

class _ExercicioGifDialog extends StatelessWidget {
  final String imagem;
  final String titulo;
  final String? subtitulo;

  const _ExercicioGifDialog({
    required this.imagem,
    required this.titulo,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 72, 18, 28),
                child: Center(child: _imagem()),
              ),
            ),
            Positioned(
              left: 18,
              top: 14,
              right: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitulo != null && subtitulo!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitulo!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              right: 14,
              top: 10,
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagem() {
    if (imagem.isEmpty) return _placeholder();

    final isNetwork =
        imagem.startsWith('http://') || imagem.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        imagem,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return Image.asset(
      imagem,
      fit: BoxFit.contain,
      cacheWidth: 1200,
      filterQuality: FilterQuality.low,
      semanticLabel: titulo,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420, minHeight: 220),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(24)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            color: AppColors.primary,
            size: 54,
          ),
          SizedBox(height: 14),
          Text(
            'GIF indisponivel',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
