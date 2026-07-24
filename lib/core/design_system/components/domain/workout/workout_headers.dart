import 'package:flutter/material.dart';

import '../../../../../design_system/components/fit_progress.dart';
import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../buttons/buttons.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Cabeçalho operacional da sessão de treino.
class FitWorkoutHeader extends StatelessWidget {
  const FitWorkoutHeader({
    super.key,
    required this.title,
    this.durationLabel,
    this.onClose,
    this.onMore,
  });

  final String title;
  final String? durationLabel;
  final VoidCallback? onClose;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: '$title${durationLabel == null ? '' : ', $durationLabel'}',
      child: Row(
        children: [
          FitIconButton(
            icon: FitIcons.close,
            tooltip: 'Fechar treino',
            onPressed: onClose,
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleLarge,
                ),
                if (durationLabel != null)
                  Text(
                    durationLabel!,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: FitSpacing.s12),
          FitIconButton(
            icon: FitIcons.more,
            tooltip: 'Mais opções',
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}

/// Cabeçalho de progresso do treino com posição e percentual.
class FitWorkoutProgressHeader extends StatelessWidget {
  const FitWorkoutProgressHeader({
    super.key,
    required this.currentExercise,
    required this.totalExercises,
    required this.progress,
    this.label = 'Progresso do treino',
  }) : assert(totalExercises > 0),
       assert(currentExercise >= 0);

  final int currentExercise;
  final int totalExercises;
  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FitProgress(
      value: progress,
      label: label,
      trailing:
          '$currentExercise de $totalExercises · ${(progress.clamp(0.0, 1.0) * 100).round()}%',
      animate: true,
    );
  }
}

/// Viewport para mídia de exercício fornecida externamente.
class FitExerciseMedia extends StatelessWidget {
  const FitExerciseMedia({
    super.key,
    this.child,
    this.loading = false,
    this.fallbackLabel = 'Execução indisponível',
    this.onTap,
    this.semanticLabel,
  });

  final Widget? child;
  final bool loading;
  final String fallbackLabel;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return FitDomainMedia(
      loading: loading,
      fallbackLabel: fallbackLabel,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}

/// Identidade do exercício atual com músculos e ação contextual.
class FitExerciseHeader extends StatelessWidget {
  const FitExerciseHeader({
    super.key,
    required this.name,
    this.muscleGroups = const [],
    this.indexLabel,
    this.trailing,
  });

  final String name;
  final List<String> muscleGroups;
  final String? indexLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label:
          '$name${muscleGroups.isEmpty ? '' : ', ${muscleGroups.join(', ')}'}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (indexLabel != null) ...[
            FitDomainStatusBadge(
              label: indexLabel!,
              tone: FitDomainTone.primary,
            ),
            const SizedBox(width: FitSpacing.s12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineSmall,
                ),
                if (muscleGroups.isNotEmpty) ...[
                  const SizedBox(height: FitSpacing.s4),
                  Text(
                    muscleGroups.join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: FitSpacing.s8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Área responsiva para ações do exercício atual.
class FitExerciseActionBar extends StatelessWidget {
  const FitExerciseActionBar({
    super.key,
    required this.actions,
    this.semanticLabel = 'Ações do exercício',
  });

  final List<Widget> actions;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Wrap(
        spacing: FitSpacing.s8,
        runSpacing: FitSpacing.s8,
        children: actions,
      ),
    );
  }
}
