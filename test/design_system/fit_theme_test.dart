import 'package:fitai/design_system/fit_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FitTheme expoe tokens e extensao semantica oficial', () {
    final theme = FitTheme.dark();

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, FitColors.primary);
    expect(theme.extension<FitSemanticColors>()?.ai, FitColors.ai);
    expect(theme.progressIndicatorTheme.linearMinHeight, 8);
    expect(FitDuration.instant, Duration.zero);
  });

  testWidgets('ContextExtensions le tokens e breakpoints com fallback seguro', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: FitTheme.dark(),
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(capturedContext.fitColors.running, FitColors.running);
    expect(
      capturedContext.fitText.displaySmall?.fontSize,
      FitTypography.metric.fontSize,
    );
    expect(
      capturedContext.fitText.displaySmall?.fontWeight,
      FitTypography.metric.fontWeight,
    );
    expect(capturedContext.isSmallMobile, isFalse);
    expect(capturedContext.isTablet, isFalse);
  });
}
