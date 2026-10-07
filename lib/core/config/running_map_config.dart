/// Public tile configuration. Provider secrets never belong in this build.
class RunningMapConfig {
  const RunningMapConfig({
    this.tileUrl = const String.fromEnvironment(
      'RUN_MAP_TILE_URL',
      defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    this.attribution = const String.fromEnvironment(
      'RUN_MAP_ATTRIBUTION',
      defaultValue: 'OpenStreetMap contributors',
    ),
    this.attributionUrl = const String.fromEnvironment(
      'RUN_MAP_ATTRIBUTION_URL',
      defaultValue: 'https://www.openstreetmap.org/copyright',
    ),
  });

  final String tileUrl;
  final String attribution;
  final String attributionUrl;
  static const userAgentPackageName = 'com.example.fitai';

  bool get isConfigured {
    final tiles = Uri.tryParse(tileUrl);
    final credits = Uri.tryParse(attributionUrl);
    return tiles?.scheme == 'https' &&
        tiles!.host.isNotEmpty &&
        tileUrl.contains('{z}') &&
        tileUrl.contains('{x}') &&
        tileUrl.contains('{y}') &&
        credits?.scheme == 'https' &&
        credits!.host.isNotEmpty &&
        attribution.trim().isNotEmpty;
  }
}
