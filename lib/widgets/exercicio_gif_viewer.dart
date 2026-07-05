import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class ExercicioGifViewer extends StatelessWidget {
  final String imagem;
  final String titulo;
  final String? subtitulo;
  final String? gifPath;
  final double height;
  final double borderRadius;

  const ExercicioGifViewer({
    super.key,
    required this.imagem,
    required this.titulo,
    this.subtitulo,
    this.gifPath,
    this.height = 220,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final temPossivelGif =
        titulo.trim().isNotEmpty ||
        imagem.trim().isNotEmpty ||
        (gifPath?.trim().isNotEmpty ?? false);

    return Semantics(
      button: temPossivelGif,
      label: temPossivelGif ? 'Abrir GIF do exercicio' : 'GIF indisponivel',
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: temPossivelGif
            ? () => mostrarGifExercicioTelaCheia(
                context,
                imagem: imagem,
                titulo: titulo,
                subtitulo: subtitulo,
                gifPath: gifPath,
              )
            : null,
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
              ExercicioGifImage(
                imagem: imagem,
                titulo: titulo,
                gifPath: gifPath,
                placeholder: _placeholder(),
                cacheHeight: 520,
              ),
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

class ExercicioGifImage extends StatelessWidget {
  final String imagem;
  final String titulo;
  final String? gifPath;
  final BoxFit fit;
  final Widget? placeholder;
  final int? cacheWidth;
  final int? cacheHeight;

  const ExercicioGifImage({
    super.key,
    required this.imagem,
    required this.titulo,
    this.gifPath,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _GifResolver.manifest,
      builder: (context, snapshot) {
        final paths = _GifResolver.pathsFor(
          titulo: titulo,
          imagem: imagem,
          gifPath: gifPath,
          manifest: snapshot.data ?? const {},
        );

        return _GifAssetChain(
          paths: paths,
          fit: fit,
          semanticLabel: titulo,
          placeholder: placeholder ?? _defaultPlaceholder(),
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
        );
      },
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      color: Colors.black.withAlpha(36),
      child: const Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: AppColors.primary,
          size: 42,
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
  String? gifPath,
}) {
  showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (_) => _ExercicioGifDialog(
      imagem: imagem.trim(),
      titulo: titulo,
      subtitulo: subtitulo,
      gifPath: gifPath,
    ),
  );
}

class _ExercicioGifDialog extends StatelessWidget {
  final String imagem;
  final String titulo;
  final String? subtitulo;
  final String? gifPath;

  const _ExercicioGifDialog({
    required this.imagem,
    required this.titulo,
    this.subtitulo,
    this.gifPath,
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
    return FutureBuilder<Map<String, String>>(
      future: _GifResolver.manifest,
      builder: (context, snapshot) {
        final paths = _GifResolver.pathsFor(
          titulo: titulo,
          imagem: imagem,
          gifPath: gifPath,
          manifest: snapshot.data ?? const {},
        );

        return _GifAssetChain(
          paths: paths,
          fit: BoxFit.contain,
          semanticLabel: titulo,
          placeholder: _placeholder(),
          cacheWidth: 1200,
        );
      },
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

class _GifAssetChain extends StatelessWidget {
  final List<String> paths;
  final BoxFit fit;
  final String semanticLabel;
  final Widget placeholder;
  final int? cacheWidth;
  final int? cacheHeight;

  const _GifAssetChain({
    required this.paths,
    required this.fit,
    required this.semanticLabel,
    required this.placeholder,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCandidate(0);
  }

  Widget _buildCandidate(int index) {
    if (index >= paths.length) return placeholder;

    final path = paths[index];
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        path,
        fit: fit,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _buildCandidate(index + 1),
      );
    }

    return Image.asset(
      path,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: FilterQuality.low,
      semanticLabel: semanticLabel,
      errorBuilder: (_, _, _) => _buildCandidate(index + 1),
    );
  }
}

class _GifResolver {
  static const String manifestPath = 'assets/gifs/gif_manifest.json';

  static Future<Map<String, String>>? _manifestFuture;

  static Future<Map<String, String>> get manifest {
    return _manifestFuture ??= _loadManifest();
  }

  static Future<Map<String, String>> _loadManifest() async {
    try {
      final raw = await rootBundle.loadString(manifestPath);
      final decoded = jsonDecode(raw);

      if (decoded is! Map) return const {};

      return decoded.map<String, String>((key, value) {
        return MapEntry(key.toString(), value.toString());
      });
    } catch (_) {
      return const {};
    }
  }

  static List<String> pathsFor({
    required String titulo,
    required String imagem,
    required String? gifPath,
    required Map<String, String> manifest,
  }) {
    final slug = normalizarNome(titulo);
    final manifestValue = manifest[slug];

    return _unique([
      _assetPath(manifestValue),
      _assetPath(gifPath),
      _assetPath(imagem),
    ]);
  }

  static String normalizarNome(String value) {
    var text = value.toLowerCase().trim();
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };

    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    text = text.replaceAll(RegExp(r'_+'), '_');
    return text.replaceAll(RegExp(r'^_|_$'), '');
  }

  static String? _assetPath(String? rawPath) {
    final raw = rawPath?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    final normalized = raw.replaceAll('\\', '/').replaceAll('%25', '%');

    if (normalized.startsWith('assets/gifs/')) {
      return normalized;
    }

    if (normalized.startsWith('assets/')) {
      return normalized;
    }

    final clean = normalized.replaceAll(RegExp(r'^/+'), '');
    return 'assets/gifs/$clean';
  }

  static List<String> _unique(List<String?> values) {
    final seen = <String>{};
    final result = <String>[];

    for (final value in values) {
      if (value == null || value.trim().isEmpty) continue;
      if (seen.add(value)) result.add(value);
    }

    return result;
  }
}
