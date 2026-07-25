import 'package:flutter/material.dart';

import '../../../../../design_system/components/fit_progress.dart';
import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_layout.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../buttons/buttons.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Cronômetro visual de descanso controlado externamente.
class FitRestTimerWidget extends StatelessWidget {
  const FitRestTimerWidget({
    super.key,
    required this.remainingLabel,
    required this.progress,
    this.paused = false,
    this.embedded = false,
    this.progressRingSize,
    this.onTogglePause,
    this.onSkip,
    this.onAddTime,
    this.addTimeLabel = 'Adicionar tempo',
  });

  final String remainingLabel;
  final double progress;
  final bool paused;

  /// Remove a superfície externa quando o temporizador é usado dentro de um
  /// painel de exercício já enquadrado.
  final bool embedded;

  /// Tamanho opcional do anel para superfícies compactas.
  final double? progressRingSize;
  final VoidCallback? onTogglePause;
  final VoidCallback? onSkip;
  final VoidCallback? onAddTime;
  final String addTimeLabel;

  @override
  Widget build(BuildContext context) {
    final content = Semantics(
      label: 'Descanso, $remainingLabel',
      child: Column(
        children: [
          FitProgressRing(
            value: progress,
            label: remainingLabel,
            size: progressRingSize ?? FitLayout.domainProgressRingLarge,
            strokeWidth: FitLayout.domainProgressRingStroke,
          ),
          const SizedBox(height: FitSpacing.s16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: FitSpacing.s8,
            runSpacing: FitSpacing.s8,
            children: [
              FitOutlinedButton(
                label: paused ? 'Retomar' : 'Pausar',
                icon: paused ? FitIcons.play : FitIcons.pause,
                onPressed: onTogglePause,
              ),
              FitGhostButton(
                label: addTimeLabel,
                icon: FitIcons.addTime,
                onPressed: onAddTime,
              ),
              FitGhostButton(
                label: 'Pular',
                icon: FitIcons.skip,
                onPressed: onSkip,
              ),
            ],
          ),
        ],
      ),
    );

    if (embedded) return content;
    return FitCard(child: content);
  }
}

/// Conteúdo completo de uma etapa de descanso, sem controlar tempo.
class FitExerciseRestScreenContent extends StatelessWidget {
  const FitExerciseRestScreenContent({
    super.key,
    required this.timer,
    this.title = 'Recupere-se',
    this.description,
    this.nextExercise,
  });

  final Widget timer;
  final String title;
  final String? description;
  final Widget? nextExercise;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall,
          ),
          if (description != null) ...[
            const SizedBox(height: FitSpacing.s8),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: FitSpacing.s24),
          timer,
          if (nextExercise != null) ...[
            const SizedBox(height: FitSpacing.s16),
            nextExercise!,
          ],
        ],
      ),
    );
  }
}

/// Prévia do próximo exercício da sessão.
class FitNextExerciseCard extends StatelessWidget {
  const FitNextExerciseCard({
    super.key,
    required this.name,
    this.details,
    this.media,
    this.onTap,
  });

  final String name;
  final String? details;
  final Widget? media;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: name,
      subtitle: details,
      icon: FitIcons.skip,
      media: media,
      trailing: const Icon(FitIcons.forward),
      onTap: onTap,
      semanticLabel: 'Próximo exercício, $name',
    );
  }
}

/// Controle compacto para uma sessão de treino em segundo plano visual.
class FitWorkoutMiniPlayer extends StatelessWidget {
  const FitWorkoutMiniPlayer({
    super.key,
    required this.title,
    required this.progress,
    this.subtitle,
    this.paused = false,
    this.onTap,
    this.onTogglePause,
    this.onNext,
  });

  final String title;
  final String? subtitle;
  final double progress;
  final bool paused;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePause;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      onTap: onTap,
      variant: onTap == null
          ? FitCardVariant.outlined
          : FitCardVariant.clickable,
      semanticLabel: 'Treino em andamento, $title',
      child: Column(
        children: [
          Row(
            children: [
              Icon(FitIcons.workout, color: context.colors.primary),
              const SizedBox(width: FitSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              FitIconButton(
                icon: paused ? FitIcons.play : FitIcons.pause,
                tooltip: paused ? 'Retomar treino' : 'Pausar treino',
                onPressed: onTogglePause,
              ),
              FitIconButton(
                icon: FitIcons.skip,
                tooltip: 'Próximo exercício',
                onPressed: onNext,
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s8),
          FitProgress(value: progress),
        ],
      ),
    );
  }
}

/// Mensagem curta do Coach apresentada durante o treino.
class FitWorkoutCoachBubble extends StatelessWidget {
  const FitWorkoutCoachBubble({
    super.key,
    required this.message,
    this.title = 'Coach FitIA',
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return FitInfoCard(
      title: title,
      description: message,
      icon: FitIcons.coach,
      tone: FitInfoCardTone.info,
      action: onAction == null
          ? null
          : FitGhostButton(
              label: actionLabel!,
              onPressed: onAction,
              icon: FitIcons.ai,
            ),
    );
  }
}

/// Prévia das séries anteriores do exercício.
class FitExerciseHistoryPreview extends StatelessWidget {
  const FitExerciseHistoryPreview({
    super.key,
    required this.series,
    this.title = 'Histórico da série',
    this.onViewAll,
  });

  final List<FitSeriesDisplayData> series;
  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      title: title,
      trailing: onViewAll == null
          ? null
          : FitGhostButton(label: 'Ver todas', onPressed: onViewAll),
      child: series.isEmpty
          ? Text(
              'Nenhuma série registrada.',
              style: context.textTheme.bodyMedium,
            )
          : Wrap(
              spacing: FitSpacing.s8,
              runSpacing: FitSpacing.s8,
              children: [
                for (final item in series)
                  FitDomainStatusBadge(
                    label:
                        '${item.index}: ${item.weight?.toStringAsFixed(0) ?? '--'} ${item.weightUnit} × ${item.repetitions}',
                    tone: item.current
                        ? FitDomainTone.primary
                        : FitDomainTone.neutral,
                    icon: item.completed ? FitIcons.check : null,
                  ),
              ],
            ),
    );
  }
}

/// Prévia gráfica da progressão do exercício.
class FitExerciseProgressPreview extends StatelessWidget {
  const FitExerciseProgressPreview({
    super.key,
    required this.points,
    this.title = 'Progressão',
    this.onViewDetails,
  });

  final List<FitChartPoint> points;
  final String title;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      title: title,
      trailing: onViewDetails == null
          ? null
          : FitGhostButton(label: 'Detalhes', onPressed: onViewDetails),
      child: FitDomainBarChart(
        points: points,
        semanticLabel: 'Evolução do exercício',
      ),
    );
  }
}
