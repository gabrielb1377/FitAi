import 'dart:ui';

import 'package:fitai/features/profile/presentation/pages/profile_root_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_test_support.dart';

void main() {
  testWidgets('golden do dashboard de Perfil em mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = profileTestController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(profileTestApp(controller));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ProfileRootPage),
      matchesGoldenFile('goldens/profile_root_page_mobile.png'),
    );
  });
}
