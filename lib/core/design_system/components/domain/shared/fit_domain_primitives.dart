import 'package:flutter/material.dart';

import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_layout.dart';
import '../../../../../design_system/tokens/fit_opacity.dart';
import '../../../../../design_system/tokens/fit_radius.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../../feedback/feedback.dart';
import 'fit_domain_models.dart';

/// Superfície interna compartilhada pelas composições de domínio.
class FitDomainContentCard extends StatelessWidget {
  const FitDomainContentCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accent,
    this.media,
    this.tags = const [],
    this.metrics = const [],
    this.progress,
    this.trailing,
    this.footer,
    this.onTap,
    this.loading = false,
    this.enabled = true,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? accent;
  final Widget? media;
  final List<Widget> tags;
  final List<FitMetricData> metrics;
  final double? progress;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;
  final bool loading;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (loading) return FitLoadingCard(semanticLabel: semanticLabel ?? title);
    final resolvedAccent = accent ?? context.colors.primary;
    return Opacity(
      opacity: enabled
          ? FitLayout.navigationSelectedScale
          : FitOpacity.disabled,
      child: FitCard(
        title: title,
        subtitle: subtitle,
        leading: icon == null ? null : Icon(icon, color: resolvedAccent),
        trailing: trailing,
        footer: footer,
        onTap: enabled ? onTap : null,
        semanticLabel: semanticLabel ?? title,
        variant: onTap == null
            ? FitCardVariant.outlined
            : FitCardVariant.clickable,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (media != null) ...[
              media!,
              const SizedBox(height: FitSpacing.s12),
            ],
            if (tags.isNotEmpty) ...[
              Wrap(
                spacing: FitSpacing.s8,
                runSpacing: FitSpacing.s8,
                children: tags,
              ),
              const SizedBox(height: FitSpacing.s12),
            ],
            if (metrics.isNotEmpty) FitDomainMetricStrip(metrics: metrics),
            if (progress != null) ...[
              if (metrics.isNotEmpty) const SizedBox(height: FitSpacing.s12),
              FitProgressRing(
                value: progress!.clamp(0.0, 1.0),
                size: FitLayout.progressRingSize,
                strokeWidth: FitLayout.progressRingStroke,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Faixa responsiva de métricas já formatadas.
class FitDomainMetricStrip extends StatelessWidget {
  const FitDomainMetricStrip({
    super.key,
    required this.metrics,
    this.compact = false,
  });

  final List<FitMetricData> metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: FitSpacing.s12,
      runSpacing: FitSpacing.s12,
      children: [
        for (final metric in metrics)
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: compact
                  ? FitLayout.domainMetricMinWidth
                  : FitLayout.domainMetricMaxWidth,
              maxWidth: FitLayout.domainMetricMaxWidth,
            ),
            child: FitStatistic(
              label: metric.label,
              value: metric.value,
              icon: metric.icon,
              unit: metric.unit,
              detail: metric.detail,
              color: metric.color,
            ),
          ),
      ],
    );
  }
}

/// Viewport de mídia com loading e fallback sem lógica de asset.
class FitDomainMedia extends StatelessWidget {
  const FitDomainMedia({
    super.key,
    this.child,
    this.loading = false,
    this.fallbackLabel = 'Mídia indisponível',
    this.fallbackIcon = FitIcons.exercise,
    this.aspectRatio = FitLayout.domainMediaAspectRatio,
    this.onTap,
    this.semanticLabel,
  }) : assert(aspectRatio > 0);

  final Widget? child;
  final bool loading;
  final String fallbackLabel;
  final IconData fallbackIcon;
  final double aspectRatio;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: FitRadius.mediumBorder,
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: FitRadius.mediumBorder,
          child: loading
              ? const Center(child: FitCircularLoading())
              : child ??
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            fallbackIcon,
                            size: FitLayout.iconSizeLarge,
                            color: context.colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: FitSpacing.s8),
                          Text(
                            fallbackLabel,
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
    return Semantics(
      image: onTap == null,
      button: onTap != null,
      label: semanticLabel ?? fallbackLabel,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: FitRadius.mediumBorder,
              child: content,
            ),
    );
  }
}

/// Badge interno que resolve papéis cromáticos de domínio.
class FitDomainStatusBadge extends StatelessWidget {
  const FitDomainStatusBadge({
    super.key,
    required this.label,
    this.tone = FitDomainTone.neutral,
    this.icon,
  });

  final String label;
  final FitDomainTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = resolveFitDomainTone(context, tone);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FitSpacing.s8,
          vertical: FitSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: FitOpacity.selected),
          borderRadius: FitRadius.pillBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: FitLayout.iconSizeBadge, color: color),
              const SizedBox(width: FitSpacing.s4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de barras sem agregação ou dependência externa.
class FitDomainBarChart extends StatelessWidget {
  const FitDomainBarChart({
    super.key,
    required this.points,
    required this.semanticLabel,
    this.color,
  });

  final List<FitChartPoint> points;
  final String semanticLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return FitEmptyState(
        title: 'Sem dados',
        description: semanticLabel,
        icon: FitIcons.progress,
      );
    }
    final maxValue = points
        .map((point) => point.value.abs())
        .reduce((a, b) => a > b ? a : b);
    final divisor = maxValue == 0
        ? FitLayout.navigationSelectedScale
        : maxValue;
    final resolvedColor = color ?? context.fitColors.chartProgress;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: FitLayout.domainChartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in points)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FitSpacing.s2,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: (point.value.abs() / divisor)
                                  .clamp(
                                    FitOpacity.subtle,
                                    FitLayout.navigationSelectedScale,
                                  )
                                  .toDouble(),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: resolvedColor,
                                  borderRadius: FitRadius.smallBorder,
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: FitSpacing.s4),
                        Text(
                          point.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resolve um papel cromático sem criar acento global.
Color resolveFitDomainTone(BuildContext context, FitDomainTone tone) {
  return switch (tone) {
    FitDomainTone.neutral => context.colors.onSurfaceVariant,
    FitDomainTone.primary => context.colors.primary,
    FitDomainTone.info => context.fitColors.chartInformation,
    FitDomainTone.ai => context.fitColors.ai,
    FitDomainTone.running => context.fitColors.running,
    FitDomainTone.steps => context.fitColors.steps,
    FitDomainTone.energy => context.fitColors.energy,
    FitDomainTone.achievement => context.fitColors.achievement,
    FitDomainTone.premium => context.fitColors.premium,
    FitDomainTone.warning => context.colors.tertiary,
    FitDomainTone.error => context.colors.error,
  };
}
