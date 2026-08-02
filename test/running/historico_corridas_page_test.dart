import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/running_session_model.dart';
import 'package:fitai/screens/corridas/historico_corridas_page.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('histórico não exibe calorias sem fonte declarada', (
    tester,
  ) async {
    await StorageService.salvarCorrida(
      CorridaModel(
        id: 'history-without-calories-source',
        distancia: 3.5,
        segundos: 1260,
        data: '2026-08-02T08:00:00.000',
        calories: 210,
      ),
    );

    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Histórico de corridas'), findsOneWidget);
    expect(find.text('Calorias'), findsNothing);
    expect(find.byTooltip('Excluir corrida'), findsOneWidget);
  });

  testWidgets('exclusão pede confirmação antes de alterar o histórico', (
    tester,
  ) async {
    await StorageService.salvarCorrida(
      CorridaModel(
        id: 'history-delete-confirmation',
        distancia: 2,
        segundos: 600,
        data: '2026-08-02T08:00:00.000',
        calories: 120,
        caloriesSource: RunningCaloriesSource.device,
      ),
    );

    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir corrida'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir corrida?'), findsOneWidget);
    expect(await StorageService.carregarCorridas(), hasLength(1));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await StorageService.carregarCorridas(), hasLength(1));
  });
}

Widget _host() =>
    MaterialApp(theme: AppTheme.dark, home: const HistoricoCorridasPage());
