import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_test_fixtures.dart';

void main() {
  const viewports = <Size>[
    Size(320, 700),
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
    Size(600, 960),
    Size(768, 1024),
    Size(1024, 900),
    Size(1440, 900),
  ];

  for (final viewport in viewports) {
    testWidgets('HOME-001 responsive ${viewport.width.toInt()}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        homeTestHost(homeOfficialScreens()['HOME-001']!()),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(homeGoldenRootKey),
        matchesGoldenFile(
          'goldens/home/responsive/HOME-001-${viewport.width.toInt()}.png',
        ),
      );
    });
  }
}
