import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/running_session_model.dart';
import 'package:fitai/screens/corridas/corrida_detalhe_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('detalhe mostra metricas, status e parcial GPS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: CorridaDetalhePage(
          corrida: CorridaModel(
            id: 'run-detail-1',
            distancia: 1.01,
            segundos: 300,
            data: '2026-08-02T08:00:00.000',
            steps: 1300,
            route: const [
              RunningRoutePointModel(
                latitude: 0,
                longitude: 0,
                accuracy: 5,
                altitude: 0,
                speed: 3,
                timestamp: '2026-08-02T08:00:00.000',
                cumulativeDistanceKm: 0,
                activeElapsedSeconds: 0,
              ),
              RunningRoutePointModel(
                latitude: 0,
                longitude: 0.0091,
                accuracy: 5,
                altitude: 0,
                speed: 3,
                timestamp: '2026-08-02T08:05:00.000',
                cumulativeDistanceKm: 1.01,
                activeElapsedSeconds: 300,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Detalhe da corrida'), findsOneWidget);
    expect(find.text('Ritmo medio'), findsOneWidget);
    expect(find.text('Passos'), findsOneWidget);
    expect(find.text('Km 1'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Resumo da corrida')), findsOneWidget);
  });
}
