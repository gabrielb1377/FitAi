import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../../../features/activities/application/running_map_controller.dart';
import '../../../services/running_session_service.dart';
import 'running_map_status.dart';
import 'running_map_view.dart';

typedef RunningMapBuilder =
    Widget Function(BuildContext context, RunningMapController controller);

/// Owns map UI listeners only; mounting/unmounting never starts or stops GPS.
class RunningLiveMap extends StatefulWidget {
  const RunningLiveMap({super.key, required this.service, this.mapBuilder});

  final RunningSessionService service;
  final RunningMapBuilder? mapBuilder;

  @override
  State<RunningLiveMap> createState() => _RunningLiveMapState();
}

class _RunningLiveMapState extends State<RunningLiveMap> {
  late RunningMapController _map;

  @override
  void initState() {
    super.initState();
    _map = RunningMapController(widget.service);
  }

  @override
  void didUpdateWidget(RunningLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _map.dispose();
      _map = RunningMapController(widget.service);
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Widget _renderer(BuildContext context) {
    try {
      return widget.mapBuilder?.call(context, _map) ??
          RunningMapView(key: ObjectKey(_map), map: _map);
    } on Object {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _map.reportAvailability(RunningMapAvailability.unavailable);
        }
      });
      return const RunningMapFallback();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _map,
    builder: (context, _) {
      final status = runningMapStatus(_map);
      return ClipRRect(
        borderRadius: BorderRadius.circular(FitRadius.card),
        child: SizedBox(
          height: FitSpacing.s64 * 4,
          child: Stack(
            children: [
              Positioned.fill(
                child: Semantics(
                  label: 'Mapa da corrida, ${_map.pointCount} pontos aceitos',
                  child:
                      _map.availability == RunningMapAvailability.unavailable ||
                          _map.currentPosition == null
                      ? const RunningMapFallback()
                      : _renderer(context),
                ),
              ),
              Positioned(
                top: FitSpacing.s8,
                right: FitSpacing.s8,
                child: FitIconButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Centralizar no corredor',
                  enabled: _map.currentPosition != null,
                  onPressed: _map.currentPosition == null
                      ? null
                      : _map.recenter,
                ),
              ),
              if (status.isNotEmpty)
                Positioned(
                  left: FitSpacing.s8,
                  right: FitSpacing.s8,
                  bottom: FitSpacing.s32,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(FitRadius.card),
                    child: Padding(
                      padding: const EdgeInsets.all(FitSpacing.s8),
                      child: Text(
                        status,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
              if (_map.availability == RunningMapAvailability.unavailable ||
                  _map.availability == RunningMapAvailability.tilesUnavailable)
                Positioned(
                  top: FitSpacing.s8,
                  left: FitSpacing.s8,
                  child: FitIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Tentar carregar mapa',
                    onPressed: _map.retryProvider,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
