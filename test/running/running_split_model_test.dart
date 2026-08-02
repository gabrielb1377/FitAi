import 'package:fitai/models/running_session_model.dart';
import 'package:fitai/models/running_split_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gera parciais apenas quando a rota possui distancia suficiente', () {
    final splits = RunningSplitModel.fromRoute([
      const RunningRoutePointModel(
        latitude: 0,
        longitude: 0,
        accuracy: 5,
        altitude: 0,
        speed: 2.8,
        timestamp: '2026-08-02T08:00:00.000',
      ),
      const RunningRoutePointModel(
        latitude: 0,
        longitude: 0.0091,
        accuracy: 5,
        altitude: 0,
        speed: 2.8,
        timestamp: '2026-08-02T08:05:00.000',
      ),
    ]);

    expect(splits, hasLength(1));
    expect(splits.single.kilometer, 1);
    expect(splits.single.elapsedSeconds, greaterThan(0));
  });

  test('nao inventa parcial quando GPS esta ausente', () {
    expect(RunningSplitModel.fromRoute(const []), isEmpty);
  });
}
