import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Resolves exercise media exclusively through the reviewed v2 contract.
///
/// A display title is intentionally never used as an asset key. Unknown,
/// unreviewed and rejected canonical IDs all return no asset so the existing
/// placeholder can fail closed instead of showing the wrong exercise.
class ExerciseMediaResolver {
  static const String manifestPath =
      'assets/exercises/exercise_media_manifest_v2.json';

  static Future<Map<String, String>>? _manifestFuture;

  static Future<Map<String, String>> get manifest {
    return _manifestFuture ??= _loadManifest();
  }

  static Future<Map<String, String>> _loadManifest() async {
    try {
      final raw = await rootBundle.loadString(manifestPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['entries'] is! List) return const {};

      final paths = <String, String>{};
      for (final value in decoded['entries'] as List<dynamic>) {
        if (value is! Map) continue;
        final id = value['canonicalExerciseId']?.toString().trim() ?? '';
        final path = value['assetPath']?.toString().trim() ?? '';
        final level = value['verificationLevel']?.toString();
        final status = value['status']?.toString();
        if (id.isEmpty || path.isEmpty || status != 'VERIFIED') continue;
        if (level != 'VERIFIED_HIGH' && level != 'VERIFIED_SHARED') continue;
        paths[id] = path;
      }
      return Map.unmodifiable(paths);
    } catch (_) {
      return const {};
    }
  }

  /// Exposed for focused widget tests and other media-only integrations.
  static String? pathFor(
    String canonicalExerciseId,
    Map<String, String> manifest,
  ) {
    final id = canonicalExerciseId.trim();
    if (id.isEmpty) return null;
    return manifest[id];
  }

  @visibleForTesting
  static void resetForTest() {
    _manifestFuture = null;
  }

  @visibleForTesting
  static void setManifestForTest(Map<String, String> manifest) {
    _manifestFuture = Future.value(Map.unmodifiable(Map.of(manifest)));
  }
}

class ExercicioGifViewer extends StatelessWidget {
  final String canonicalExerciseId;
  final String titulo;
  final String? subtitulo;
  final double height;
  final double borderRadius;

  const ExercicioGifViewer({
    super.key,
    required this.canonicalExerciseId,
    required this.titulo,
    this.subtitulo,
    this.height = 220,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final canOpen = canonicalExerciseId.trim().isNotEmpty;

    return Semantics(
      button: canOpen,
      label: canOpen ? 'Abrir execução de $titulo' : 'Mídia indisponível',
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: canOpen
            ? () => mostrarGifExercicioTelaCheia(
                context,
                canonicalExerciseId: canonicalExerciseId,
                titulo: titulo,
                subtitulo: subtitulo,
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
                canonicalExerciseId: canonicalExerciseId,
                titulo: titulo,
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
  final String canonicalExerciseId;
  final String titulo;
  final BoxFit fit;
  final Widget? placeholder;
  final int? cacheWidth;
  final int? cacheHeight;

  const ExercicioGifImage({
    super.key,
    required this.canonicalExerciseId,
    required this.titulo,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: ExerciseMediaResolver.manifest,
      builder: (context, snapshot) {
        final path = ExerciseMediaResolver.pathFor(
          canonicalExerciseId,
          snapshot.data ?? const {},
        );
        if (path == null) return placeholder ?? _defaultPlaceholder();

        return Image.asset(
          path,
          fit: fit,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          filterQuality: FilterQuality.low,
          semanticLabel: titulo,
          errorBuilder: (_, _, _) => placeholder ?? _defaultPlaceholder(),
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
  required String canonicalExerciseId,
  required String titulo,
  String? subtitulo,
}) {
  showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (_) => _ExercicioGifDialog(
      canonicalExerciseId: canonicalExerciseId.trim(),
      titulo: titulo,
      subtitulo: subtitulo,
    ),
  );
}

class _ExercicioGifDialog extends StatelessWidget {
  final String canonicalExerciseId;
  final String titulo;
  final String? subtitulo;

  const _ExercicioGifDialog({
    required this.canonicalExerciseId,
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
    return ExercicioGifImage(
      canonicalExerciseId: canonicalExerciseId,
      titulo: titulo,
      fit: BoxFit.contain,
      cacheWidth: 1200,
      placeholder: _placeholder(),
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
            'GIF indisponível',
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
