import 'package:fitai/screens/exercicios/biblioteca_exercicios_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Biblioteca nao gera overflow na matriz de telas', (
    tester,
  ) async {
    const sizes = <Size>[
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
      Size(600, 900),
      Size(768, 1024),
      Size(1024, 768),
      Size(1440, 900),
    ];
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            );
          },
          home: const BibliotecaExerciciosPage(offline: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
  });
}
