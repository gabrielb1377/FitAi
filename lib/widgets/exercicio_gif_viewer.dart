import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ExercicioGifViewer extends StatelessWidget {
  final String imagem;
  final String titulo;
  final String? subtitulo;
  final double height;
  final double borderRadius;

  const ExercicioGifViewer({
    super.key,
    required this.imagem,
    required this.titulo,
    this.subtitulo,
    this.height = 220,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = imagem.trim();

    return Semantics(
      button: imagePath.isNotEmpty,
      label: imagePath.isEmpty ? 'GIF indisponivel' : 'Abrir GIF do exercicio',
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: imagePath.isEmpty
            ? null
            : () => mostrarGifExercicioTelaCheia(
                context,
                imagem: imagePath,
                titulo: titulo,
                subtitulo: subtitulo,
              ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          width: double.infinity,
          height: height.clamp(180, 260).toDouble(),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withAlpha(18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(54),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _imagem(imagePath),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(18)),
                  ),
                  child: const Icon(
                    Icons.open_in_full_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagem(String imagePath) {
    if (imagePath.isEmpty) return _placeholder();

    final isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      cacheHeight: 520,
      filterQuality: FilterQuality.low,
      semanticLabel: titulo,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.black.withAlpha(36),
      child: const Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: AppColors.primary,
          size: 52,
        ),
      ),
    );
  }
}

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
