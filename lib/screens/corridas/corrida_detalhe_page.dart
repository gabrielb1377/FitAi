import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import '../../models/corrida_model.dart';
import '../../models/running_session_model.dart';
import '../../models/running_split_model.dart';
import '../../services/storage_service.dart';
import '../widgets/activities/activities_navigation_header.dart';

/// Detalhe local de uma corrida finalizada. A rota GPS e opcional.
class CorridaDetalhePage extends StatelessWidget {
  const CorridaDetalhePage({super.key, required this.corrida});

  final CorridaModel corrida;

  @override
  Widget build(BuildContext context) {
    final splits = RunningSplitModel.fromRoute(corrida.route);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            FitSpacing.s20,
            FitSpacing.s12,
            FitSpacing.s20,
            FitSpacing.s32,
          ),
          children: [
            ActivitiesNavigationHeader(
              title: 'Detalhe da corrida',
              subtitle: _dateLabel(corrida),
              trailing: _syncBadge(corrida.syncStatus),
            ),
            const SizedBox(height: FitSpacing.s24),
            Semantics(
              container: true,
              label:
                  'Resumo da corrida, ${_distanceLabel(corrida)} em ${_timeLabel(corrida.segundos)}',
              child: FitCard(
                variant: FitCardVariant.outlined,
                title: _distanceLabel(corrida),
                subtitle: '${_timeLabel(corrida.segundos)} de corrida',
                leading: const Icon(Icons.directions_run_rounded),
                child: const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: FitSpacing.s16),
            _MetricsGrid(corrida: corrida),
            const SizedBox(height: FitSpacing.s24),
            FitSectionHeader(
              title: 'Parciais',
              badge: FitBadge(
                label: splits.isEmpty ? 'Sem GPS' : '${splits.length} km',
                tone: splits.isEmpty
                    ? FitBadgeTone.neutral
                    : FitBadgeTone.success,
                icon: splits.isEmpty
                    ? Icons.location_off_outlined
                    : Icons.route_outlined,
              ),
            ),
            const SizedBox(height: FitSpacing.s12),
            if (splits.isEmpty)
              const FitCard(
                variant: FitCardVariant.outlined,
                child: Text(
                  'As parciais aparecem quando a corrida possui pontos GPS suficientes.',
                ),
              )
            else
              FitCard(
                variant: FitCardVariant.outlined,
                child: Column(
                  children: [
                    for (final split in splits) ...[
                      FitSplitRow(
                        label: 'Km ${split.kilometer}',
                        durationLabel: _timeLabel(split.elapsedSeconds),
                        paceLabel: _paceLabel(split.paceMinutesPerKm),
                      ),
                      if (split != splits.last) const FitDivider(),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: FitSpacing.s24),
            FitCard(
              variant: FitCardVariant.outlined,
              title: 'GPS',
              subtitle: corrida.route.isEmpty
                  ? 'Nenhum ponto GPS foi salvo nesta corrida.'
                  : '${corrida.route.length} pontos registrados localmente.',
              leading: Icon(
                corrida.route.isEmpty
                    ? Icons.location_off_outlined
                    : Icons.location_on_outlined,
              ),
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  static FitBadge _syncBadge(RunningSyncStatus status) {
    return switch (status) {
      RunningSyncStatus.synced => const FitBadge.success(
        label: 'Sincronizada',
        icon: Icons.cloud_done_outlined,
      ),
      RunningSyncStatus.syncing => const FitBadge(
        label: 'Sincronizando',
        tone: FitBadgeTone.info,
        icon: Icons.sync_rounded,
      ),
      RunningSyncStatus.queued => const FitBadge.offline(),
      RunningSyncStatus.conflict => const FitBadge(
        label: 'Conflito local',
        tone: FitBadgeTone.warning,
        icon: Icons.sync_problem_outlined,
      ),
      RunningSyncStatus.local => const FitBadge(
        label: 'Local',
        tone: FitBadgeTone.neutral,
        icon: Icons.phone_android_outlined,
      ),
    };
  }

  static String _distanceLabel(CorridaModel corrida) =>
      '${corrida.distancia.toStringAsFixed(2)} km';

  static String _timeLabel(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainder = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  static String _paceLabel(double pace) {
    if (pace <= 0) return '--';
    final seconds = (pace * 60).round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} min/km';
  }

  static String _dateLabel(CorridaModel corrida) {
    final date = DateTime.tryParse(corrida.endTime ?? corrida.data);
    if (date == null) return 'Corrida salva localmente';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Resolve uma corrida persistida para suportar links internos sem depender da
/// pagina de historico como origem.
class CorridaDetalhePorIdPage extends StatelessWidget {
  const CorridaDetalhePorIdPage({super.key, required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CorridaModel?>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: SafeArea(child: FitLoading.fullScreen()));
        }
        final corrida = snapshot.data;
        if (corrida == null) {
          return Scaffold(
            body: SafeArea(
              child: FitErrorState(
                title: 'Corrida indisponivel',
                error: 'Essa corrida nao existe mais no armazenamento local.',
              ),
            ),
          );
        }
        return CorridaDetalhePage(corrida: corrida);
      },
    );
  }

  Future<CorridaModel?> _load() async {
    final normalizedId = runId.trim();
    if (normalizedId.isEmpty) return null;
    final corridas = await StorageService.carregarCorridas();
    for (final corrida in corridas) {
      if (corrida.id == normalizedId) return corrida;
    }
    return null;
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.corrida});

  final CorridaModel corrida;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        label: 'Ritmo medio',
        value: CorridaDetalhePage._paceLabel(corrida.pace),
        icon: Icons.route_outlined,
      ),
      (
        label: 'Velocidade media',
        value: '${corrida.averageSpeed.toStringAsFixed(1)} km/h',
        icon: Icons.speed_outlined,
      ),
      if (corrida.hasReliableCalories)
        (
          label: 'Calorias',
          value: '${corrida.calories!.toStringAsFixed(0)} kcal',
          icon: Icons.local_fire_department_outlined,
        ),
      if (corrida.steps != null)
        (
          label: 'Passos',
          value: '${corrida.steps}',
          icon: Icons.directions_walk_outlined,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: FitSpacing.s12,
            mainAxisSpacing: FitSpacing.s12,
            childAspectRatio: 1.7,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return FitMetricCard(
              label: metric.label,
              value: metric.value,
              icon: metric.icon,
            );
          },
        );
      },
    );
  }
}
