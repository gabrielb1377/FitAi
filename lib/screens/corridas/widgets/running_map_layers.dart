import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/running_map_config.dart';
import '../../../design_system/fit_design_system.dart';

/// Local overlays never expose the route to the raster tile provider.
List<Widget> runningMapLayers({
  required BuildContext context,
  required RunningMapConfig config,
  required LatLng position,
  required List<List<LatLng>> segments,
  required VoidCallback onTileError,
  TileProvider? tileProvider,
}) {
  final colors = Theme.of(context).colorScheme;
  return [
    TileLayer(
      urlTemplate: config.tileUrl,
      userAgentPackageName: RunningMapConfig.userAgentPackageName,
      tileProvider: tileProvider,
      errorTileCallback: (_, _, _) => onTileError(),
    ),
    PolylineLayer(
      polylines: [
        for (final points in segments)
          if (points.length > 1)
            Polyline(
              points: points,
              color: colors.primary,
              strokeWidth: FitSpacing.s4,
            ),
      ],
    ),
    MarkerLayer(
      markers: [
        Marker(
          point: position,
          width: FitSpacing.s32,
          height: FitSpacing.s32,
          child: Icon(
            Icons.location_on,
            color: colors.primary,
            semanticLabel: 'Última posição aceita',
          ),
        ),
      ],
    ),
    Align(
      alignment: Alignment.bottomLeft,
      child: RunningMapAttribution(config: config),
    ),
  ];
}

/// Provider attribution remains visible and opens its copyright notice.
class RunningMapAttribution extends StatelessWidget {
  const RunningMapAttribution({super.key, required this.config});

  final RunningMapConfig config;

  Future<void> _open(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(config.attributionUrl));
    } on Object {
      // The copyright address remains available when URL launching fails.
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(config.attributionUrl)));
    }
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => _open(context),
    style: TextButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surface,
    ),
    child: Text(
      '© ${config.attribution}',
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}
