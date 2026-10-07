import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/running_map_config.dart';
import '../../../features/activities/application/running_map_controller.dart';
import 'running_map_layers.dart';

/// SDK adapter. Coordinates are projected locally, not sent as a route payload.
class RunningMapView extends StatefulWidget {
  const RunningMapView({
    super.key,
    required this.map,
    this.config = const RunningMapConfig(),
    this.tileProvider,
  });

  final RunningMapController map;
  final RunningMapConfig config;
  final TileProvider? tileProvider;

  @override
  State<RunningMapView> createState() => _RunningMapViewState();
}

class _RunningMapViewState extends State<RunningMapView> {
  final _camera = MapController();
  final _points = <List<LatLng>>[];
  var _generation = -1;
  var _cameraRevision = -1;
  var _ready = false;
  var _renderedRevision = -1;
  var _providerRevision = -1;
  ColorScheme? _colors;
  Widget? _rendered;

  @override
  void initState() {
    super.initState();
    widget.map.addListener(_follow);
  }

  void _report(RunningMapAvailability status) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.map.reportAvailability(status);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _follow() {
    if (!_ready ||
        !widget.map.followUser ||
        _cameraRevision == widget.map.cameraRevision) {
      return;
    }
    final point = widget.map.currentPosition;
    if (point == null) return;
    _cameraRevision = widget.map.cameraRevision;
    try {
      _camera.move(
        LatLng(point.latitude, point.longitude),
        _camera.camera.zoom,
      );
    } on Object {
      _report(RunningMapAvailability.unavailable);
    }
  }

  void _appendGeometry() {
    if (_generation != widget.map.generation) {
      _points.clear();
      _generation = widget.map.generation;
    }
    final segments = widget.map.segments;
    for (var index = 0; index < segments.length; index++) {
      if (index == _points.length) _points.add(<LatLng>[]);
      final segment = segments[index];
      for (
        var offset = _points[index].length;
        offset < segment.length;
        offset++
      ) {
        final point = segment[offset];
        _points[index].add(LatLng(point.latitude, point.longitude));
      }
    }
  }

  @override
  void dispose() {
    widget.map.removeListener(_follow);
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.config.isConfigured) {
      _report(RunningMapAvailability.unavailable);
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    if (_renderedRevision == widget.map.routeRevision &&
        _providerRevision == widget.map.providerRevision &&
        _colors == colors) {
      return _rendered!;
    }
    _renderedRevision = widget.map.routeRevision;
    _providerRevision = widget.map.providerRevision;
    _colors = colors;
    _appendGeometry();
    final point = widget.map.currentPosition!;
    return _rendered = FlutterMap(
      key: ValueKey(widget.map.providerRevision),
      mapController: _camera,
      options: MapOptions(
        initialCenter: LatLng(point.latitude, point.longitude),
        initialZoom: 16,
        maxZoom: 19,
        backgroundColor: colors.surfaceContainerHighest,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: () {
          _ready = true;
          _follow();
          _report(RunningMapAvailability.ready);
        },
        onPositionChanged: (_, hasGesture) {
          if (hasGesture) widget.map.manualCameraInteraction();
        },
      ),
      children: runningMapLayers(
        context: context,
        config: widget.config,
        position: LatLng(point.latitude, point.longitude),
        segments: _points,
        tileProvider: widget.tileProvider,
        onTileError: () => _report(RunningMapAvailability.tilesUnavailable),
      ),
    );
  }
}
