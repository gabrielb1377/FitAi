import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai/design_system/design_system.dart';
import 'package:fitai/features/settings/application/settings_runtime.dart';
import 'package:fitai/features/settings/data/settings_local_store.dart';
import 'package:fitai/features/settings/data/settings_repository.dart';
import 'package:fitai/features/settings/presentation/pages/settings_page.dart';

void main() {
  testWidgets('organiza configuracoes por grupos e abre unidades', (
    tester,
  ) async {
    final controller = SettingsController(
      repository: SettingsRepository(
        store: InMemorySettingsLocalStore(),
        userIdResolver: () async => 'test-user',
      ),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: FitTheme.dark(),
        home: SettingsPage(controller: controller),
      ),
    );

    expect(find.text('Conta'), findsWidgets);
    expect(find.text('Unidades'), findsOneWidget);
    await tester.tap(find.text('Unidades'));
    await tester.pumpAndSettle();
    expect(find.text('Peso'), findsOneWidget);
    expect(find.text('Distancia'), findsOneWidget);
  });

  testWidgets('preferencia de notificacao e persistida no controlador', (
    tester,
  ) async {
    final controller = SettingsController(
      repository: SettingsRepository(
        store: InMemorySettingsLocalStore(),
        userIdResolver: () async => 'test-user',
      ),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: FitTheme.dark(),
        home: SettingsPage(controller: controller),
      ),
    );

    final notifications = find.text('Notificacoes');
    await tester.ensureVisible(notifications);
    await tester.pumpAndSettle();
    await tester.tap(notifications);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lembretes de treino'));
    await tester.pump();

    expect(
      controller
          .state
          .snapshot!
          .settings
          .account
          .notifications
          .workoutReminders,
      isTrue,
    );
  });
}
