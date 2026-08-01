import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_test_fixtures.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final entry in homeOfficialScreens().entries) {
    testWidgets('${entry.key} golden mobile', (tester) async {
      // Goldens existentes foram aprovados com o DPR padrao do test binding.
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(homeTestHost(entry.value()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(homeGoldenRootKey),
        matchesGoldenFile('goldens/home/${entry.key}.png'),
      );
    });
  }
}
