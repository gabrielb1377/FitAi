import 'package:fitai/features/plans/presentation/pages/planos_official_root_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const viewports = <Size>[
    Size(360, 844),
    Size(390, 844),
    Size(412, 844),
    Size(768, 1024),
    Size(1440, 1024),
  ];

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  for (final viewport in viewports) {
    testWidgets('golden PLAN-001 root after ${viewport.width.toInt()}dp', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: PlanosOfficialRootPage(checkBackend: () async => false),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PlanosOfficialRootPage),
        matchesGoldenFile(
          'goldens/ui_m1_3/root_after/PLANS_001_ROOT_AFTER_${viewport.width.toInt()}.png',
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
