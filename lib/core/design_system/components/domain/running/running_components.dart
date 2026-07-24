import 'package:flutter/material.dart';

import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_layout.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../buttons/buttons.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Estado visual da disponibilidade de GPS.
enum FitGPSState { connecting, connected, weak, unavailable }

/// Resumo de corridas para dashboards.
class FitRunningDashboardCard extends StatelessWidget {
  const FitRunningDashboardCard({
    super.key,
    required this.title,
    required this.metrics,
    this.subtitle,
    this.action,
    this.loading = false,
  });

  final String title;
  final String? subtitle;
  final List<FitMetricData> metrics;
  final Widget? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: subtitle,
      icon: FitIcons.running,
      accent: context.fitColors.running,
      metrics: metrics,
      footer: action,
      loading: loading,
    );
  }
}

/// Métrica unitária de corrida.
class FitRunMetric extends StatelessWidget {
  const FitRunMetric({super.key, required this.data});

  final FitMetricData data;

  @override
  Widget build(BuildContext context) {
    return FitStatistic(
      label: data.label,
      value: data.value,
      icon: data.icon,
      unit: data.unit,
      detail: data.detail,
      color: data.color ?? context.fitColors.running,
    );
  }
}

/// Grade responsiva de métricas atualizadas durante a corrida.
class FitRunLiveMetricGrid extends StatelessWidget {
  const FitRunLiveMetricGrid({super.key, required this.metrics});

  final List<FitMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return FitDomainMetricStrip(metrics: metrics);
  }
}

/// Container visual de mapa; mapa e localização são fornecidos pelo chamador.
class FitRunMapContainer extends StatelessWidget {
  const FitRunMapContainer({
    super.key,
    this.child,
    this.loading = false,
    this.fallbackLabel = 'Mapa indisponível',
    this.onTap,
  });

  final Widget? child;
  final bool loading;
  final String fallbackLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainMedia(
      loading: loading,
      fallbackLabel: fallbackLabel,
      fallbackIcon: FitIcons.map,
      aspectRatio: FitLayout.domainMapAspectRatio,
      onTap: onTap,
      semanticLabel: 'Mapa da corrida',
      child: child,
    );
  }
}

/// Indicador de conexão GPS sem consultar sensores.
class FitGPSStatus extends StatelessWidget {
  const FitGPSStatus({super.key, required this.state, this.label});

  final FitGPSState state;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (defaultLabel, tone, icon) = switch (state) {
      FitGPSState.connecting => (
        'Conectando GPS',
        FitDomainTone.neutral,
        FitIcons.gps,
      ),
      FitGPSState.connected => (
        'GPS conectado',
        FitDomainTone.primary,
        FitIcons.gps,
      ),
      FitGPSState.weak => (
        'Sinal GPS fraco',
        FitDomainTone.warning,
        FitIcons.gps,
      ),
      FitGPSState.unavailable => (
        'GPS indisponível',
        FitDomainTone.error,
        FitIcons.gpsOff,
      ),
    };
    return FitDomainStatusBadge(
      label: label ?? defaultLabel,
      tone: tone,
      icon: icon,
    );
  }
}

/// Barra de controles da corrida com callbacks externos.
class FitRunControlBar extends StatelessWidget {
  const FitRunControlBar({
    super.key,
    required this.active,
    this.paused = false,
    this.onStart,
    this.onTogglePause,
    this.onFinish,
  });

  final bool active;
  final bool paused;
  final VoidCallback? onStart;
  final VoidCallback? onTogglePause;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Controles da corrida',
      child: Row(
        children: [
          if (!active)
            Expanded(
              child: FitPrimaryButton(
                label: 'Iniciar corrida',
                icon: FitIcons.play,
                onPressed: onStart,
                fullWidth: true,
              ),
            )
          else ...[
            Expanded(
              child: FitPrimaryButton(
                label: paused ? 'Retomar' : 'Pausar',
                icon: paused ? FitIcons.play : FitIcons.pause,
                onPressed: onTogglePause,
                fullWidth: true,
              ),
            ),
            const SizedBox(width: FitSpacing.s12),
            FitDangerButton(
              label: 'Finalizar',
              icon: FitIcons.stop,
              onPressed: onFinish,
            ),
          ],
        ],
      ),
    );
  }
}

/// Painel exibido enquanto a corrida está pausada.
class FitRunPausePanel extends StatelessWidget {
  const FitRunPausePanel({
    super.key,
    required this.durationLabel,
    this.message = 'Corrida pausada',
    this.onResume,
    this.onFinish,
  });

  final String durationLabel;
  final String message;
  final VoidCallback? onResume;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    return FitInfoCard(
      title: message,
      description: durationLabel,
      icon: FitIcons.pause,
      tone: FitInfoCardTone.warning,
      action: FitOutlinedButton(
        label: 'Retomar',
        icon: FitIcons.play,
        onPressed: onResume,
      ),
    );
  }
}

/// Resumo de uma corrida finalizada.
class FitRunSummaryCard extends StatelessWidget {
  const FitRunSummaryCard({
    super.key,
    required this.title,
    required this.metrics,
    this.subtitle,
    this.routePreview,
    this.action,
  });

  final String title;
  final String? subtitle;
  final List<FitMetricData> metrics;
  final Widget? routePreview;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: subtitle,
      icon: FitIcons.running,
      accent: context.fitColors.running,
      media: routePreview,
      metrics: metrics,
      footer: action,
    );
  }
}

/// Gráfico de pace recebido já agregado.
class FitPaceChartCard extends StatelessWidget {
  const FitPaceChartCard({
    super.key,
    required this.points,
    this.title = 'Ritmo',
    this.subtitle,
  });

  final List<FitChartPoint> points;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      title: title,
      subtitle: subtitle,
      child: FitDomainBarChart(
        points: points,
        semanticLabel: 'Gráfico de ritmo',
        color: context.fitColors.running,
      ),
    );
  }
}

/// Zona cardíaca com progresso calculado externamente.
class FitHeartRateZoneCard extends StatelessWidget {
  const FitHeartRateZoneCard({
    super.key,
    required this.zoneLabel,
    required this.valueLabel,
    required this.progress,
    this.description,
  });

  final String zoneLabel;
  final String valueLabel;
  final double progress;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return FitProgressCard(
      title: zoneLabel,
      value: valueLabel,
      progress: progress,
      icon: FitIcons.heart,
      color: context.fitColors.energy,
      description: description,
    );
  }
}

/// Linha de split por distância ou intervalo.
class FitSplitRow extends StatelessWidget {
  const FitSplitRow({
    super.key,
    required this.label,
    required this.paceLabel,
    this.durationLabel,
    this.trailing,
  });

  final String label;
  final String paceLabel;
  final String? durationLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: label,
      subtitle: durationLabel,
      leading: Icon(FitIcons.pace, color: context.fitColors.running),
      trailing:
          trailing ?? Text(paceLabel, style: context.textTheme.titleSmall),
      semanticLabel: '$label, ritmo $paceLabel',
    );
  }
}

/// Card de rota com mapa fornecido externamente.
class FitRouteCard extends StatelessWidget {
  const FitRouteCard({
    super.key,
    required this.title,
    this.subtitle,
    this.map,
    this.metrics = const [],
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? map;
  final List<FitMetricData> metrics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: subtitle,
      icon: FitIcons.map,
      accent: context.fitColors.running,
      media: map,
      metrics: metrics,
      trailing: const Icon(FitIcons.forward),
      onTap: onTap,
    );
  }
}

/// Etapa de treino intervalado sem controlar o relógio.
class FitIntervalStepCard extends StatelessWidget {
  const FitIntervalStepCard({
    super.key,
    required this.title,
    required this.durationLabel,
    this.description,
    this.current = false,
    this.completed = false,
  });

  final String title;
  final String durationLabel;
  final String? description;
  final bool current;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      selected: current,
      title: title,
      subtitle: description,
      leading: Icon(
        completed ? FitIcons.success : FitIcons.timer,
        color: current || completed
            ? context.colors.primary
            : context.colors.onSurfaceVariant,
      ),
      trailing: Text(durationLabel, style: context.textTheme.titleSmall),
      child: const SizedBox.shrink(),
    );
  }
}

/// Recorde pessoal de corrida.
class FitPersonalRunRecordCard extends StatelessWidget {
  const FitPersonalRunRecordCard({
    super.key,
    required this.title,
    required this.value,
    this.description,
    this.onTap,
  });

  final String title;
  final String value;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitProgressCard(
      title: title,
      value: value,
      progress: 1,
      icon: FitIcons.achievement,
      color: context.fitColors.achievement,
      description: description,
      onTap: onTap,
    );
  }
}
