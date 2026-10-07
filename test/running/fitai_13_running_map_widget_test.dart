import 'dart:convert';
import 'dart:typed_data';

import 'package:fitai/core/config/running_map_config.dart';
import 'package:fitai/features/activities/application/running_map_controller.dart';
import 'package:fitai/screens/corridas/widgets/running_live_map.dart';
import 'package:fitai/screens/corridas/widgets/running_map_view.dart';
import 'package:fitai/services/running_session_service.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryMapTiles extends TileProvider {
  @override
  ImageProvider getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) => MemoryImage(
    Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    ),
  );
}

class FailedTile extends Fake implements TileImage {}

void main() {
  late RunningSessionService service;
  late DateTime now;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime.utc(2026, 10, 6, 12);
    service = RunningSessionService.forTesting(clock: () => now);
    await service.start();
    service.recordLocationForTesting(
      latitude: 0,
      longitude: 0,
      recordedAt: now,
    );
    now = now.add(const Duration(seconds: 10));
    service.recordLocationForTesting(
      latitude: 0,
      longitude: 0.0001,
      recordedAt: now,
    );
  });
  tearDown(() => service.dispose());

  Widget app(Widget child, {double scale = 1}) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: child,
      ),
    ),
  );

  testWidgets(
    'RUN-MAP SDK renders polyline and accepted marker without network',
    (tester) async {
      RunningMapController? projected;
      await tester.pumpWidget(
        app(
          RunningLiveMap(
            service: service,
            mapBuilder: (_, map) {
              projected = map;
              return RunningMapView(map: map, tileProvider: MemoryMapTiles());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);
      final line = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(line.polylines.single.points, hasLength(2));
      expect(line.polylines.single.points.last.longitude, 0.0001);
      expect(projected!.availability, RunningMapAvailability.ready);
      await tester.drag(find.byType(FlutterMap), const Offset(70, 0));
      await tester.pumpAndSettle();
      expect(projected!.followUser, isFalse);
      await tester.tap(find.byTooltip('Centralizar no corredor'));
      await tester.pumpAndSettle();
      expect(projected!.followUser, isTrue);
      final camera = MapController.of(
        tester.element(find.byType(PolylineLayer)),
      ).camera;
      expect(camera.center.longitude, closeTo(0.0001, 0.000001));
      now = now.add(const Duration(seconds: 10));
      service.recordLocationForTesting(
        latitude: 0,
        longitude: 0.0002,
        recordedAt: now,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PolylineLayer>(find.byType(PolylineLayer))
            .polylines
            .single
            .points,
        hasLength(3),
      );
      expect(
        MapController.of(
          tester.element(find.byType(PolylineLayer)),
        ).camera.center.longitude,
        closeTo(0.0002, 0.000001),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('RUN-MAP-FALLBACK-02 initialization failure handled', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        RunningLiveMap(
          service: service,
          mapBuilder: (_, _) => throw StateError('test initialization failure'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mapa indisponível. A corrida continua.'), findsOneWidget);
    expect(service.isRunning, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('RUN-MAP config unavailable remains recoverable', (tester) async {
    await tester.pumpWidget(
      app(
        RunningLiveMap(
          service: service,
          mapBuilder: (_, map) => RunningMapView(
            map: map,
            config: const RunningMapConfig(tileUrl: ''),
            tileProvider: MemoryMapTiles(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mapa indisponível. A corrida continua.'), findsOneWidget);
    expect(find.byTooltip('Tentar carregar mapa'), findsOneWidget);
    expect(service.isRunning, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('RUN-MAP tile failure retains route and controls', (
    tester,
  ) async {
    RunningMapController? projected;
    await tester.pumpWidget(
      app(
        RunningLiveMap(
          service: service,
          mapBuilder: (_, map) {
            projected = map;
            return RunningMapView(map: map, tileProvider: MemoryMapTiles());
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tile = tester.widget<TileLayer>(find.byType(TileLayer));
    tile.errorTileCallback!(FailedTile(), StateError('offline'), null);
    await tester.pumpAndSettle();
    expect(projected!.availability, RunningMapAvailability.tilesUnavailable);
    expect(projected!.pointCount, 2);
    expect(
      find.text('Mapa base indisponível. A rota local continua.'),
      findsOneWidget,
    );
    expect(find.byType(PolylineLayer), findsOneWidget);
    expect(service.isRunning, isTrue);
    await tester.tap(find.byTooltip('Tentar carregar mapa'));
    await tester.pumpAndSettle();
    expect(projected!.availability, RunningMapAvailability.ready);
    expect(projected!.pointCount, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('RUN-MAP responsive $width with text 200%', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          RunningLiveMap(
            service: service,
            mapBuilder: (_, map) =>
                RunningMapView(map: map, tileProvider: MemoryMapTiles()),
          ),
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final target = tester.getSize(find.byTooltip('Centralizar no corredor'));
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
