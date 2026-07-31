import 'package:fitai/design_system/fit_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VS5 pares de texto e acao criticos atendem contraste WCAG AA', () {
    const minimumAaContrast = 4.5;
    final pairs = <String, (Color, Color)>{
      'texto primario sobre fundo': (
        FitColors.textPrimary,
        FitColors.background,
      ),
      'texto secundario sobre superficie': (
        FitColors.textSecondary,
        FitColors.surface,
      ),
      'texto terciario sobre fundo': (
        FitColors.textTertiary,
        FitColors.background,
      ),
      'acao primaria': (FitColors.onPrimary, FitColors.primary),
      'informacao': (FitColors.onInfo, FitColors.info),
      'conquista': (FitColors.onAchievement, FitColors.achievement),
      'erro': (FitColors.onError, FitColors.error),
    };

    for (final entry in pairs.entries) {
      expect(
        _contrastRatio(entry.value.$1, entry.value.$2),
        greaterThanOrEqualTo(minimumAaContrast),
        reason: '${entry.key} deve ter contraste minimo AA.',
      );
    }
  });

  testWidgets('VS5 controles-base preservam alvo de toque minimo de 48dp', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FitTheme.dark(),
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FitButton(label: 'Salvar', onPressed: () {}),
              FitIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Fechar',
                onPressed: () {},
              ),
              TextButton(onPressed: () {}, child: const Text('Cancelar')),
              FitTextField(controller: TextEditingController(), label: 'Nome'),
            ],
          ),
        ),
      ),
    );

    for (final finder in <Finder>[
      find.byType(FilledButton),
      find.byType(IconButton),
      find.byType(TextButton),
      find.byType(TextField),
    ]) {
      final size = tester.getSize(finder);
      expect(size.height, greaterThanOrEqualTo(FitLayout.minimumTouchTarget));
      expect(size.width, greaterThanOrEqualTo(FitLayout.minimumTouchTarget));
    }
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + .05) / (darker + .05);
}
