import 'package:fitai/screens/exercicios/biblioteca_exercicios_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('golden LIB-001 biblioteca offline', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const BibliotecaExerciciosPage(offline: true),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(BibliotecaExerciciosPage),
      matchesGoldenFile('goldens/library_001_root.png'),
    );
  });
}
